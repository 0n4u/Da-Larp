param(
    [Parameter(Mandatory=$true)][string]$SourceDirectory,
    [Parameter(Mandatory=$true)][string]$Destination
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $source = [IO.Path]::GetFullPath($SourceDirectory)
    $target = [IO.Path]::GetFullPath($Destination)
    if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw 'Support folder is missing.' }
    $files = @(Get-ChildItem -LiteralPath $source -File | ForEach-Object FullName)
    if ($files.Count -eq 0) { throw 'Support folder is empty.' }
    Compress-Archive -LiteralPath $files -DestinationPath $target -Force
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw 'Archive was not created.' }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
