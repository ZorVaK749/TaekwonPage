# Requires a running local postgres service from docker-compose.yml.
# Uses a uniquely named disposable database, never the configured application DB.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$compose = Join-Path $root 'docker-compose.yml'
$envFile = Join-Path $root '.env'
if (!(Test-Path -LiteralPath $envFile)) { throw 'Copy .env.example to .env and set DB_PASSWORD first.' }
$database = 'tkd_test_' + [guid]::NewGuid().ToString('N')
$created = $false
$oldEncoding = $OutputEncoding
$oldConsoleEncoding = [Console]::OutputEncoding
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $OutputEncoding
function Invoke-Compose {
  param([string[]]$Arguments)
  & docker compose --env-file $envFile -f $compose @Arguments
  if ($LASTEXITCODE -ne 0) { throw 'Database test command failed.' }
}
function Invoke-TestSql {
  param([string[]]$Sql, [switch]$ExpectConflict, [string]$ExpectedError = '')
  $previousPreference = $ErrorActionPreference
  try {
    # PowerShell 5 converts native stderr to error records. Expected SQL rejections
    # must be checked by exit code AND message, not terminate the harness early.
    $ErrorActionPreference = 'Continue'
    $output = @($Sql | & docker compose --env-file $envFile -f $compose exec -T postgres sh -c ('psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d ' + $database) 2>&1)
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousPreference }
  if ($ExpectConflict -or $ExpectedError) {
    $message = if ($ExpectConflict) { 'draft import conflict:' } else { $ExpectedError }
    if ($code -eq 0 -or ($output | Out-String) -notmatch [regex]::Escape($message)) {
      throw 'Expected a deliberate importer conflict, not success or an unrelated SQL error.'
    }
  } elseif ($code -ne 0) {
    Write-Output $output
    throw 'SQL import/test failed.'
  }
}
try {
  Invoke-Compose @('up', '-d', '--wait', 'postgres')
  Invoke-Compose @('exec', '-T', 'postgres', 'sh', '-c', ('createdb -U "$POSTGRES_USER" ' + $database))
  $created = $true
  $url = 'FLYWAY_URL=jdbc:postgresql://postgres:5432/' + $database
  # Load drafts under V2 first, then verify populated upgrades through V3/V4/V5.
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', '-target=2', 'migrate')
  # Second execution must be a no-op; validate checks migration checksums.
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', '-target=2', 'migrate')
  # Strict validate runs after all migrations below; later versions are intentionally pending here.
  $sql = & node (Join-Path $root 'tools/seeders/export-draft-sql.mjs') --local-drafts
  if ($LASTEXITCODE -ne 0) { throw 'Draft SQL export failed.' }
  Invoke-TestSql -Sql $sql
  Invoke-TestSql -Sql $sql
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-constraints.sql'))
  $fixtureScript = Join-Path $PSScriptRoot 'export-import-fixture.mjs'
  $fixture = & node $fixtureScript initial
  if ($LASTEXITCODE -ne 0) { throw 'Synthetic fixture export failed.' }
  Invoke-TestSql -Sql $fixture
  Invoke-TestSql -Sql $fixture
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', '-target=3', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', '-target=4', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', '-target=5', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'validate')
  Invoke-TestSql -Sql $fixture
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT count(*) FROM curriculum_draft_revision WHERE content_id = 'gup_10' AND revision = 0) <> 1 THEN
    RAISE EXCEPTION 'V3 upgrade failed to capture existing curriculum baseline';
  END IF;
  PERFORM assert_curriculum_revision_applied('gup_10');
  IF (SELECT count(*) FROM content_detail_revision WHERE is_baseline) < 2 THEN
    RAISE EXCEPTION 'V4 upgrade failed to capture subtype baselines';
  END IF;
END; $$;
'@
  foreach ($mode in @('conflict-name', 'conflict-requirements', 'conflict-aliases', 'conflict-requirement-add', 'conflict-steps')) {
    $changed = & node $fixtureScript $mode
    if ($LASTEXITCODE -ne 0) { throw 'Conflict fixture export failed.' }
    Invoke-TestSql -Sql $changed -ExpectConflict
  }
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-import-checks.sql'))
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-draft-revisions.sql'))
  $edit = & node $fixtureScript apply-text-edit
  if ($LASTEXITCODE -ne 0) { throw 'Text edit fixture export failed.' }
  Invoke-TestSql -Sql $edit
  Invoke-TestSql -Sql $edit -ExpectedError 'stale draft revision'
  Invoke-TestSql -Sql $fixture -ExpectConflict
  $updated = & node $fixtureScript after-text-edit
  if ($LASTEXITCODE -ne 0) { throw 'Updated snapshot export failed.' }
  Invoke-TestSql -Sql $updated
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 1
    OR (SELECT name FROM content_entry WHERE id = 'fixture_position') <> 'Edited synthetic draft'
    OR (SELECT count(*) FROM content_draft_revision) <> 1 THEN
    RAISE EXCEPTION 'versioned edit/import pipeline did not preserve revision history';
  END IF;
