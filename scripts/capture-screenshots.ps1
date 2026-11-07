# Walks through the installer and the uninstaller and saves a picture of each screen in docs\images.
# Maintainer tool: run it on a test game folder and a package path WITHOUT the user name in them
# (for example D:\Jogos\Red Dead Redemption and D:\Downloads\...zip), because the screens show both paths.
# It clicks through UI Automation and takes each picture with PrintWindow, so the desktop is never captured.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GameDir,
    [Parameter(Mandatory)][string]$ModPack,
    [string]$Setup,
    [string]$Out
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$root = Split-Path $PSScriptRoot -Parent
if (-not $Setup) { $Setup = (Get-ChildItem -LiteralPath (Join-Path $root 'dist') -Filter 'Instalador-*.exe' | Select-Object -First 1).FullName }
if (-not $Out) { $Out = Join-Path $root 'docs\images' }
foreach ($p in $GameDir, $ModPack) {
    if ($p -match [regex]::Escape($env:USERNAME)) { throw "The path shows the user name: $p" }
}
New-Item -ItemType Directory -Force -Path $Out | Out-Null

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Snap {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
'@

$UIA = [Windows.Automation.AutomationElement]
$Tree = [Windows.Automation.TreeScope]

function FindWindow([string]$titlePart, [int]$seconds = 60) {
    for ($i = 0; $i -lt $seconds * 4; $i++) {
        foreach ($w in $UIA::RootElement.FindAll($Tree::Children, [Windows.Automation.Condition]::TrueCondition)) {
            if ($w.Current.Name -like "*$titlePart*") { return $w }
        }
        Start-Sleep -Milliseconds 250
    }
    throw "Window not found: $titlePart"
}

function FindButton($window, [string]$namePart, [int]$seconds = 600) {
    # The wizard buttons show up as panes in UI Automation, so the search is by name and the click is BM_CLICK.
    $cond = [Windows.Automation.Condition]::TrueCondition
    for ($i = 0; $i -lt $seconds * 4; $i++) {
        foreach ($b in $window.FindAll($Tree::Descendants, $cond)) {
            if ($b.Current.Name -like "$namePart*" -and $b.Current.NativeWindowHandle -ne 0 -and $b.Current.IsEnabled -and -not $b.Current.IsOffscreen) { return $b }
        }
        Start-Sleep -Milliseconds 250
    }
    throw "Button not found: $namePart"
}

function HasText($window, [string]$part) {
    foreach ($e in $window.FindAll($Tree::Descendants, [Windows.Automation.Condition]::TrueCondition)) {
        if ($e.Current.Name -like "*$part*" -and -not $e.Current.IsOffscreen) { return $true }
    }
    return $false
}

function Click($button) {
    [void][Snap]::PostMessage([IntPtr]$button.Current.NativeWindowHandle, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 1200
}

function Shot($window, [string]$name) {
    Start-Sleep -Milliseconds 600
    $h = [IntPtr]$window.Current.NativeWindowHandle
    $r = New-Object Snap+RECT
    # The visible frame (without the invisible resize border of Windows 10 and 11).
    if ([Snap]::DwmGetWindowAttribute($h, 9, [ref]$r, 16) -ne 0) { [void][Snap]::GetWindowRect($h, [ref]$r) }
    $full = New-Object Snap+RECT
    [void][Snap]::GetWindowRect($h, [ref]$full)
    $bmp = New-Object Drawing.Bitmap ($full.Right - $full.Left), ($full.Bottom - $full.Top)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [void][Snap]::PrintWindow($h, $hdc, 2)
    $g.ReleaseHdc($hdc); $g.Dispose()
    $crop = New-Object Drawing.Rectangle ($r.Left - $full.Left), ($r.Top - $full.Top), ($r.Right - $r.Left), ($r.Bottom - $r.Top)
    $final = $bmp.Clone($crop, $bmp.PixelFormat)
    $path = Join-Path $Out "$name.png"
    $final.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $final.Dispose(); $bmp.Dispose()
    Write-Host "saved $name.png"
}

$title = 'Dublagem PT-BR do Red Dead Redemption'
$proc = Start-Process -FilePath $Setup -ArgumentList @('/CURRENTUSER', "/MODPACK=`"$ModPack`"", "/GAMEDIR=`"$GameDir`"") -PassThru
$w = FindWindow $title
Shot $w 'installer-1-welcome'
Click (FindButton $w 'Avan')
Shot $w 'installer-2-package'
Click (FindButton $w 'Avan')
Shot $w 'installer-3-game-folder'
Click (FindButton $w 'Avan')
Shot $w 'installer-4-ready'
Click (FindButton $w 'Instalar')
for ($i = 0; $i -lt 2400 -and -not (HasText $w 'Aplicando a dublagem'); $i++) { Start-Sleep -Milliseconds 100 }
Shot $w 'installer-5-applying'
$finish = FindButton $w 'Concluir'
Shot $w 'installer-6-finished'
Click $finish
[void]$proc.WaitForExit(60000)

# Uninstall, as Windows starts it from the list of installed apps.
$entry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{4F7C2B91-6A3E-4D58-B1E0-9C2A7D5E8F13}_is1'
$uninstaller = (Get-ItemProperty -LiteralPath $entry).UninstallString.Trim('"')
Start-Process -FilePath $uninstaller | Out-Null
$ask = FindWindow 'Desinstalar'
Shot $ask 'uninstall-1-confirm'
Click (FindButton $ask 'Sim')
for ($i = 0; $i -lt 1200; $i++) {
    $done = $null
    foreach ($x in $UIA::RootElement.FindAll($Tree::Children, [Windows.Automation.Condition]::TrueCondition)) {
        if ($x.Current.Name -like '*Desinstalar*' -and (HasText $x 'foi removida')) { $done = $x }
    }
    if ($done) { break }
    Start-Sleep -Milliseconds 250
}
if (-not $done) { throw 'The end message of the uninstaller did not show' }
Shot $done 'uninstall-2-done'
Click (FindButton $done 'OK')
Write-Host 'All screens saved'
