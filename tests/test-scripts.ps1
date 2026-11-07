# Tests the Windows scripts (the alternative to the .exe) through their .cmd launchers, as a person would
# open them: the launcher must run the script even where Windows blocks scripts. Synthetic game, never the real one.
[CmdletBinding()]
param([string]$HdiffpatchZip)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$root = Split-Path $PSScriptRoot -Parent
$TESTED_URL = 'https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_windows64.zip'
$TESTED_SHA = '77F141386E5D8F785C1C846E10FBBC19B6C05AA00E3F59CC44670FB3F0E2AE94'

$work = Join-Path ([IO.Path]::GetTempPath()) ('rdr1-ptbr-scripts-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
$failures = 0
function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "  ok   $what" -ForegroundColor Green }
    else { Write-Host "  FAIL $what" -ForegroundColor Red; $script:failures++ }
}
function Sha([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

try {
    if (-not $HdiffpatchZip) {
        $HdiffpatchZip = Join-Path $work 'hdiffpatch.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object Net.WebClient).DownloadFile($TESTED_URL, $HdiffpatchZip)
    }
    if ((Sha $HdiffpatchZip) -ne $TESTED_SHA) { throw 'The HDiffPatch zip is not the official v5.1.3' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($HdiffpatchZip, (Join-Path $work 'hdp'))

    # A synthetic original and dub, and the mod folder as it looks after extracting the Nexus zip and the scripts zip.
    $rng = New-Object Random 5
    $orig = Join-Path $work 'original.rpf'; $b = New-Object byte[] 2000000; $rng.NextBytes($b); [IO.File]::WriteAllBytes($orig, $b)
    for ($i = 0; $i -lt 300; $i++) { $b[$rng.Next($b.Length)] = [byte]$rng.Next(256) }
    $dub = Join-Path $work 'dub.rpf'; [IO.File]::WriteAllBytes($dub, $b)
    $mod = Join-Path $work 'mod'
    $dados = Join-Path $mod 'dados'
    New-Item -ItemType Directory -Force -Path $dados | Out-Null
    & (Join-Path $work 'hdp\windows64\hdiffz.exe') -f $orig $dub (Join-Path $dados 'rdr1-ptbr-v1.0.hdiff') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'hdiffz failed' }
    $json = "{`n  `"versao_mod`": `"1.0`",`n  `"patch`": `"rdr1-ptbr-v1.0.hdiff`",`n  `"original_tamanho`": $((Get-Item $orig).Length),`n" +
            "  `"original_sha256`": `"$(Sha $orig)`",`n  `"dublado_tamanho`": $((Get-Item $dub).Length),`n  `"dublado_sha256`": `"$(Sha $dub)`"`n}`n"
    [IO.File]::WriteAllText((Join-Path $dados 'versao.json'), $json)
    foreach ($name in 'Instalar dublagem.cmd', 'Remover dublagem.cmd', 'Instalar dublagem.ps1', 'Remover dublagem.ps1') {
        Copy-Item -LiteralPath (Join-Path $root $name) -Destination $mod
    }
    Copy-Item -LiteralPath $HdiffpatchZip -Destination (Join-Path $mod (Split-Path $TESTED_URL -Leaf))

    $game = Join-Path $work 'Red Dead Redemption'
    New-Item -ItemType Directory -Force -Path (Join-Path $game 'game') | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $game 'RDR.exe'), [byte[]](0x4D, 0x5A))
    Copy-Item -LiteralPath $orig -Destination (Join-Path $game 'game\audio_d11generic.rpf')
    $audio = Join-Path $game 'game\audio_d11generic.rpf'

    # The launchers must work even when the session asks for blocked scripts.
    $env:PSExecutionPolicyPreference = 'Restricted'
    # Run from a PowerShell 7 terminal, Windows PowerShell would inherit its module path; the launchers clear it.
    # This test keeps whatever module path the parent has, so under PowerShell 7 it covers that case.

    Write-Host '[1] Instalar dublagem.cmd'
    & cmd.exe /c "`"$mod\Instalar dublagem.cmd`" -Pasta `"$game`" -SemPausa" | Out-Null
    Check ($LASTEXITCODE -eq 0) 'finishes with code 0'
    Check ((Sha $audio) -eq (Sha $dub)) 'the game has the dubbed audio'
    Check ((Sha (Join-Path $game 'PTBR-backup\audio_d11generic.rpf')) -eq (Sha $orig)) 'the original is in PTBR-backup'

    Write-Host '[2] Remover dublagem.cmd'
    & cmd.exe /c "`"$mod\Remover dublagem.cmd`" -Pasta `"$game`" -SemPausa" | Out-Null
    Check ($LASTEXITCODE -eq 0) 'finishes with code 0'
    Check ((Sha $audio) -eq (Sha $orig)) 'the original audio is back'
    Check (-not (Test-Path -LiteralPath (Join-Path $game 'PTBR-backup'))) 'PTBR-backup is gone'

    Write-Host '[3] A run cut in the middle: the audio file is gone, the original waits in PTBR-backup'
    $backup = Join-Path $game 'PTBR-backup\audio_d11generic.rpf'
    New-Item -ItemType Directory -Path (Join-Path $game 'PTBR-backup') | Out-Null
    Move-Item -LiteralPath $audio -Destination $backup
    & cmd.exe /c "`"$mod\Instalar dublagem.cmd`" -Pasta `"$game`" -SemPausa" | Out-Null
    Check ($LASTEXITCODE -eq 0) 'finishes with code 0'
    Check ((Sha $audio) -eq (Sha $dub)) 'the game has the dubbed audio'
    Check (-not (Test-Path -LiteralPath "$audio.ptbr-velho")) 'no leftover file'

    Write-Host '[4] Install over an unknown file while the original waits in PTBR-backup'
    $other = New-Object byte[] 1500000; $rng.NextBytes($other); [IO.File]::WriteAllBytes($audio, $other)
    $otherSha = Sha $audio
    & cmd.exe /c "`"$mod\Instalar dublagem.cmd`" -Pasta `"$game`" -SemPausa" | Out-Null
    Check ($LASTEXITCODE -ne 0) 'the script refuses'
    Check ((Sha $audio) -eq $otherSha) 'the game file is untouched'
    Check ((Sha $backup) -eq (Sha $orig)) 'the original stays in PTBR-backup'
}
finally {
    Remove-Item Env:\PSExecutionPolicyPreference -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures -gt 0) { Write-Host "$failures check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All script checks passed' -ForegroundColor Green
# The last native command (a run expected to fail) would otherwise set the exit code of this script.
exit 0
