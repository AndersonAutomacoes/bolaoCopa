#Requires -Version 5.1
<#
.SYNOPSIS
  Verifica se os 24 PNG listados em expected-png-manifest.txt existem em reference/png/.
.EXAMPLE
  .\verify-mockup-pngs.ps1
  pwsh -File .\verify-mockup-pngs.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pngDir = Join-Path $root 'reference/png'
$manifest = Join-Path $PSScriptRoot 'expected-png-manifest.txt'

if (-not (Test-Path -LiteralPath $manifest)) {
    Write-Error "Manifest não encontrado: $manifest"
    exit 2
}

$names = @(Get-Content -LiteralPath $manifest | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
$expected = $names.Count
if ($expected -ne 24) {
    Write-Error "O manifest deve listar exatamente 24 ficheiros; encontrados: $expected ($manifest)"
    exit 2
}
$missing = [System.Collections.Generic.List[string]]::new()

foreach ($name in $names) {
    $path = Join-Path $pngDir $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $missing.Add($name)
    }
}

Write-Host "Pasta: $pngDir"
Write-Host "Manifest: $manifest ($expected ficheiros esperados)"
Write-Host ""

if ($missing.Count -eq 0) {
    Write-Host "OK: todos os $expected PNG estão presentes."
    exit 0
}

Write-Host "FALTAM $($missing.Count) ficheiro(s):"
foreach ($m in $missing) {
    Write-Host "  - $m"
}
Write-Host ""
Write-Host "Presentes: $($expected - $missing.Count) / $expected"
exit 1
