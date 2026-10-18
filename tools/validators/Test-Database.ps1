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
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'migrate')
  # Second execution must be a no-op; validate checks migration checksums.
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'migrate')
  Invoke-Compose @('run', '--rm', '-e', $url, 'migrate', 'validate')
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
  Write-Output 'PASS: migrations twice, Flyway validate, 16 SQL constraints; real/synthetic reloads; 7 curriculum groups; 5 import conflicts; versioned draft edits with 18 rejections and rollback.'
} finally {
  if ($created) {
    Invoke-Compose @('exec', '-T', 'postgres', 'sh', '-c', ('dropdb -U "$POSTGRES_USER" ' + $database))
  }
  $OutputEncoding = $oldEncoding
  [Console]::OutputEncoding = $oldConsoleEncoding
}
