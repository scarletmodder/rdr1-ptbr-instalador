@echo off
rem Dublagem PT-BR do Red Dead Redemption (Scarlet Modder): de dois cliques neste arquivo para remover
rem a dublagem e devolver o audio original em ingles.
if not exist "%~dp0Instalar dublagem.ps1" (
    echo Falta o arquivo "Instalar dublagem.ps1" nesta pasta. Extraia o zip do instalador inteiro de novo.
    pause
    exit /b 1
)
rem Aberto de um terminal do PowerShell 7, o Windows PowerShell herdaria a lista de modulos dele e nao acharia
rem os comandos basicos (Get-FileHash, Expand-Archive). Vazia, ele monta a lista padrao.
set "PSModulePath="
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar dublagem.ps1" -Acao remover %*
