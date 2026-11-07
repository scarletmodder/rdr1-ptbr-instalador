# Remove a dublagem PT-BR e devolve o arquivo original do jogo (Scarlet Modder).
# Alternativa pelo terminal. Para remover com dois cliques, use "Remover dublagem.cmd", que chama "Instalar dublagem.ps1 -Acao remover".
& (Join-Path $PSScriptRoot 'Instalar dublagem.ps1') -Acao remover
