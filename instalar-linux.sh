#!/usr/bin/env bash
# Red Dead Redemption (PC) dublado em PT-BR, mod de fã por Scarlet Modder.
# Instalador para Linux e SteamOS (Steam Deck), para o jogo rodando pelo Proton.
# Uso:
#   bash instalar-linux.sh                 instala (acha o jogo sozinho)
#   bash instalar-linux.sh remover         volta ao áudio original
#   bash instalar-linux.sh instalar "/caminho/da/pasta/do/jogo"
# Não precisa de sudo nem de internet. Guarda o original em <jogo>/PTBR-backup.
set -u

ACAO="${1:-instalar}"
PASTA="${2:-}"
RAIZ_TESTE="${RDRPTBR_TESTE_RAIZ:-}"   # só para teste do instalador
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DADOS="$AQUI/dados"
REL="game/audio_d11generic.rpf"
NOME_BACKUP="PTBR-backup"

sair() { echo; echo "$1"; exit "${2:-1}"; }
case "$ACAO" in instalar|remover) ;; *) sair "Uso: bash instalar-linux.sh [instalar|remover] [pasta do jogo]";; esac
[ -f "$DADOS/versao.json" ] || sair 'A pasta "dados" não está ao lado do instalador. Extraia o .zip inteiro e rode de novo.'

cfg() { sed -n "s/.*\"$1\": *\"\{0,1\}\([^\",]*\)\"\{0,1\},\{0,1\}.*/\1/p" "$DADOS/versao.json" | head -n1; }
VERSAO="$(cfg versao_mod)"; PATCH="$DADOS/$(cfg patch)"
ORIG_TAM="$(cfg original_tamanho)"; ORIG_SHA="$(cfg original_sha256 | tr 'A-F' 'a-f')"
DUB_TAM="$(cfg dublado_tamanho)"; DUB_SHA="$(cfg dublado_sha256 | tr 'A-F' 'a-f')"

echo "Red Dead Redemption: dublagem PT-BR v$VERSAO (mod de fã, Scarlet Modder)"
echo

if [ -z "$RAIZ_TESTE" ] && pgrep -if 'RDR\.exe|PlayRDR\.exe' >/dev/null 2>&1; then
  sair 'O jogo está aberto. Feche o Red Dead Redemption e rode de novo.'
fi

# ------------------------------------------------------------------ busca da pasta do jogo
ACHADOS=()
candidato() {
  local p="${1%/}"
  p="${p%/game}"; p="${p%/game/audio_d11generic.rpf}"
  [ -n "$p" ] && [ -f "$p/$REL" ] || return 0
  local a; for a in "${ACHADOS[@]+"${ACHADOS[@]}"}"; do [ "$a" = "$p" ] && return 0; done
  ACHADOS+=("$p")
}

if [ -n "$RAIZ_TESTE" ]; then CASA="$RAIZ_TESTE/home"; MIDIAS=("$RAIZ_TESTE/run/media"); else CASA="$HOME"; MIDIAS=(/run/media /media /mnt); fi

buscar_steam() {
  local bases=(
    "$CASA/.local/share/Steam"
    "$CASA/.steam/steam"
    "$CASA/.steam/root"
    "$CASA/.var/app/com.valvesoftware.Steam/.local/share/Steam"
    "$CASA/snap/steam/common/.local/share/Steam"
  )
  local libs=() b vdf l dir acf
  for b in "${bases[@]}"; do
    [ -d "$b" ] || continue
    libs+=("$b")
    vdf="$b/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
      while IFS= read -r l; do libs+=("$l"); done < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$vdf")
    fi
  done
  # cartão SD do Steam Deck e outros discos montados
  local m
  for m in "${MIDIAS[@]}"; do
    [ -d "$m" ] || continue
    while IFS= read -r l; do libs+=("$(dirname "$l")"); done < <(find "$m" -maxdepth 4 -type d -name steamapps 2>/dev/null)
  done
  for l in "${libs[@]+"${libs[@]}"}"; do
    [ -n "$RAIZ_TESTE" ] && case "$l" in "$RAIZ_TESTE"*) ;; *) l="$RAIZ_TESTE$l";; esac
    dir="Red Dead Redemption"
    acf="$l/steamapps/appmanifest_2668510.acf"
    if [ -f "$acf" ]; then
      d="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$acf" | head -n1)"
      [ -n "$d" ] && dir="$d"
    fi
    candidato "$l/steamapps/common/$dir"
  done
}

