# Tests the installer end to end on a synthetic game: small invented audio files and a real HDiffPatch
# patch between them. It never looks for the real game: every run names the folders.
# Runs per user (/CURRENTUSER), so it needs no administrator. -Online also lets the installer download
# HDiffPatch from GitHub instead of using the local zip.
[CmdletBinding()]
param([string]$Setup, [string]$HdiffpatchZip, [switch]$Online)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$root = Split-Path $PSScriptRoot -Parent
$TESTED_URL = 'https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_windows64.zip'
$TESTED_SHA = '77F141386E5D8F785C1C846E10FBBC19B6C05AA00E3F59CC44670FB3F0E2AE94'
$GUID = '{4F7C2B91-6A3E-4D58-B1E0-9C2A7D5E8F13}_is1'
$ENTRY = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$GUID"

if (-not $Setup) { $Setup = (Get-ChildItem -LiteralPath (Join-Path $root 'dist') -Filter 'Instalador-*.exe' | Select-Object -First 1).FullName }
if (-not $Setup -or -not (Test-Path -LiteralPath $Setup)) { throw 'Installer not found: run scripts\build.ps1' }

$work = Join-Path ([IO.Path]::GetTempPath()) ('rdr1-ptbr-test-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
$failures = 0
function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "  ok   $what" -ForegroundColor Green }
    else { Write-Host "  FAIL $what" -ForegroundColor Red; $script:failures++ }
}
function Sha([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

# ------------------------------------------------------------------ HDiffPatch, to build the test patches
if (-not $HdiffpatchZip) {
    $HdiffpatchZip = Join-Path $work 'hdiffpatch.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object Net.WebClient).DownloadFile($TESTED_URL, $HdiffpatchZip)
}
if ((Sha $HdiffpatchZip) -ne $TESTED_SHA) { throw 'The HDiffPatch zip is not the official v5.1.3' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($HdiffpatchZip, (Join-Path $work 'hdp'))
$hdiffz = Join-Path $work 'hdp\windows64\hdiffz.exe'

# ------------------------------------------------------------------ synthetic files
$rng = New-Object Random 7
function RandomBytes([int]$n) { $b = New-Object byte[] $n; $rng.NextBytes($b); return $b }
$orig = Join-Path $work 'original.rpf'
[IO.File]::WriteAllBytes($orig, (RandomBytes 3000000))
function Dubbed([string]$name, [int]$seed) {
    $b = [IO.File]::ReadAllBytes($orig)
    $r = New-Object Random $seed
    for ($i = 0; $i -lt 400; $i++) { $b[$r.Next($b.Length)] = [byte]$r.Next(256) }
    $extra = New-Object byte[] 50000; $r.NextBytes($extra)
    $path = Join-Path $work $name
    [IO.File]::WriteAllBytes($path, $b + $extra)
    return $path
}
$dub1 = Dubbed 'dub1.rpf' 11
$dub2 = Dubbed 'dub2.rpf' 22

function MakePack([string]$name, [string]$dub, [string]$version, [string]$dubShaOverride = '') {
    $dir = Join-Path $work "$name\RDR1-PTBR-Dublagem\dados"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $patch = "rdr1-ptbr-v$version.hdiff"
    & $hdiffz -f $orig $dub (Join-Path $dir $patch) | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'hdiffz failed' }
    $dubSha = if ($dubShaOverride) { $dubShaOverride } else { Sha $dub }
    $json = "{`n  `"versao_mod`": `"$version`",`n  `"patch`": `"$patch`",`n  `"original_tamanho`": $((Get-Item $orig).Length),`n" +
            "  `"original_sha256`": `"$(Sha $orig)`",`n  `"dublado_tamanho`": $((Get-Item $dub).Length),`n  `"dublado_sha256`": `"$dubSha`"`n}`n"
    [IO.File]::WriteAllText((Join-Path $dir 'versao.json'), $json)
    $folder = Join-Path $work "$name\RDR1-PTBR-Dublagem"
    $zip = Join-Path $work "$name.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($folder, $zip, [IO.Compression.CompressionLevel]::Fastest, $true)
    return @{ Folder = $folder; Zip = $zip }
}
$pack1 = MakePack 'pack1' $dub1 '1.0'
$pack2 = MakePack 'pack2' $dub2 '2.0'
$packBad = MakePack 'packbad' $dub1 '1.0' ('0' * 64)

function NewGame([string]$name, [string]$audio) {
    $g = Join-Path $work $name
    New-Item -ItemType Directory -Force -Path (Join-Path $g 'game') | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $g 'RDR.exe'), [byte[]](0x4D, 0x5A))
    Copy-Item -LiteralPath $audio -Destination (Join-Path $g 'game\audio_d11generic.rpf')
    return $g
}
function Audio([string]$game) { Sha (Join-Path $game 'game\audio_d11generic.rpf') }
function Backup([string]$game) { Join-Path $game 'PTBR-backup\audio_d11generic.rpf' }