END; $$;
'@
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-curriculum-revisions.sql'))
  $curriculumEdit = & node $fixtureScript apply-curriculum-edit
  if ($LASTEXITCODE -ne 0) { throw 'Curriculum edit fixture export failed.' }
  Invoke-TestSql -Sql $curriculumEdit
  Invoke-TestSql -Sql $curriculumEdit -ExpectedError 'stale curriculum revision'
  Invoke-TestSql -Sql $updated -ExpectConflict
  $curriculumUpdated = & node $fixtureScript after-curriculum-edit
  if ($LASTEXITCODE -ne 0) { throw 'Updated curriculum fixture export failed.' }
  Invoke-TestSql -Sql $curriculumUpdated
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT draft_revision FROM content_entry WHERE id = 'gup_10') <> 1
    OR (SELECT count(*) FROM curriculum_draft_revision WHERE content_id = 'gup_10') <> 2
    OR EXISTS (SELECT 1 FROM gup_position WHERE gup_id = 'gup_10') THEN
    RAISE EXCEPTION 'curriculum edit/import pipeline lost state or history';
  END IF;
END; $$;
'@
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-detail-revisions.sql'))
  $detailEdit = & node $fixtureScript apply-detail-edit
  if ($LASTEXITCODE -ne 0) { throw 'Detail edit fixture export failed.' }
  Invoke-TestSql -Sql $detailEdit
  Invoke-TestSql -Sql $detailEdit -ExpectedError 'stale catalog detail revision'
  Invoke-TestSql -Sql $curriculumUpdated -ExpectConflict
  $detailUpdated = & node $fixtureScript after-detail-edit
  if ($LASTEXITCODE -ne 0) { throw 'Updated detail fixture export failed.' }
  Invoke-TestSql -Sql $detailUpdated
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_position') <> 2
    OR (SELECT count(*) FROM content_detail_revision WHERE content_id = 'fixture_position' AND NOT is_baseline) <> 1
    OR (SELECT rear_rotation_deg FROM position WHERE id = 'fixture_position') <> 25.5 THEN
    RAISE EXCEPTION 'detail edit/import pipeline lost state or history';
  END IF;
END; $$;
'@
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-tul-revisions.sql'))
  $tulEdit = & node $fixtureScript apply-tul-edit
  if ($LASTEXITCODE -ne 0) { throw 'Exercise edit fixture export failed.' }
  Invoke-TestSql -Sql $tulEdit
  Invoke-TestSql -Sql $tulEdit -ExpectedError 'stale exercise revision'
  Invoke-TestSql -Sql $detailUpdated -ExpectConflict
  $tulUpdated = & node $fixtureScript after-tul-edit
  if ($LASTEXITCODE -ne 0) { throw 'Updated exercise fixture export failed.' }
  Invoke-TestSql -Sql $tulUpdated
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 1
    OR (SELECT movement_count FROM tul WHERE id = 'fixture_tul') IS NOT NULL
    OR (SELECT sequence_complete FROM tul WHERE id = 'fixture_tul')
    OR (SELECT count(*) FROM tul_step WHERE tul_id = 'fixture_tul') <> 2
    OR (SELECT count(*) FROM tul_step_source WHERE tul_id = 'fixture_tul') <> 2 THEN
    RAISE EXCEPTION 'exercise edit/import pipeline lost unknown totals or history';
  END IF;
END; $$;
'@
  Invoke-TestSql -Sql (Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-citation-revisions.sql'))
  $citationEdit = & node $fixtureScript apply-citation-edit
  if ($LASTEXITCODE -ne 0) { throw 'Citation edit fixture export failed.' }
  Invoke-TestSql -Sql $citationEdit
  Invoke-TestSql -Sql $citationEdit -ExpectedError 'stale citation revision'
  Invoke-TestSql -Sql $tulUpdated -ExpectConflict
  $citationUpdated = & node $fixtureScript after-citation-edit
  if ($LASTEXITCODE -ne 0) { throw 'Updated citation fixture export failed.' }
  Invoke-TestSql -Sql $citationUpdated
  Invoke-TestSql -Sql @'
DO $$ BEGIN
  IF (SELECT draft_revision FROM content_entry WHERE id = 'fixture_tul') <> 2
    OR (SELECT pdf_page FROM content_source WHERE id = 'citation_import_tul') <> 2
    OR (SELECT count(*) FROM content_citation_revision WHERE content_id = 'fixture_tul' AND NOT is_baseline) <> 1
    OR (SELECT count(*) FROM tul_step_source WHERE tul_id = 'fixture_tul') <> 2 THEN
    RAISE EXCEPTION 'citation edit/import pipeline lost evidence, step ownership or history';
  END IF;
END; $$;
'@
  Write-Output 'PASS: populated upgrades V2-V6/reloads; previous checks plus 37 citation/ownership rejections; source/hash/page bounds, location swaps, reserved IDs and rollback.'
} finally {
  if ($created) {
    Invoke-Compose @('exec', '-T', 'postgres', 'sh', '-c', ('dropdb -U "$POSTGRES_USER" ' + $database))
  }
  $OutputEncoding = $oldEncoding
  [Console]::OutputEncoding = $oldConsoleEncoding
}
