# Zips a folder of hand-built OOXML parts (produced by the skill) into a .xlsx file.
# Usage: powershell -File build_xlsx.ps1 -Src <xlsx_build_dir> -Dest <output.xlsx>
param(
  [Parameter(Mandatory=$true)][string]$Src,
  [Parameter(Mandatory=$true)][string]$Dest
)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path -LiteralPath $Dest) { Remove-Item -LiteralPath $Dest -Force }

$zip = [System.IO.Compression.ZipFile]::Open($Dest, [System.IO.Compression.ZipArchiveMode]::Create)
$files = Get-ChildItem -Path $Src -Recurse -File
foreach ($f in $files) {
  $relPath = $f.FullName.Substring($Src.Length + 1)
  $relPath = $relPath -replace [regex]::Escape('\'), '/'
  $entry = $zip.CreateEntry($relPath, [System.IO.Compression.CompressionLevel]::Optimal)
  $entryStream = $entry.Open()
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $entryStream.Write($bytes, 0, $bytes.Length)
  $entryStream.Close()
}
$zip.Dispose()
Write-Output "Created: $Dest"