buscar_heroic() {  # Epic pelo Heroic Games Launcher (nativo ou Flatpak)
  local j p
  for j in "$CASA/.config/heroic/legendaryConfig/legendary/installed.json" \
           "$CASA/.var/app/com.heroicgameslauncher.hgl/config/heroic/legendaryConfig/legendary/installed.json" \
           "$CASA/.config/legendary/installed.json"; do
    [ -f "$j" ] || continue
    while IFS= read -r p; do candidato "$p"; done < <(sed -n 's/.*"install_path": *"\([^"]*\)".*/\1/p' "$j")
  done
  for p in "$CASA/Games/Heroic"/*; do candidato "$p"; done
}

buscar_lutris() {  # Rockstar ou Epic por Lutris/Bottles (prefixos Wine comuns)
  local p
  for p in "$CASA"/Games/*/drive_c/"Program Files"/"Rockstar Games"/* \
           "$CASA"/Games/*/drive_c/"Program Files"/"Epic Games"/* \
           "$CASA"/.wine/drive_c/"Program Files"/"Rockstar Games"/* \
           "$CASA"/.var/app/com.usebottles.bottles/data/bottles/bottles/*/drive_c/"Program Files"/*/*; do
    candidato "$p"
  done
}

if [ -n "$PASTA" ]; then
  candidato "$PASTA"
  [ ${#ACHADOS[@]} -gt 0 ] || sair "Não encontrei $REL dentro de: $PASTA"
else
  echo 'Procurando o Red Dead Redemption (Steam, Steam Flatpak, cartão SD, Heroic, Lutris)...'
  buscar_steam; buscar_heroic; buscar_lutris
fi

if [ ${#ACHADOS[@]} -eq 0 ]; then
  [ -t 0 ] || sair 'Não encontrei o jogo. Rode de novo informando a pasta: bash instalar-linux.sh instalar "/caminho/do/jogo"'
  echo 'Não achei o jogo sozinho.'
  echo 'Na Steam: botão direito no jogo > Gerenciar > Ver arquivos locais, e copie o caminho da pasta.'
  read -r -p 'Cole aqui o caminho da pasta do jogo (a que tem RDR.exe) e aperte Enter: ' PASTA
  candidato "$PASTA"
  [ ${#ACHADOS[@]} -gt 0 ] || sair "Não encontrei $REL dentro de: $PASTA"
fi

JOGO="${ACHADOS[0]}"
if [ ${#ACHADOS[@]} -gt 1 ] && [ -t 0 ]; then
  echo 'Achei mais de uma instalação:'
  i=1; for a in "${ACHADOS[@]}"; do echo "  $i) $a"; i=$((i+1)); done
  read -r -p 'Digite o número e aperte Enter: ' n
  case "$n" in ''|*[!0-9]*) sair 'Número inválido.';; esac
  [ "$n" -ge 1 ] && [ "$n" -le ${#ACHADOS[@]} ] || sair 'Número inválido.'
  JOGO="${ACHADOS[$((n-1))]}"
fi
echo "Jogo: $JOGO"

ALVO="$JOGO/$REL"
PB="$JOGO/$NOME_BACKUP"
BACKUP="$PB/audio_d11generic.rpf"
NOVO="$ALVO.ptbr-novo"

estado() {  # original | dublado | ausente | outro
  [ -f "$1" ] || { echo ausente; return; }
  local t; t="$(stat -c %s "$1")"
  [ "$t" = "$ORIG_TAM" ] || [ "$t" = "$DUB_TAM" ] || { echo outro; return; }
  echo 'Conferindo o arquivo de áudio do jogo (pode levar até 1 minuto)...' >&2
  local h; h="$(sha256sum "$1" | cut -d' ' -f1)"
  if [ "$h" = "$ORIG_SHA" ]; then echo original; elif [ "$h" = "$DUB_SHA" ]; then echo dublado; else echo outro; fi
}

touch "$JOGO/game/.ptbr-teste" 2>/dev/null && rm -f "$JOGO/game/.ptbr-teste" || sair "Sem permissão para escrever em $JOGO/game."

if [ "$ACAO" = remover ]; then
  if [ -f "$BACKUP" ]; then
    [ "$(estado "$BACKUP")" = original ] || sair "O backup em $PB não confere com o original. Use Verificar integridade dos arquivos na Steam."
    rm -f "$NOVO" "$ALVO"
    mv "$BACKUP" "$ALVO" && rmdir "$PB" 2>/dev/null
    sair 'Dublagem removida. O áudio original em inglês voltou.' 0
  fi
  [ "$(estado "$ALVO")" = original ] && sair 'O jogo já está com o áudio original. Nada a fazer.' 0
  sair 'Não achei o backup do original. Na Steam: Propriedades > Arquivos instalados > Verificar integridade.'
fi

E="$(estado "$ALVO")"
[ "$E" = dublado ] && sair "A dublagem v$VERSAO já está instalada neste jogo." 0
TEM_BACKUP=0
if [ -f "$BACKUP" ]; then
  [ "$(estado "$BACKUP")" = original ] || sair "Já existe $PB com um arquivo que não é o original. Nada foi alterado."
  TEM_BACKUP=1
fi
if [ $TEM_BACKUP -eq 0 ] && [ "$E" != original ]; then
  sair 'O arquivo de áudio do seu jogo é diferente do esperado (outra versão do jogo ou outro mod de áudio). Nada foi alterado. Verifique os arquivos pela loja e rode de novo.'
fi
[ -f "$PATCH" ] || sair 'Falta o arquivo do patch na pasta "dados". Extraia o .zip inteiro de novo.'

LIVRE=$(( $(df -Pk "$JOGO/game" | awk 'NR==2{print $4}') * 1024 ))
PRECISA=$(( DUB_TAM + 300*1024*1024 ))
[ "$LIVRE" -ge "$PRECISA" ] || sair "Falta espaço no disco do jogo: precisa de $((PRECISA/1024/1024/1024 + 1)) GB livres."

# O Nexus não aceita executáveis no pacote: o hpatchz vem do zip oficial do HDiffPatch v5.1.3 que a pessoa baixa
# do GitHub (Downloads ou pasta do mod). Confere o SHA-256 antes de usar.
HP_SHA=38b6a79b1c888308152072c672bec5d0d2a29892eb9ddcc92a295b852bfeb16d
HP_URL=https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_linux64.zip
if [ ! -f "$DADOS/hpatchz-linux" ]; then
  solto=$(find "$AQUI" -type f -name hpatchz 2>/dev/null | head -n1)
  if [ -n "$solto" ]; then cp "$solto" "$DADOS/hpatchz-linux"; fi
fi
if [ ! -f "$DADOS/hpatchz-linux" ]; then
  for d in "$AQUI" "$DADOS" "$CASA/Downloads" "$(xdg-user-dir DOWNLOAD 2>/dev/null)"; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    z=$(ls "$d"/hdiffpatch_v5.1.3_bin_linux64*.zip 2>/dev/null | head -n1)
    [ -n "$z" ] || continue
    if command -v unzip >/dev/null 2>&1; then unzip -p "$z" linux64/hpatchz > "$DADOS/hpatchz-linux" 2>/dev/null
    elif command -v bsdtar >/dev/null 2>&1; then bsdtar -xOf "$z" linux64/hpatchz > "$DADOS/hpatchz-linux" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then python3 -c 'import sys,zipfile;sys.stdout.buffer.write(zipfile.ZipFile(sys.argv[1]).read("linux64/hpatchz"))' "$z" > "$DADOS/hpatchz-linux" 2>/dev/null
    fi
    [ -s "$DADOS/hpatchz-linux" ] && break
    rm -f "$DADOS/hpatchz-linux"
  done
fi
if [ ! -s "$DADOS/hpatchz-linux" ]; then
  echo
  echo 'Falta o programa que aplica o patch (hpatchz, do HDiffPatch, código aberto).'
  echo 'O Nexus não deixa incluir programas no pacote, então baixe o zip oficial (cerca de 1 MB):'
  echo "  $HP_URL"
  echo 'Deixe o arquivo na pasta Downloads (não precisa extrair) e rode de novo.'
  sair 'Nada foi alterado no jogo.'
fi
if [ "$(sha256sum "$DADOS/hpatchz-linux" | cut -d' ' -f1)" != "$HP_SHA" ]; then
  rm -f "$DADOS/hpatchz-linux"
  sair "O hpatchz encontrado não é o oficial v5.1.3. Baixe de novo: $HP_URL"
fi

# o zip não guarda permissão de execução: copia o hpatchz para um lugar onde possa rodar
HP=""
for d in "$DADOS" "${XDG_RUNTIME_DIR:-}" "$CASA/.cache" /tmp; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  t="$d/rdrptbr-hpatchz"
  if cp "$DADOS/hpatchz-linux" "$t" 2>/dev/null && chmod +x "$t" 2>/dev/null && "$t" -v >/dev/null 2>&1; then HP="$t"; break; fi
  rm -f "$t" 2>/dev/null
done
[ -n "$HP" ] || sair 'Não consegui executar o hpatchz-linux (pasta sem permissão de execução). Extraia o .zip na sua pasta pessoal e rode de novo.'

if [ $TEM_BACKUP -eq 0 ]; then
  echo "Guardando o original em $PB ..."
  mkdir -p "$PB" && mv "$ALVO" "$BACKUP" || sair 'Não consegui guardar o original. Nada foi alterado.'
fi

desfazer() {
  rm -f "$NOVO" "$HP"
  if [ ! -f "$ALVO" ]; then mv "$BACKUP" "$ALVO"; rmdir "$PB" 2>/dev/null; fi
  sair "$1"
}

echo 'Aplicando a dublagem (de alguns segundos a poucos minutos)...'
rm -f "$NOVO"
"$HP" -f "$BACKUP" "$PATCH" "$NOVO" >/dev/null 2>&1 || desfazer 'O patch falhou. O jogo ficou com o áudio original.'
rm -f "$HP"
echo 'Conferindo o resultado...'
[ "$(stat -c %s "$NOVO")" = "$DUB_TAM" ] && [ "$(sha256sum "$NOVO" | cut -d' ' -f1)" = "$DUB_SHA" ] \
  || desfazer 'O arquivo gerado não confere. O jogo ficou com o áudio original.'
rm -f "$ALVO"
mv "$NOVO" "$ALVO"
sair "Pronto! Dublagem PT-BR v$VERSAO instalada. O original está guardado em $PB (não apague essa pasta). Abra o jogo." 0
