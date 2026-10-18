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
  $sql | & docker compose --env-file $envFile -f $compose exec -T postgres sh -c ('psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d ' + $database)
  if ($LASTEXITCODE -ne 0) { throw 'Draft import failed.' }
  Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'database-constraints.sql') |
    & docker compose --env-file $envFile -f $compose exec -T postgres sh -c ('psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d ' + $database)
  if ($LASTEXITCODE -ne 0) { throw 'SQL constraints test failed.' }
  Write-Output 'PASS: migrations twice, Flyway validate, actual draft import and 16 negative SQL checks.'
} finally {
  if ($created) {
    Invoke-Compose @('exec', '-T', 'postgres', 'sh', '-c', ('dropdb -U "$POSTGRES_USER" ' + $database))
  }
  $OutputEncoding = $oldEncoding
  [Console]::OutputEncoding = $oldConsoleEncoding
}
