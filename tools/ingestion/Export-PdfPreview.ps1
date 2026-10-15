# Windows-only local inspection helper. No OCR, extraction or publication.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$PdfPath,
  [Parameter(Mandatory = $true)]
  [ValidateCount(1, 20)]
  [int[]]$Pages,
  [string]$OutputDirectory = '',
  [ValidateRange(400, 2400)]
  [int]$Width = 1400
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  throw 'This helper requires Windows PDF APIs.'
}
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
$null = [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType=WindowsRuntime]
$null = [Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
$null = [Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType=WindowsRuntime]

function Wait-PdfOperation {
  param($Operation, [type]$ResultType)
  $method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and
    $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
  } | Select-Object -First 1
  $task = $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
  return $task.GetAwaiter().GetResult()
}

$actionMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and !$_.IsGenericMethod -and $_.GetParameters().Count -eq 1
} | Select-Object -First 1
$resolvedPdf = (Resolve-Path -LiteralPath $PdfPath).Path
$file = Wait-PdfOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($resolvedPdf)) ([Windows.Storage.StorageFile])
$pdf = Wait-PdfOperation ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])

# Validate every page before creating output. Numbering is PDF-based, starting at 1.
$selected = @($Pages | Select-Object -Unique)
foreach ($number in $selected) {
  if ($number -lt 1 -or $number -gt $pdf.PageCount) {
    throw "PDF page outside bounds: $number (1..$($pdf.PageCount))."
  }
}
if (!$OutputDirectory) {
  $root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
  $OutputDirectory = Join-Path $root ('knowledge/sources/local-previews/' + [guid]::NewGuid().ToString())
}
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) {
  throw 'Output directory already exists. Choose a new directory; existing work is never overwritten.'
}
$null = New-Item -ItemType Directory -Path $output

foreach ($number in $selected) {
  $page = $pdf.GetPage([uint32]($number - 1))
  $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
  try {
    $options = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $options.DestinationWidth = [uint32]$Width
    $task = $actionMethod.Invoke($null, @($page.RenderToStreamAsync($stream, $options)))
    $null = $task.GetAwaiter().GetResult()
    $reader = New-Object Windows.Storage.Streams.DataReader($stream.GetInputStreamAt(0))
    try {
      $null = Wait-PdfOperation ($reader.LoadAsync([uint32]$stream.Size)) ([uint32])
      $bytes = New-Object byte[] ([int]$stream.Size)
      $reader.ReadBytes($bytes)
      [System.IO.File]::WriteAllBytes((Join-Path $output "page-$number.png"), $bytes)
    } finally { $reader.Dispose() }
  } finally { $page.Dispose(); $stream.Dispose() }
}

[PSCustomObject]@{
  PdfPages = $pdf.PageCount
  ExportedPages = $selected
  OutputDirectory = $output
}
