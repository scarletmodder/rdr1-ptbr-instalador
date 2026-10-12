param(
    [ValidateSet('instalar', 'remover')][string]$Acao = 'instalar',
    [string]$Pasta = '',
    [switch]$SemPausa,
    [string]$TesteRaiz = ''
)
# Red Dead Redemption (PC) dublado em PT-BR, mod de fã por Scarlet Modder.
# Instala ou remove a dublagem. Guarda o arquivo original do jogo numa pasta de backup ao lado do
# jogo e aplica um patch sobre ele: nenhum arquivo do jogo vem neste pacote.
# -Pasta: pasta do jogo (a que tem RDR.exe), se a busca automática não achar.
# -TesteRaiz: só para teste do instalador (simula as lojas numa pasta, sem ler o registro real).
$ErrorActionPreference = 'Stop'

$Dados = Join-Path $PSScriptRoot 'dados'
$Rel = 'game\audio_d11generic.rpf'
$NomeBackup = 'PTBR-backup'
$Processos = @('RDR', 'PlayRDR')

function Pausa { if (-not $SemPausa) { Write-Host ''; Read-Host 'Aperte Enter para fechar' | Out-Null } }
function Sair([string]$msg, [int]$codigo = 1) {
    Write-Host ''
    if ($codigo -eq 0) { Write-Host $msg -ForegroundColor Green } else { Write-Host $msg -ForegroundColor Yellow }
    Pausa
    exit $codigo
}
function Info([string]$msg) { Write-Host $msg }

if (-not (Test-Path -LiteralPath (Join-Path $Dados 'versao.json'))) {
    Sair 'A pasta "dados" não está ao lado do instalador. Extraia o arquivo .zip inteiro e rode de novo.'
}
$cfg = Get-Content -LiteralPath (Join-Path $Dados 'versao.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$Hpatch = Join-Path $Dados 'hpatchz.exe'
$PatchArq = Join-Path $Dados $cfg.patch

# Arquivos baixados da internet ficam marcados pelo Windows; desmarca só os do próprio pacote.
Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    try { Unblock-File -LiteralPath $_.FullName -ErrorAction Stop } catch { }
}

# ------------------------------------------------------------------ busca da pasta do jogo
$Achados = New-Object System.Collections.ArrayList

