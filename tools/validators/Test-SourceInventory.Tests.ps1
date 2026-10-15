[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$validator = Join-Path $PSScriptRoot 'Test-SourceInventory.ps1'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$original = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'knowledge/sources/inventory.json')
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('taekwonpage-inventory-test-' + [guid]::NewGuid().ToString())
$null = New-Item -ItemType Directory -Path (Join-Path $temp 'knowledge/sources/pdfs') -Force
$path = Join-Path $temp 'inventory.json'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:passed = 0

function Invoke-Case {
  param([string]$Name, [scriptblock]$Mutate, [string]$ExpectedError = '', [switch]$Local)
  $data = $original | ConvertFrom-Json
  & $Mutate $data
  [System.IO.File]::WriteAllText($path, ($data | ConvertTo-Json -Depth 20), $utf8)
  $caught = $null
  try { $null = & $validator -RepositoryRoot $temp -InventoryPath $path -CheckLocalFiles:$Local } catch { $caught = $_.Exception.Message }
  if ($ExpectedError) {
    if (!$caught -or $caught -notlike "*$ExpectedError*") { throw "FAIL $Name (expected '$ExpectedError', got '$caught')" }
  } elseif ($caught) { throw "FAIL $Name : $caught" }
  $script:passed++
  Write-Output "PASS: $Name"
}

try {
  Push-Location $temp
  try { $null = & $validator } finally { Pop-Location }
  $script:passed++
  Write-Output 'PASS: default paths from another working directory'
  Invoke-Case 'valid inventory without local PDFs' { param($d) }
  Invoke-Case 'unsupported version' { param($d) $d.format_version = 2 } 'format_version'
  Invoke-Case 'empty inventory' { param($d) $d.sources = @() } 'nonempty array'
  Invoke-Case 'duplicate ID' { param($d) $d.sources[1].id = $d.sources[0].id } 'Duplicate source ID'
  Invoke-Case 'noncanonical ID' { param($d) $d.sources[0].id = 'Fuente Á' } 'canonical source ID'
  Invoke-Case 'missing field' { param($d) $d.sources[0].PSObject.Properties.Remove('notes') } 'Missing field'
  Invoke-Case 'path traversal' { param($d) $d.sources[0].file_reference = '../external.pdf' } 'Invalid PDF reference'
  Invoke-Case 'duplicate path' { param($d) $d.sources[1].file_reference = $d.sources[0].file_reference } 'Duplicate PDF reference'
  Invoke-Case 'malformed hash' { param($d) $d.sources[0].sha256 = '123' } 'Invalid SHA-256'
  Invoke-Case 'duplicate hash' { param($d) $d.sources[1].sha256 = $d.sources[0].sha256 } 'Duplicate PDF bytes'
  Invoke-Case 'invalid size' { param($d) $d.sources[0].size_bytes = '135651' } 'Invalid size_bytes'
  Invoke-Case 'missing metadata evidence' { param($d) $d.sources[0].metadata_evidence = $null } 'requires evidence'
  Invoke-Case 'coverage out of bounds' { param($d) $d.sources[0].coverage[0].pdf_page_end = 9999 } 'outside PDF bounds'
  Invoke-Case 'approval cannot be inferred' { param($d) $d.sources[0].review_status = 'approved' } 'does not approve content'
  Invoke-Case 'rights cannot be inferred' { param($d) $d.sources[0].redistribution_status = 'allowed' } 'Rights changes'
  Invoke-Case 'missing local file' { param($d) } 'Local PDF missing' -Local

  # Synthetic bytes test identity checks, not PDF parsing or martial accuracy.
  $fixture = Join-Path $temp 'knowledge/sources/pdfs/fixture.pdf'
  [System.IO.File]::WriteAllText($fixture, '%PDF-synthetic-test', $utf8)
  $prepare = {
    param($d)
    $d.sources = @($d.sources[0])
    $d.sources[0].file_reference = 'knowledge/sources/pdfs/fixture.pdf'
    $d.sources[0].size_bytes = (Get-Item -LiteralPath $fixture).Length
    $d.sources[0].sha256 = (Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  Invoke-Case 'local identity matches' $prepare -Local
  Invoke-Case 'local size mismatch' { param($d) & $prepare $d; $d.sources[0].size_bytes++ } 'Size mismatch' -Local
  Invoke-Case 'local hash mismatch' { param($d) & $prepare $d; $d.sources[0].sha256 = '0' * 64 } 'SHA-256 mismatch' -Local
  [System.IO.File]::WriteAllText($fixture, 'NOT-a-pdf', $utf8)
  Invoke-Case 'invalid local PDF header' $prepare 'Invalid PDF header' -Local
  [System.IO.File]::WriteAllText($fixture, '%PDF-synthetic-test', $utf8)
  $extra = Join-Path $temp 'knowledge/sources/pdfs/extra.pdf'
  [System.IO.File]::WriteAllText($extra, '%PDF-extra', $utf8)
  Invoke-Case 'unregistered local PDF' $prepare 'Unregistered local PDF' -Local
  Write-Output "PASS: $script:passed tests."
} finally {
  # Only remove this run's newly created, uniquely named fixtures.
  Remove-Item -LiteralPath $temp -Recurse -Force
}
