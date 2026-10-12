# Instalador da dublagem PT-BR do Red Dead Redemption (PC)

Instalador automático e **opcional** da dublagem em português do Brasil do Red Dead Redemption de PC,
por Scarlet Modder. O mod em si (o patch de áudio) está no Nexus Mods:
https://www.nexusmods.com/reddeadredemption/mods/855

O Nexus Mods não aceita scripts nem programas dentro do pacote do mod, por isso o instalador fica aqui,
com o código aberto para quem quiser conferir. Dá para instalar sem ele, à mão (instruções no
LEIA-ME.txt do mod e na página do Nexus).

## O que o instalador faz por você

- Acha a pasta do jogo sozinho (Steam, Epic, Rockstar Games Launcher; no Linux, Steam nativa, Flatpak,
  cartão SD do Steam Deck e Heroic). Se não achar, deixa você escolher.
- Confere se o seu arquivo de áudio é o original antes de mexer (impressão digital SHA-256).
- Guarda o original numa pasta `PTBR-backup` dentro da pasta do jogo.
- Aplica o patch com o HDiffPatch oficial e confere o resultado.
- Remove a dublagem e devolve o original com um clique.
- Não acessa a internet, não mexe em saves, não precisa de administrador (só pede se o jogo estiver em
  "Arquivos de Programas").

## Requisito

O programa que aplica o patch, **HDiffPatch v5.1.3** (código aberto, licença MIT), baixado da página
oficial do autor. Não precisa extrair: deixe o .zip na pasta Downloads e o instalador acha e confere
a impressão digital dele.

- Windows: https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_windows64.zip
- Linux e Steam Deck: https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_linux64.zip

## Como usar

1. Baixe o mod no Nexus e extraia o .zip numa pasta.
2. Baixe o zip do instalador na página de [releases](../../releases/latest) e extraia **dentro da pasta do
   mod**, ao lado do `LEIA-ME.txt` e da pasta `dados`.
3. Windows: botão direito em `Instalar dublagem.ps1` > **Executar com o PowerShell**. Se o PowerShell
   perguntar sobre "política de execução", digite S e aperte Enter (vale só para essa execução).
   Para remover: botão direito em `Remover dublagem.ps1` > **Executar com o PowerShell**.
4. Linux e Steam Deck (Modo Desktop): abra um terminal na pasta do mod e rode `bash instalar-linux.sh`.
   Para remover: `bash instalar-linux.sh remover`.

## Licença

MIT. Veja `LICENSE`.
