# Requires only PowerShell 5.1+ and built-in .NET APIs; does not parse PDF content.
[CmdletBinding()]
param(
  [string]$RepositoryRoot = '',
  [string]$InventoryPath = '',
  [switch]$CheckLocalFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Condition {
  param([bool]$Condition, [string]$Message)
  if (!$Condition) { throw $Message }
}

function Test-Integer {
  param($Value)
  return ($Value -is [int] -or $Value -is [long])
}

if (!$RepositoryRoot) { $RepositoryRoot = Join-Path $PSScriptRoot '../..' }
$root = [System.IO.Path]::GetFullPath($RepositoryRoot)
if (!$InventoryPath) { $InventoryPath = Join-Path $root 'knowledge/sources/inventory.json' }
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$text = $utf8.GetString([System.IO.File]::ReadAllBytes($InventoryPath))
$inventory = $text | ConvertFrom-Json
Assert-Condition ($null -ne $inventory -and $inventory -is [pscustomobject]) 'Inventory must be an object.'
Assert-Condition ((Test-Integer $inventory.format_version) -and $inventory.format_version -eq 1) 'Unsupported format_version.'
Assert-Condition ($inventory.sources -is [array] -and $inventory.sources.Count -gt 0) 'sources must be a nonempty array.'

$ids = @{}
$paths = @{}
$hashes = @{}
$required = @('id', 'file_reference', 'size_bytes', 'sha256', 'title', 'organization', 'author', 'edition', 'language', 'pdf_pages', 'metadata_evidence', 'coverage', 'review_status', 'redistribution_status', 'notes')
foreach ($source in $inventory.sources) {
  Assert-Condition ($source -is [pscustomobject]) 'Each source must be an object.'
  foreach ($field in $required) {
    Assert-Condition ($field -cin @($source.PSObject.Properties.Name)) "Missing field: $field"
  }
  Assert-Condition ($source.id -is [string] -and $source.id -cmatch '^[a-z][a-z0-9]*(_[a-z0-9]+)*$') 'Invalid canonical source ID.'
  Assert-Condition (!$ids.ContainsKey($source.id)) "Duplicate source ID: $($source.id)"
  $ids[$source.id] = $true

  # Restrict references to a single local filename: no absolute paths or traversal.
  Assert-Condition ($source.file_reference -is [string] -and $source.file_reference -cmatch '^knowledge/sources/pdfs/[^/\\:]+\.[pP][dD][fF]$') 'Invalid PDF reference.'
  Assert-Condition (!$paths.ContainsKey($source.file_reference)) 'Duplicate PDF reference.'
  $paths[$source.file_reference] = $true
  Assert-Condition ((Test-Integer $source.size_bytes) -and $source.size_bytes -ge 5) 'Invalid size_bytes.'
  Assert-Condition ($source.sha256 -is [string] -and $source.sha256 -cmatch '^[a-f0-9]{64}$') 'Invalid SHA-256.'
  Assert-Condition (!$hashes.ContainsKey($source.sha256)) 'Duplicate PDF bytes under different records.'
  $hashes[$source.sha256] = $true

  foreach ($field in @('title', 'organization', 'author', 'edition', 'language', 'metadata_evidence')) {
    $value = $source.$field
    Assert-Condition ($null -eq $value -or ($value -is [string] -and ![string]::IsNullOrWhiteSpace($value))) "Invalid nullable text: $field"
  }
  Assert-Condition ($null -eq $source.pdf_pages -or ((Test-Integer $source.pdf_pages) -and $source.pdf_pages -gt 0)) 'Invalid pdf_pages.'
  Assert-Condition ($source.review_status -ceq 'pending_human_review') 'This inventory format does not approve content.'
  Assert-Condition ($source.redistribution_status -ceq 'unknown') 'Rights changes require a reviewed update of this format.'
  Assert-Condition ($source.notes -is [string] -and ![string]::IsNullOrWhiteSpace($source.notes)) 'Missing notes.'
  Assert-Condition ($source.coverage -is [array]) 'coverage must be an array.'
  $hasMetadata = @('title', 'organization', 'author', 'edition', 'language', 'pdf_pages') | Where-Object { $null -ne $source.$_ }
  Assert-Condition (@($hasMetadata).Count -eq 0 -or $null -ne $source.metadata_evidence) 'Known metadata requires evidence.'
  foreach ($entry in $source.coverage) {
    Assert-Condition ($entry.topic -is [string] -and ![string]::IsNullOrWhiteSpace($entry.topic)) 'Invalid coverage topic.'
    Assert-Condition ((Test-Integer $entry.pdf_page_start) -and (Test-Integer $entry.pdf_page_end)) 'Coverage pages must be integers.'
    Assert-Condition ($null -ne $source.pdf_pages -and $entry.pdf_page_start -ge 1 -and $entry.pdf_page_end -ge $entry.pdf_page_start -and $entry.pdf_page_end -le $source.pdf_pages) 'Coverage pages outside PDF bounds.'
  }

  if ($CheckLocalFiles) {
    $file = Join-Path $root $source.file_reference
    Assert-Condition (Test-Path -LiteralPath $file -PathType Leaf) "Local PDF missing: $($source.id)"
    Assert-Condition ((Get-Item -LiteralPath $file).Length -eq $source.size_bytes) "Size mismatch: $($source.id)"
    $stream = [System.IO.File]::OpenRead($file)
    try {
      $header = New-Object byte[] 5
      $read = $stream.Read($header, 0, 5)
      Assert-Condition ($read -eq 5 -and [System.Text.Encoding]::ASCII.GetString($header) -ceq '%PDF-') "Invalid PDF header: $($source.id)"
    } finally { $stream.Dispose() }
    $actualHash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Condition ($actualHash -ceq $source.sha256) "SHA-256 mismatch: $($source.id)"
  }
}

if ($CheckLocalFiles) {
  $pdfDirectory = Join-Path $root 'knowledge/sources/pdfs'
  foreach ($file in Get-ChildItem -LiteralPath $pdfDirectory -Recurse -File | Where-Object { $_.Extension -ieq '.pdf' }) {
    $reference = 'knowledge/sources/pdfs/' + $file.FullName.Substring($pdfDirectory.Length + 1).Replace('\', '/')
    Assert-Condition ($paths.ContainsKey($reference)) "Unregistered local PDF: $reference"
  }
  Write-Output "PASS: $($inventory.sources.Count) source records and local PDF identities."
} else {
  Write-Output "PASS: $($inventory.sources.Count) source records; local PDFs NOT checked."
}
