# Builds the Windows installer with Inno Setup and writes SHA256SUMS.txt next to it.
# The version comes from the VERSION file; the output goes to dist\.
[CmdletBinding()]
param([string]$Iscc)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$root = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $root

$version = ([IO.File]::ReadAllText((Join-Path $root 'VERSION'))).Trim()
if ($version -cnotmatch '^\d+\.\d+\.\d+$') { throw "Invalid VERSION: $version" }

if (-not $Iscc) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    )
    $Iscc = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $Iscc) { throw 'ISCC.exe (Inno Setup 6.7 or newer) not found. Pass -Iscc.' }

New-Item -ItemType Directory -Force -Path (Join-Path $root 'dist') | Out-Null
& $Iscc /Qp "/DAppVersion=$version" (Join-Path $root 'installer\rdr1-ptbr.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with code $LASTEXITCODE" }

$setup = Join-Path $root "dist\Instalador-Dublagem-PTBR-RDR1-v$version.exe"

# The Linux and Steam Deck script, zipped on its own (it goes next to the extracted mod).
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$linux = Join-Path $root "dist\Instalador-Dublagem-PTBR-RDR1-Linux-v$version.zip"
if (Test-Path -LiteralPath $linux) { Remove-Item -LiteralPath $linux }
$zip = [IO.Compression.ZipFile]::Open($linux, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($name in 'instalar-linux.sh', 'LICENSE') {
        $entry = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]'2026-01-01T00:00:00Z'
        $out = $entry.Open()
        try { $bytes = [IO.File]::ReadAllBytes((Join-Path $root $name)); $out.Write($bytes, 0, $bytes.Length) } finally { $out.Dispose() }
    }
}
finally { $zip.Dispose() }

$lines = foreach ($file in $setup, $linux) {
    "$((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant())  $(Split-Path $file -Leaf)"
}
$sums = Join-Path $root 'dist\SHA256SUMS.txt'
[IO.File]::WriteAllText($sums, ($lines -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
Write-Host "Built $setup and $linux"
$lines | ForEach-Object { Write-Host $_ }
