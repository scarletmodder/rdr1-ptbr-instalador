# Changelog

As versões seguem o [versionamento semântico](https://semver.org/lang/pt-BR/). A versão deste instalador é independente da versão da dublagem: o mesmo instalador aplica qualquer versão publicada no [Nexus Mods](https://www.nexusmods.com/reddeadredemption/mods/855).

## [1.0.1] - 2026-11-07

### Corrigido

- Scripts de Windows: abertos de um terminal do PowerShell 7, os lançadores `.cmd` paravam com `Erro inesperado` antes de mexer no jogo, porque o Windows PowerShell herdava a lista de módulos do PowerShell 7. Os lançadores agora limpam essa lista, e o teste dos scripts cobre esse caso. O instalador `.exe` não muda.

## [1.0.0] - 2026-11-07

### Adicionado

- Instalador com telas para Windows (`Instalador-Dublagem-PTBR-RDR1-v1.0.0.exe`), feito no Inno Setup, sem terminal nem script.
- Busca automática do .zip da dublagem (Downloads, Área de Trabalho, Documentos e a pasta do instalador) e do jogo (Steam, Epic, Rockstar Games Launcher e pastas comuns).
- Link para a página do mod no Nexus Mods nas telas de boas-vindas e da dublagem.
- Download do HDiffPatch oficial, do repositório do autor, com o hash da versão testada conferido. Sem internet, usa o .zip oficial que estiver na pasta Downloads.
- Remoção pela lista de aplicativos do Windows e pelo atalho do menu Iniciar, com o original conferido pelo hash antes de voltar.
- Guia de instalação com as telas (`docs/installation.md`), testes de ponta a ponta num jogo sintético, CI e release automática.
- Retomada depois de interrupção, no .exe e nos scripts de Windows: se o computador desligar no meio, rodar de novo termina a aplicação a partir do original guardado.
- Lançadores `Instalar dublagem.cmd` e `Remover dublagem.cmd` para os scripts de Windows.

### Corrigido

- Scripts de Windows: numa atualização ou remoção, o arquivo que estava no jogo só é apagado depois que o novo está no lugar. Com o original guardado, só uma dublagem publicada (ou nada) é substituída; um arquivo desconhecido fica como está.

### Mudado

- O instalador recomendado para Windows deixa de ser o script `Instalar dublagem.ps1`. No Windows 11, "Executar com o PowerShell" não libera a política de execução e a janela fechava sem fazer nada.
- O zip de scripts (`Instalador-Dublagem-PTBR-RDR1-Scripts-v1.0.0.zip`) mantém o formato da 0.7.1, com o `instalar-linux.sh` para Linux e Steam Deck e os scripts de Windows, agora com os lançadores `.cmd`.

## [0.7.1] - 2026-10-13

### Adicionado

- Primeira versão: scripts de instalação e remoção para Windows (PowerShell) e para Linux e Steam Deck (bash).

[1.0.1]: https://github.com/scarletmodder/rdr1-ptbr-instalador/releases/tag/v1.0.1
[1.0.0]: https://github.com/scarletmodder/rdr1-ptbr-instalador/releases/tag/v1.0.0
[0.7.1]: https://github.com/scarletmodder/rdr1-ptbr-instalador/releases/tag/v0.7.1