function Normalizar([string]$p) {
    if (-not $p) { return $null }
    $p = $p.Trim().Trim('"') -replace '/', '\'
    $p = $p.TrimEnd('\')
    if ($p -match '\\game$') { $p = $p.Substring(0, $p.Length - 5) }
    if ($p -match '\\audio_d11generic\.rpf$') { $p = Split-Path (Split-Path $p -Parent) -Parent }
    return $p
}

function Candidato([string]$loja, [string]$raiz) {
    $raiz = Normalizar $raiz
    if (-not $raiz) { return }
    try { if (-not (Test-Path -LiteralPath (Join-Path $raiz $Rel))) { return } } catch { return }
    foreach ($a in $Achados) { if ($a.Raiz -ieq $raiz) { return } }
    [void]$Achados.Add([pscustomobject]@{ Loja = $loja; Raiz = $raiz })
}

function RaizesRegistro {
    if ($TesteRaiz) { return @('HKCU:\Software\RDRPTBRTeste') }
    return @('HKCU:\Software', 'HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\WOW6432Node')
}

function LerReg([string]$chave, [string]$nome) {
    try { return (Get-ItemProperty -LiteralPath $chave -Name $nome -ErrorAction Stop).$nome } catch { return $null }
}

function Buscar-Steam {
    $bases = @()
    foreach ($r in RaizesRegistro) {
        foreach ($n in 'SteamPath', 'InstallPath') {
            $v = LerReg (Join-Path $r 'Valve\Steam') $n
            if ($v) { $bases += (Normalizar $v) }
        }
    }
    if (-not $TesteRaiz) { $bases += (Join-Path ${env:ProgramFiles(x86)} 'Steam') }
    $libs = @()
    foreach ($b in ($bases | Select-Object -Unique)) {
        $libs += $b
        $vdf = Join-Path $b 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            $t = Get-Content -LiteralPath $vdf -Raw
            foreach ($m in [regex]::Matches($t, '"path"\s+"([^"]+)"')) { $libs += ($m.Groups[1].Value -replace '\\\\', '\') }
        }
    }
    foreach ($l in ($libs | Select-Object -Unique)) {
        $dir = 'Red Dead Redemption'
        $acf = Join-Path $l 'steamapps\appmanifest_2668510.acf'
        if (Test-Path -LiteralPath $acf) {
            $t = Get-Content -LiteralPath $acf -Raw
            if ($t -match '"installdir"\s+"([^"]+)"') { $dir = $Matches[1] }
        }
        Candidato 'Steam' (Join-Path $l "steamapps\common\$dir")
    }
}

function Buscar-Epic {
    if ($TesteRaiz) {
        $man = Join-Path $TesteRaiz 'Epic\Manifests'
        $dat = Join-Path $TesteRaiz 'Epic\LauncherInstalled.dat'
    } else {
        $man = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
        $dat = Join-Path $env:ProgramData 'Epic\UnrealEngineLauncher\LauncherInstalled.dat'
    }
    if (Test-Path -LiteralPath $man) {
        foreach ($f in Get-ChildItem -LiteralPath $man -Filter '*.item' -File -ErrorAction SilentlyContinue) {
            try { $j = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
            if ($j.InstallLocation) { Candidato 'Epic Games Store' $j.InstallLocation }
        }
    }
    if (Test-Path -LiteralPath $dat) {
        try {
            $j = Get-Content -LiteralPath $dat -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($i in $j.InstallationList) { if ($i.InstallLocation) { Candidato 'Epic Games Store' $i.InstallLocation } }
        } catch { }
    }
}

function Buscar-Rockstar {
    foreach ($r in RaizesRegistro) {
        $base = Join-Path $r 'Rockstar Games'
        if (Test-Path -LiteralPath $base) {
            foreach ($k in Get-ChildItem -LiteralPath $base -ErrorAction SilentlyContinue) {
                foreach ($n in 'InstallFolder', 'InstallLocation') {
                    $v = LerReg $k.PSPath $n
                    if ($v) { Candidato 'Rockstar Games Launcher' $v }
                }
            }
        }
        $un = Join-Path $r 'Microsoft\Windows\CurrentVersion\Uninstall'
        if (Test-Path -LiteralPath $un) {
            foreach ($k in Get-ChildItem -LiteralPath $un -ErrorAction SilentlyContinue) {
                $nome = LerReg $k.PSPath 'DisplayName'
                if ($nome -and $nome -match 'Red Dead Redemption' -and $nome -notmatch 'Redemption 2') {
                    $v = LerReg $k.PSPath 'InstallLocation'
                    $loja = 'Rockstar Games Launcher'
                    if ($v -match 'steamapps') { $loja = 'Steam' } elseif ($v -match 'Epic Games') { $loja = 'Epic Games Store' }
                    if ($v) { Candidato $loja $v }
                }
            }
        }
    }
}

function Raizes-Disco {
    if ($TesteRaiz) { return @(Join-Path $TesteRaiz 'disco') }
    return @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object { $_.Root.TrimEnd('\') })
}

function Buscar-Padrao {
    foreach ($d in Raizes-Disco) {
        foreach ($sub in 'Program Files\Rockstar Games\Red Dead Redemption', 'Rockstar Games\Red Dead Redemption',
                         'Program Files\Epic Games\RedDeadRedemption', 'Program Files\Epic Games\Red Dead Redemption',
                         'Epic Games\RedDeadRedemption', 'Epic Games\Red Dead Redemption',
                         'SteamLibrary\steamapps\common\Red Dead Redemption', 'Steam\steamapps\common\Red Dead Redemption') {
            $p = Join-Path $d $sub
            $loja = 'Rockstar Games Launcher'
            if ($sub -match 'Epic') { $loja = 'Epic Games Store' } elseif ($sub -match 'steamapps') { $loja = 'Steam' }
            Candidato $loja $p
        }
        $xb = Join-Path $d 'XboxGames'
        if (Test-Path -LiteralPath $xb) {
            foreach ($g in Get-ChildItem -LiteralPath $xb -Directory -Filter 'Red Dead Redemption*' -ErrorAction SilentlyContinue) {
                Candidato 'Xbox (Microsoft Store)' (Join-Path $g.FullName 'Content')
                Candidato 'Xbox (Microsoft Store)' $g.FullName
            }
        }
    }
    if (-not $TesteRaiz) {
        try {
            foreach ($p in Get-AppxPackage -Name 'RockstarGamesInc.KalonPC' -ErrorAction Stop) { Candidato 'Xbox (Microsoft Store)' $p.InstallLocation }
        } catch { }
    }
}

function Escolher-Pasta {
    if ($SemPausa) { return $null }
    Info 'Não achei o jogo sozinho. Vai abrir uma janela: escolha a pasta do Red Dead Redemption (a que tem o RDR.exe).'
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Escolha a pasta do Red Dead Redemption (a que tem o RDR.exe)'
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
    } catch { }
    return (Read-Host 'Ou cole aqui o caminho da pasta do jogo e aperte Enter')
}

function Achar-Jogo {
    if ($Pasta) {
        Candidato 'escolhida' $Pasta
        if ($Achados.Count -eq 0) { Sair "Não encontrei game\audio_d11generic.rpf dentro de: $Pasta" }
        return $Achados[0]
    }
    Info 'Procurando o Red Dead Redemption (Steam, Epic, Rockstar, Xbox)...'
    Buscar-Steam; Buscar-Epic; Buscar-Rockstar; Buscar-Padrao
    if ($Achados.Count -eq 0) {
        $p = Escolher-Pasta
        if ($p) { Candidato 'escolhida' $p }
        if ($Achados.Count -eq 0) { Sair 'Não encontrei o jogo. Rode de novo e escolha a pasta onde está o RDR.exe.' }
    }
    if ($Achados.Count -eq 1) { return $Achados[0] }
    Info 'Achei mais de uma instalação:'
    for ($i = 0; $i -lt $Achados.Count; $i++) { Info ("  {0}) {1}: {2}" -f ($i + 1), $Achados[$i].Loja, $Achados[$i].Raiz) }
    if ($SemPausa) { return $Achados[0] }
    $n = Read-Host 'Digite o número da instalação e aperte Enter'
    $i = 0
    if (-not [int]::TryParse($n, [ref]$i) -or $i -lt 1 -or $i -gt $Achados.Count) { Sair 'Número inválido. Rode de novo.' }
    return $Achados[$i - 1]
}

# ------------------------------------------------------------------ conferências
function Hash([string]$arq) {
    return (Get-FileHash -LiteralPath $arq -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Estado([string]$arq) {
    if (-not (Test-Path -LiteralPath $arq)) { return 'ausente' }
    $tam = (Get-Item -LiteralPath $arq).Length
    if ($tam -ne [int64]$cfg.original_tamanho -and $tam -ne [int64]$cfg.dublado_tamanho) { return 'outro' }
    Info 'Conferindo o arquivo de áudio do jogo (pode levar até 1 minuto)...'
    $h = Hash $arq
    if ($h -eq $cfg.original_sha256) { return 'original' }
    if ($h -eq $cfg.dublado_sha256) { return 'dublado' }
    return 'outro'
}

function Jogo-Aberto {
    foreach ($p in $Processos) { if (Get-Process -Name $p -ErrorAction SilentlyContinue) { return $true } }
    return $false
}

function E-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Pode-Escrever([string]$pasta) {
    $t = Join-Path $pasta ('ptbr-teste-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try { [IO.File]::WriteAllText($t, 'ok'); Remove-Item -LiteralPath $t -Force; return $true } catch { return $false }
}

function Pedir-Admin($jogo) {
    if ($jogo.Raiz -match '\\WindowsApps\\' -or $jogo.Loja -match 'Xbox') {
        Sair ('O Windows não deixa alterar os arquivos da versão do Xbox (Microsoft Store) nesta pasta: ' + $jogo.Raiz +
              '. Esta dublagem funciona nas versões Steam, Epic e Rockstar. Veja o LEIA-ME.')
    }
    if ((E-Admin) -or $SemPausa) { Sair "Sem permissão para escrever em $($jogo.Raiz). Feche o jogo e o launcher e tente de novo." }
    $r = Read-Host 'A pasta do jogo pede permissão de administrador. Abrir de novo como administrador? (S/N)'
    if ($r -notmatch '^[sS]') { Sair 'Nada foi alterado.' }
    $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Acao', $Acao, '-Pasta', "`"$($jogo.Raiz)`"")
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argumentos -Verb RunAs
    exit 0
}

# ------------------------------------------------------------------ ações
Write-Host ("Red Dead Redemption: dublagem PT-BR v{0} (mod de fã, Scarlet Modder)" -f $cfg.versao_mod) -ForegroundColor Cyan
Write-Host ''
if (Jogo-Aberto) { Sair 'O jogo está aberto. Feche o Red Dead Redemption e rode de novo.' }

$jogo = Achar-Jogo
Info ("Jogo: {0} ({1})" -f $jogo.Raiz, $jogo.Loja)
$alvo = Join-Path $jogo.Raiz $Rel
$pastaBackup = Join-Path $jogo.Raiz $NomeBackup
$backup = Join-Path $pastaBackup 'audio_d11generic.rpf'
$novo = "$alvo.ptbr-novo"

if (-not (Pode-Escrever (Split-Path $alvo -Parent))) { Pedir-Admin $jogo }

if ($Acao -eq 'remover') {
    if (Test-Path -LiteralPath $backup) {
        if ((Estado $backup) -ne 'original') {
            Sair ("O backup em $pastaBackup não confere com o original. Para voltar ao inglês, use a verificação " +
                  'de arquivos da loja (Steam: Propriedades > Arquivos instalados > Verificar integridade).')
        }
        if (Test-Path -LiteralPath $novo) { Remove-Item -LiteralPath $novo -Force }
        if (Test-Path -LiteralPath $alvo) { Remove-Item -LiteralPath $alvo -Force }
        Move-Item -LiteralPath $backup -Destination $alvo
        Remove-Item -LiteralPath $pastaBackup -Force -Recurse -ErrorAction SilentlyContinue
        Sair 'Dublagem removida. O áudio original em inglês voltou.' 0
    }
    $e = Estado $alvo
    if ($e -eq 'original') { Sair 'O jogo já está com o áudio original. Nada a fazer.' 0 }
    Sair ('Não achei o backup do original. Para voltar ao inglês, use a verificação de arquivos da loja ' +
          '(Steam: Propriedades > Arquivos instalados > Verificar integridade; Epic: Gerenciar > Verificar; ' +
          'Rockstar: Configurações > o jogo > Verificar integridade).')
}

# instalar
$eAlvo = Estado $alvo
if ($eAlvo -eq 'dublado') { Sair "A dublagem v$($cfg.versao_mod) já está instalada neste jogo." 0 }

$temBackup = Test-Path -LiteralPath $backup
if ($temBackup -and (Estado $backup) -ne 'original') {
    Sair "Já existe uma pasta $NomeBackup com um arquivo que não é o original. Nada foi alterado; apague essa pasta só se tiver certeza e rode de novo."
}
if (-not $temBackup -and $eAlvo -ne 'original') {
    Sair ('O arquivo de áudio do seu jogo é diferente do esperado (outra versão do jogo ou outro mod de áudio). ' +
          'Nada foi alterado. Verifique os arquivos pela loja para voltar ao original e rode de novo. ' +
          'Se o jogo atualizou, aguarde uma versão nova do mod.')
}
if (-not (Test-Path -LiteralPath $PatchArq)) {
    Sair 'Faltam arquivos na pasta "dados". Extraia o .zip inteiro de novo.'
}
# O Nexus não aceita executáveis no pacote: o hpatchz.exe vem do zip oficial do HDiffPatch v5.1.3 que a pessoa
# baixa do GitHub (Downloads ou pasta do mod). Confere o SHA-256 do programa antes de usar.
$HpatchSha = '9703C694B5955C576D9F0E26E98B60941F0BBB53B382B1F1988D75D461E580CB'
$HpatchUrl = 'https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_windows64.zip'
if (-not (Test-Path -LiteralPath $Hpatch)) {
    $soltos = @(Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -Filter 'hpatchz.exe' -File -ErrorAction SilentlyContinue)
    if ($soltos.Count -gt 0) { Copy-Item -LiteralPath $soltos[0].FullName -Destination $Hpatch }
}
if (-not (Test-Path -LiteralPath $Hpatch)) {
    $pastas = @($PSScriptRoot, $Dados, (Join-Path $env:USERPROFILE 'Downloads'))
    try { $pastas += (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path } catch { }
    $zipHp = $pastas | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | ForEach-Object {
        Get-ChildItem -LiteralPath $_ -Filter 'hdiffpatch_v5.1.3_bin_windows64*.zip' -File -ErrorAction SilentlyContinue
    } | Select-Object -First 1
    if ($zipHp) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $z = [System.IO.Compression.ZipFile]::OpenRead($zipHp.FullName)
        try {
            $ent = $z.Entries | Where-Object { $_.FullName -eq 'windows64/hpatchz.exe' } | Select-Object -First 1
            if ($ent) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($ent, $Hpatch, $true) }
        } finally { $z.Dispose() }
    }
}
if (-not (Test-Path -LiteralPath $Hpatch)) {
    Write-Host ''
    Write-Host 'Falta o programa que aplica o patch (hpatchz, do HDiffPatch, código aberto).' -ForegroundColor Yellow
    Write-Host 'O Nexus não deixa incluir programas no pacote, então baixe o zip oficial (1 clique, cerca de 1 MB):'
    Write-Host "  $HpatchUrl" -ForegroundColor Cyan
    Write-Host 'Deixe o arquivo na pasta Downloads (não precisa extrair) e rode o instalador de novo.'
    Sair 'Nada foi alterado no jogo.'
}
if ((Get-FileHash -LiteralPath $Hpatch -Algorithm SHA256).Hash -ne $HpatchSha) {
    Remove-Item -LiteralPath $Hpatch -Force -ErrorAction SilentlyContinue
    Sair "O hpatchz.exe encontrado não é o oficial v5.1.3 (impressão digital diferente). Baixe de novo pelo link oficial: $HpatchUrl"
}
$livre = (Get-PSDrive -Name ($jogo.Raiz.Substring(0, 1))).Free
$precisa = [int64]$cfg.dublado_tamanho + 300MB
if ($livre -lt $precisa) {
    Sair ("Falta espaço no disco do jogo: precisa de {0:N1} GB livres, tem {1:N1} GB." -f ($precisa / 1GB), ($livre / 1GB))
}

if (-not $temBackup) {
    Info "Guardando o original em $pastaBackup ..."
    New-Item -ItemType Directory -Force -Path $pastaBackup | Out-Null
    Move-Item -LiteralPath $alvo -Destination $backup
}

Info 'Aplicando a dublagem (de alguns segundos a poucos minutos)...'
if (Test-Path -LiteralPath $novo) { Remove-Item -LiteralPath $novo -Force }
& $Hpatch -f $backup $PatchArq $novo | Out-Null
$rc = $LASTEXITCODE

function Desfazer([string]$msg) {
    if (Test-Path -LiteralPath $novo) { Remove-Item -LiteralPath $novo -Force }
    if (-not (Test-Path -LiteralPath $alvo)) { Move-Item -LiteralPath $backup -Destination $alvo; Remove-Item -LiteralPath $pastaBackup -Force -Recurse -ErrorAction SilentlyContinue }
    Sair $msg
}

if ($rc -ne 0 -or -not (Test-Path -LiteralPath $novo)) { Desfazer "O patch falhou (código $rc). O jogo ficou com o áudio original." }
Info 'Conferindo o resultado...'
if ((Get-Item -LiteralPath $novo).Length -ne [int64]$cfg.dublado_tamanho -or (Hash $novo) -ne $cfg.dublado_sha256) {
    Desfazer 'O arquivo gerado não confere. O jogo ficou com o áudio original. Rode de novo; se repetir, avise na página do mod.'
}
if (Test-Path -LiteralPath $alvo) { Remove-Item -LiteralPath $alvo -Force }
Move-Item -LiteralPath $novo -Destination $alvo
Sair "Pronto! Dublagem PT-BR v$($cfg.versao_mod) instalada. O original está guardado em $pastaBackup (não apague essa pasta). Abra o jogo." 0
