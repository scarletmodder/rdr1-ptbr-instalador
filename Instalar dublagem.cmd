@echo off
rem Dublagem PT-BR do Red Dead Redemption (Scarlet Modder): de dois cliques neste arquivo para instalar.
rem Abre o "Instalar dublagem.ps1" liberando scripts so nesta execucao. Sem isso, o Windows que bloqueia
rem scripts (o padrao de fabrica) fecha a janela do PowerShell na hora, sem mostrar nada.
if not exist "%~dp0Instalar dublagem.ps1" (
    echo Falta o arquivo "Instalar dublagem.ps1" nesta pasta. Extraia o zip do instalador inteiro de novo.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar dublagem.ps1" %*