$APP = Join-Path $work 'app'
$n = 0
function Install([string]$pack, [string]$game) {
    $script:n++
    $log = Join-Path $work "setup-$($script:n).log"
    $args = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER', "/DIR=`"$APP`"", "/LOG=`"$log`"",
              "/MODPACK=`"$pack`"", "/GAMEDIR=`"$game`"")
    if (-not $Online) { $args += "/HDIFFPATCHZIP=`"$HdiffpatchZip`"" }
    $p = Start-Process -FilePath $Setup -ArgumentList $args -PassThru
    if (-not $p.WaitForExit(600000)) { $p.Kill(); throw 'The installer did not finish: it may be waiting for an answer.' }
    return $p.ExitCode
}
function WaitGone([string]$path) {
    for ($i = 0; $i -lt 120; $i++) { if (-not (Test-Path -LiteralPath $path)) { return $true }; Start-Sleep -Milliseconds 500 }
    return $false
}
# The uninstaller reopens itself from a temporary copy and returns at once, so the wait is on its effect.
function Uninstall() {
    Start-Process -FilePath (Join-Path $APP 'unins000.exe') -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Wait
    return (WaitGone $ENTRY)
}

try {
    if (Test-Path -LiteralPath $ENTRY) { throw 'The installer is already installed for this user: uninstall it before the tests.' }

    Write-Host '[1] Zip from Nexus, original game'
    $g = NewGame 'game1' $orig
    Check ((Install $pack1.Zip $g) -eq 0) 'the installer finishes with code 0'
    Check ((Audio $g) -eq (Sha $dub1)) 'the game has the dubbed audio'
    Check ((Test-Path -LiteralPath (Backup $g)) -and ((Sha (Backup $g)) -eq (Sha $orig))) 'the original is in PTBR-backup'
    Check (-not (Test-Path -LiteralPath (Join-Path $g 'game\audio_d11generic.rpf.ptbr-novo'))) 'no leftover file'
    Check (Test-Path -LiteralPath $ENTRY) 'it shows in the Windows list of installed apps'

    Write-Host '[2] Running it again on the dubbed game'
    Check ((Install $pack1.Zip $g) -eq 0) 'finishes with code 0'
    Check ((Audio $g) -eq (Sha $dub1)) 'the dub stays'

    Write-Host '[3] A newer dub, applied from the original kept in PTBR-backup'
    Check ((Install $pack2.Folder $g) -eq 0) 'the extracted folder works too'
    Check ((Audio $g) -eq (Sha $dub2)) 'the game has the newer dub'
    Check ((Sha (Backup $g)) -eq (Sha $orig)) 'the backup is still the original'

    Write-Host '[4] Uninstall from Windows'
    Check (Uninstall) 'the entry is gone'
    Check ((Audio $g) -eq (Sha $orig)) 'the original audio is back'
    Check (-not (Test-Path -LiteralPath (Join-Path $g 'PTBR-backup'))) 'PTBR-backup is gone'
    Check (WaitGone (Join-Path $APP 'dublagem.ini')) 'the program folder is clean'

    Write-Host '[5] A game file that is neither the original nor the dub'
    $other = Join-Path $work 'other.rpf'; [IO.File]::WriteAllBytes($other, (RandomBytes 3000000))
    $g5 = NewGame 'game5' $other
    Check ((Install $pack1.Zip $g5) -ne 0) 'the installer stops with an error code'
    Check ((Audio $g5) -eq (Sha $other)) 'the game file is untouched'
    Check (-not (Test-Path -LiteralPath (Join-Path $g5 'PTBR-backup'))) 'no PTBR-backup'
    Check (-not (Test-Path -LiteralPath $ENTRY)) 'nothing installed'

    Write-Host '[6] A result that does not check out'
    $g6 = NewGame 'game6' $orig
    Check ((Install $packBad.Zip $g6) -ne 0) 'the installer stops with an error code'
    Check ((Audio $g6) -eq (Sha $orig)) 'the original audio is back in place'
    Check (-not (Test-Path -LiteralPath (Join-Path $g6 'PTBR-backup'))) 'no PTBR-backup left behind'
    Check (-not (Test-Path -LiteralPath (Join-Path $g6 'game\audio_d11generic.rpf.ptbr-novo'))) 'no leftover file'
    Check (-not (Test-Path -LiteralPath $ENTRY)) 'nothing installed'

    Write-Host '[7] A folder that is not the game'
    $g7 = Join-Path $work 'empty'; New-Item -ItemType Directory -Path $g7 | Out-Null
    Check ((Install $pack1.Zip $g7) -ne 0) 'the installer stops with an error code'
    Check (-not (Test-Path -LiteralPath $ENTRY)) 'nothing installed'

    Write-Host '[8] Uninstall after the game lost its backup'
    $g8 = NewGame 'game8' $orig
    Check ((Install $pack1.Zip $g8) -eq 0) 'installed'
    Remove-Item -LiteralPath (Join-Path $g8 'PTBR-backup') -Recurse -Force
    Check (Uninstall) 'the uninstaller still removes the entry'
    Check ((Audio $g8) -eq (Sha $dub1)) 'and leaves the game file alone'

    # Without internet the installer falls back to the official zip in the Downloads folder of this user.
    $downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    if (Test-Path -LiteralPath (Join-Path $downloads (Split-Path $TESTED_URL -Leaf))) {
        Write-Host '[9] No internet, the official zip is in Downloads'
        $g9 = NewGame 'game9' $orig
        $script:n++
        $log = Join-Path $work "setup-$($script:n).log"
        $p = Start-Process -FilePath $Setup -PassThru -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER',
            "/DIR=`"$APP`"", "/LOG=`"$log`"", "/MODPACK=`"$($pack1.Zip)`"", "/GAMEDIR=`"$g9`"", '/HDIFFPATCHURL=https://127.0.0.1:9/none.zip')
        [void]$p.WaitForExit(600000)
        Check ($p.ExitCode -eq 0) 'finishes with code 0'
        Check ((Audio $g9) -eq (Sha $dub1)) 'the game has the dubbed audio'
        Check (Uninstall) 'uninstalls'
    }
    else { Write-Host '[9] skipped: the official HDiffPatch zip is not in Downloads' }
}
finally {
    if (Test-Path -LiteralPath $ENTRY) { [void](Uninstall) }
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures -gt 0) { Write-Host "$failures check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All installer checks passed' -ForegroundColor Green
