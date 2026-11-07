; Inno Setup script of the Windows installer of the PT-BR dub of Red Dead Redemption (PC).
; One wizard does everything: finds the dub package downloaded from Nexus Mods (zip or folder) and the
; game, downloads the official HDiffPatch, keeps the original audio file in PTBR-backup, applies the
; patch and checks every file by its SHA-256. Uninstalling from Windows puts the original back.
; No PowerShell and no script: nothing for the execution policy to block.
;
; Build with scripts\build.ps1, which passes the version.

#if VER < EncodeVer(6, 7, 0)
  #error Inno Setup 6.7 or newer is required (ExtractArchive of zip files, ExecAndCaptureOutput)
#endif

#define AppName "Dublagem PT-BR do Red Dead Redemption"
#define AppPublisher "Scarlet Modder"
#define AppURL "https://github.com/scarletmodder/rdr1-ptbr-instalador"
#define NexusURL "https://www.nexusmods.com/reddeadredemption/mods/855"
; Identifies the installation across upgrades: never change it.
#define AppGuid "4F7C2B91-6A3E-4D58-B1E0-9C2A7D5E8F13"
#define AudioRel "game\audio_d11generic.rpf"
#define BackupDirName "PTBR-backup"
; HDiffPatch: the newest release is looked up on GitHub; this one is the fallback and the tested one.
#define HdpApi "https://api.github.com/repos/sisong/HDiffPatch/releases/latest"
#define HdpTestedTag "v5.1.3"
#define HdpTestedUrl "https://github.com/sisong/HDiffPatch/releases/download/v5.1.3/hdiffpatch_v5.1.3_bin_windows64.zip"
#define HdpTestedZipSha "77f141386e5d8f785c1c846e10fbbc19b6c05aa00e3f59cc44670fb3f0e2ae94"

#ifndef AppVersion
  #error AppVersion is missing: run scripts\build.ps1
#endif

[Setup]
AppId={{{#AppGuid}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
VersionInfoVersion={#AppVersion}.0
VersionInfoCompany={#AppPublisher}
VersionInfoCopyright={#AppPublisher}, MIT license
VersionInfoDescription={#AppName}
; The game usually sits in Program Files: the installer asks for administrator once, at the start.
; The tests run it per user with /CURRENTUSER on a game folder they own.
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
DefaultDirName={autopf}\Scarlet Modder\RDR1-PTBR
DisableWelcomePage=no
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyMemo=no
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\scarlet.ico
SetupIconFile=scarlet.ico
WizardStyle=modern dynamic windows11
WizardSizePercent=115
OutputDir=..\dist
OutputBaseFilename=Instalador-Dublagem-PTBR-RDR1-v{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
ArchiveExtraction=full
; Fixed date on the installed files: the build time is not recorded.
TimeStampsInUTC=yes
TouchDate=2026-01-01
TouchTime=00:00

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
WelcomeLabel1=Dublagem PT-BR do Red Dead Redemption
WelcomeLabel2=Coloca a dublagem em português do Brasil no Red Dead Redemption de PC.%n%nAntes de continuar, feche o jogo e baixe a dublagem no Nexus Mods (link abaixo). Não precisa extrair o .zip.%n%nO instalador acha o jogo, baixa o HDiffPatch oficial e guarda o arquivo original. Para voltar ao inglês, desinstale pelo Windows.%n%nMod de fã, sem vínculo com a Rockstar Games.
ClickNext=Clique em Avançar para continuar.
ReadyLabel1=Tudo pronto para aplicar a dublagem.
ReadyLabel2a=Clique em Instalar. A aplicação leva de 1 a 5 minutos, conforme o disco.
ReadyLabel2b=Clique em Instalar. A aplicação leva de 1 a 5 minutos, conforme o disco.
PreparingDesc=Aplicando a dublagem no jogo. Não feche esta janela.
FinishedHeadingLabel=Dublagem instalada
FinishedLabelNoIcons=A dublagem foi aplicada. Pode abrir o jogo.%n%nPara voltar ao inglês: Configurações do Windows > Aplicativos > Aplicativos instalados > [name] > Desinstalar.
FinishedLabel=A dublagem foi aplicada. Pode abrir o jogo.%n%nPara voltar ao inglês: Configurações do Windows > Aplicativos > Aplicativos instalados > [name] > Desinstalar.
ConfirmUninstall=Remover a %1? O áudio original em inglês volta para o jogo.
UninstallStatusLabel=Devolvendo o áudio original do jogo. Aguarde.
UninstalledAll=A dublagem foi removida e o áudio original em inglês voltou.
StatusUninstalling=Removendo a %1...

[CustomMessages]
PackPageTitle=Arquivos da dublagem
PackPageSubtitle=Onde está a dublagem que você baixou do Nexus Mods?
PackPageText=Escolha o arquivo .zip baixado do Nexus (não precisa extrair) ou a pasta extraída, que tem a pasta "dados". O instalador já procurou em Downloads, na Área de Trabalho e em Documentos.
PackPageLabel=Arquivo .zip ou pasta da dublagem:
PackPickZip=Escolher .zip...
PackPickFolder=Escolher pasta...
PackPickZipFilter=Arquivo da dublagem (*.zip)|*.zip
PackPickFolderText=Escolha a pasta extraída da dublagem (a que tem a pasta "dados")
PackFound=Encontrada: dublagem v%1.
PackFoundZip=Encontrado um .zip da dublagem. A versão é conferida na instalação.
PackNotFound=Não achei a dublagem sozinho. Use um dos botões acima para escolher o .zip ou a pasta.
PackInvalid=Não reconheci a dublagem em:%n%n%1%n%nEscolha o .zip baixado do Nexus Mods ou a pasta extraída que tem a pasta "dados".
GamePageTitle=Pasta do jogo
GamePageSubtitle=Onde está o Red Dead Redemption?
GamePageText=O instalador procurou na Steam, na Epic e no Rockstar Games Launcher. Confira a pasta: é a que tem o RDR.exe. Na Steam: botão direito no jogo > Gerenciar > Ver arquivos locais.
GamePageLabel=Pasta do jogo:
GameInvalid=Não encontrei o arquivo de áudio do jogo (game\audio_d11generic.rpf) nesta pasta:%n%n%1%n%nEscolha a pasta que tem o RDR.exe.
GameXbox=O Windows não deixa alterar os arquivos da versão do Xbox (Microsoft Store). A dublagem funciona nas versões Steam, Epic e Rockstar.
ReadyPack=Dublagem:
ReadyGame=Pasta do jogo:
StepCheckGame=Conferindo se o jogo está fechado...
StepDownload=Baixando o HDiffPatch oficial (programa de código aberto que aplica o patch)...
StepExtractTool=Preparando o HDiffPatch...
StepExtractPack=Abrindo o .zip da dublagem (cerca de 400 MB)...
StepHashGame=Conferindo o arquivo de áudio do jogo (até 1 minuto)...
StepBackup=Guardando o arquivo original em PTBR-backup...
StepPatch=Aplicando a dublagem (de 1 a 4 minutos)...
StepHashResult=Conferindo o resultado...
StepDone=Pronto.
ErrGameOpen=O jogo está aberto. Feche o Red Dead Redemption e clique em Instalar de novo.
ErrDownload=Não consegui baixar o HDiffPatch do GitHub:%n%1%n%nConfira a internet e tente de novo. Sem internet, baixe em outro aparelho o arquivo hdiffpatch_v5.1.3_bin_windows64.zip (página do HDiffPatch no GitHub) e deixe na pasta Downloads. Nada foi alterado no jogo.
ErrTool=O HDiffPatch baixado não tem o hpatchz.exe esperado. Tente de novo; nada foi alterado no jogo.
ErrPackOpen=Não consegui abrir a dublagem:%n%1%n%nBaixe o .zip de novo no Nexus Mods. Nada foi alterado no jogo.
ErrPackMissing=Faltam arquivos na dublagem (dados\versao.json ou o patch). Baixe o .zip de novo no Nexus Mods. Nada foi alterado no jogo.
ErrSpace=Falta espaço no disco do jogo: precisa de %1 GB livres. Nada foi alterado no jogo.
ErrBackupOther=Já existe uma pasta PTBR-backup no jogo com um arquivo que não é o original. Nada foi alterado. Apague essa pasta só se tiver certeza e tente de novo.
ErrGameOther=O arquivo de áudio do seu jogo é diferente do esperado (outra versão do jogo ou outro mod de áudio). Nada foi alterado.%n%nVerifique os arquivos do jogo pela loja (Steam: Propriedades > Arquivos instalados > Verificar integridade) e tente de novo. Se o jogo atualizou, aguarde uma versão nova da dublagem.
ErrNoWrite=Não consegui mexer no arquivo de áudio do jogo:%n%1%n%nFeche o jogo e o launcher e tente de novo. Nada foi alterado.
ErrPatch=O patch falhou (código %1). O jogo ficou com o áudio original.
ErrResult=O arquivo gerado não confere com a dublagem. O jogo ficou com o áudio original. Tente de novo; se repetir, avise na página do mod.
AlreadyInstalled=A dublagem v%1 já estava instalada neste jogo.
UninstallNoBackup=Não achei o original guardado em PTBR-backup:%n%1%n%nPara voltar ao inglês, use a verificação de arquivos da loja (Steam: Propriedades > Arquivos instalados > Verificar integridade; Epic: Gerenciar > Verificar; Rockstar: Configurações > o jogo > Verificar integridade).
UninstallBackupOther=O arquivo em PTBR-backup não é o original do jogo, então não foi usado:%n%1%n%nPara voltar ao inglês, use a verificação de arquivos da loja.
UninstallGameOpen=O jogo está aberto. Feche o Red Dead Redemption e desinstale de novo.
UninstallRestoreFailed=Não consegui devolver o original:%n%1%n%nFeche o jogo e o launcher e desinstale de novo. Nada foi removido.
NexusLink=Baixar a dublagem no Nexus Mods
ShortcutUninstall=Remover a dublagem (voltar ao inglês)
ShortcutGuide=Guia de instalação

[Files]
Source: "scarlet.ico"; DestDir: "{app}"; Flags: ignoreversion touch
Source: "..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion touch

[UninstallDelete]
Type: files; Name: "{app}\dublagem.ini"

[Icons]
Name: "{autoprograms}\{#AppName}\{cm:ShortcutUninstall}"; Filename: "{uninstallexe}"; IconFilename: "{app}\scarlet.ico"
Name: "{autoprograms}\{#AppName}\{cm:ShortcutGuide}"; Filename: "{#AppURL}/blob/main/docs/installation.md"

[Code]
const
  StateFile = 'dublagem.ini';

var
  PackPage: TWizardPage;
  PackEdit: TNewEdit;
  PackStatus: TNewStaticText;
  GamePage: TInputDirWizardPage;
  Progress: TOutputProgressWizardPage;
  PackVersion, OriginalSha: String;

{ ------------------------------------------------------------------ small helpers }

function ReadText(const FileName: String): String;
var
  Raw: AnsiString;
begin
  Result := '';
  if LoadStringFromFile(FileName, Raw) then
    Result := String(Raw);
end;

{ Value of "key": "value" or "key": number in a flat JSON text, with \\ and \/ unescaped. }
function JsonValue(const Text, Key: String): String;
var
  P, I: Integer;
  Rest: String;
begin
  Result := '';
  P := Pos('"' + Key + '"', Text);
  if P = 0 then
    Exit;
  Rest := Copy(Text, P + Length(Key) + 2, MaxInt);
  P := Pos(':', Rest);
  if P = 0 then
    Exit;
  Rest := TrimLeft(Copy(Rest, P + 1, MaxInt));
  if Copy(Rest, 1, 1) = '"' then
  begin
    I := 2;
    while (I <= Length(Rest)) and (Rest[I] <> '"') do
    begin
      if Rest[I] = '\' then
        I := I + 1;
      I := I + 1;
    end;
    Result := Copy(Rest, 2, I - 2);
    StringChangeEx(Result, '\\', #1, True);
    StringChangeEx(Result, '\/', '/', True);
    StringChangeEx(Result, #1, '\', True);
  end
  else
  begin
    I := 1;
    while (I <= Length(Rest)) and (Pos(Rest[I], '0123456789.') > 0) do
      I := I + 1;
    Result := Copy(Rest, 1, I - 1);
  end;
end;

function NormalizeDir(Dir: String): String;
begin
  Dir := Trim(Dir);
  StringChangeEx(Dir, '"', '', True);
  StringChangeEx(Dir, '/', '\', True);
  Dir := RemoveBackslashUnlessRoot(Dir);
  if CompareText(ExtractFileName(Dir), 'game') = 0 then
    Dir := ExtractFileDir(Dir);
  Result := Dir;
end;

function HasGame(const Dir: String): Boolean;
begin
  Result := (Dir <> '') and FileExists(AddBackslash(Dir) + '{#AudioRel}');
end;

function IsXbox(const Dir: String): Boolean;
begin
  Result := (Pos('\WINDOWSAPPS\', Uppercase(AddBackslash(Dir))) > 0) or (Pos('\XBOXGAMES\', Uppercase(AddBackslash(Dir))) > 0);
end;

function DownloadsDir(): String;
begin
  if not RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders',
    '{374DE290-123F-4565-9164-39C4925E467B}', Result) then
    Result := ExpandConstant('{%USERPROFILE}\Downloads');
end;

function GameRunning(): Boolean;
var
  Wmi, Service, Found: Variant;
begin
  Result := False;
  try
    Wmi := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Wmi.ConnectServer('.', 'root\CIMV2');
    Found := Service.ExecQuery('SELECT ProcessId FROM Win32_Process WHERE Name = ''RDR.exe'' OR Name = ''PlayRDR.exe''');
    Result := Found.Count > 0;
  except
    Log('Could not ask Windows for the running processes: ' + GetExceptionMessage);
  end;
end;

{ SHA-256 by certutil, which runs in its own process and keeps the window responsive on a 4 GB file. }
function FileSha256(const FileName: String): String;
var
  Output: TExecOutput;
  Code, I, J: Integer;
  Line: String;
  IsHex: Boolean;
begin
  Result := '';
  if ExecAndCaptureOutput(ExpandConstant('{sys}\certutil.exe'), '-hashfile "' + FileName + '" SHA256', '',
    SW_HIDE, ewWaitUntilTerminated, Code, Output) and (Code = 0) then
    for I := 0 to GetArrayLength(Output.StdOut) - 1 do
    begin
      Line := Output.StdOut[I];
      StringChangeEx(Line, ' ', '', True);
      if Length(Line) = 64 then
      begin
        IsHex := True;
        for J := 1 to 64 do
          if Pos(Lowercase(Line[J]), '0123456789abcdef') = 0 then
            IsHex := False;
        if IsHex then
        begin
          Result := Uppercase(Line);
          Exit;
        end;
      end;
    end;
  Log('certutil did not give the hash, falling back to GetSHA256OfFile');
  Result := Uppercase(GetSHA256OfFile(FileName));
end;

function FileSize64(const FileName: String): Int64;
var
  Rec: TFindRec;
begin
  Result := -1;
  if FindFirst(FileName, Rec) then
  begin
    Result := Int64(Rec.SizeHigh) * 4294967296 + Rec.SizeLow;
    FindClose(Rec);
  end;
end;

{ ------------------------------------------------------------------ the dub package }

{ The folder with versao.json: the extracted package, its "dados" folder or one level inside. }
function PackDataDir(const Dir: String): String;
var
  Rec: TFindRec;
begin
  Result := '';
  if FileExists(AddBackslash(Dir) + 'dados\versao.json') then
    Result := AddBackslash(Dir) + 'dados'
  else if FileExists(AddBackslash(Dir) + 'versao.json') and (CompareText(ExtractFileName(RemoveBackslash(Dir)), 'dados') = 0) then
    Result := RemoveBackslash(Dir)
  else if FindFirst(AddBackslash(Dir) + '*', Rec) then
  begin
    try
      repeat
        if (Rec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and (Rec.Name <> '.') and (Rec.Name <> '..') and
           FileExists(AddBackslash(Dir) + Rec.Name + '\dados\versao.json') then
        begin
          Result := AddBackslash(Dir) + Rec.Name + '\dados';
          Exit;
        end;
      until not FindNext(Rec);
    finally
      FindClose(Rec);
    end;
  end;
end;

function IsPackZipName(const Name: String): Boolean;
var
  U: String;
begin
  U := Uppercase(Name);
  Result := (CompareText(ExtractFileExt(Name), '.zip') = 0) and
    ((Pos('RDR1-PTBR', U) = 1) or (Pos('SCARLET DUB', U) = 1) or (Pos('SCARLET-DUB', U) = 1) or (Pos('-855-', U) > 0));
end;

{ Newest candidate in a folder: an extracted package (folder) or a zip from Nexus. }
procedure ScanForPack(const Dir: String; var Best: String; var BestTime: Int64; Depth: Integer);
var
  Rec: TFindRec;
  Stamp: Int64;
  Path: String;
begin
  if (Dir = '') or not DirExists(Dir) then
    Exit;
  if FindFirst(AddBackslash(Dir) + '*', Rec) then
  try
    repeat
      if (Rec.Name = '.') or (Rec.Name = '..') then
        Continue;
      Path := AddBackslash(Dir) + Rec.Name;
      Stamp := Int64(Rec.LastWriteTime.dwHighDateTime) * 4294967296 + Rec.LastWriteTime.dwLowDateTime;
      if Rec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
      begin
        if FileExists(Path + '\dados\versao.json') and FileExists(Path + '\dados\' + JsonValue(ReadText(Path + '\dados\versao.json'), 'patch')) then
        begin
          if Stamp > BestTime then
          begin
            Best := Path;
            BestTime := Stamp;
          end;
        end
        else if Depth > 0 then
          ScanForPack(Path, Best, BestTime, Depth - 1);
      end
      else if IsPackZipName(Rec.Name) and (Stamp > BestTime) then
      begin
        Best := Path;
        BestTime := Stamp;
      end;
    until not FindNext(Rec);
  finally
    FindClose(Rec);
  end;
end;

function DetectPack(): String;
var
  Time: Int64;
begin
  Result := '';
  Time := 0;
  ScanForPack(ExpandConstant('{src}'), Result, Time, 2);
  ScanForPack(DownloadsDir(), Result, Time, 2);
  ScanForPack(ExpandConstant('{userdesktop}'), Result, Time, 2);
  ScanForPack(ExpandConstant('{userdocs}'), Result, Time, 1);
end;

procedure ShowPackStatus();
var
  Data, Path: String;
begin
  Path := Trim(PackEdit.Text);
  PackVersion := '';
  if Path = '' then
    PackStatus.Caption := CustomMessage('PackNotFound')
  else if DirExists(Path) then
  begin
    Data := PackDataDir(Path);
    if Data <> '' then
    begin
      PackVersion := JsonValue(ReadText(Data + '\versao.json'), 'versao_mod');
      PackStatus.Caption := FmtMessage(CustomMessage('PackFound'), [PackVersion]);
    end
    else
      PackStatus.Caption := FmtMessage(CustomMessage('PackInvalid'), [Path]);
  end
  else if FileExists(Path) and (CompareText(ExtractFileExt(Path), '.zip') = 0) then
    PackStatus.Caption := CustomMessage('PackFoundZip')
  else
    PackStatus.Caption := FmtMessage(CustomMessage('PackInvalid'), [Path]);
end;

function PackLooksValid(const Path: String): Boolean;
begin
  if DirExists(Path) then
    Result := PackDataDir(Path) <> ''
  else
    Result := FileExists(Path) and (CompareText(ExtractFileExt(Path), '.zip') = 0);
end;

procedure PickZipClick(Sender: TObject);
var
  FileName: String;
begin
  FileName := '';
  if GetOpenFileName('', FileName, DownloadsDir(), CustomMessage('PackPickZipFilter'), 'zip') then
  begin
    PackEdit.Text := FileName;
    ShowPackStatus();
  end;
end;

procedure PickFolderClick(Sender: TObject);
var
  Dir: String;
begin
  Dir := DownloadsDir();
  if BrowseForFolder(CustomMessage('PackPickFolderText'), Dir, False) then
  begin
    PackEdit.Text := Dir;
    ShowPackStatus();
  end;
end;

{ ------------------------------------------------------------------ the game }

procedure Consider(Dir: String; var Best: String);
begin
  Dir := NormalizeDir(Dir);
  if (Best = '') and HasGame(Dir) and not IsXbox(Dir) then
    Best := Dir;
end;

procedure ConsiderSteam(var Best: String);
var
  Root, Library, Text, InstallDir: String;
  Start: Integer;
begin
  if not RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', Root) then
    if not RegQueryStringValue(HKLM32, 'SOFTWARE\Valve\Steam', 'InstallPath', Root) then
      Root := ExpandConstant('{commonpf32}\Steam');
  StringChangeEx(Root, '/', '\', True);
  Text := ReadText(AddBackslash(Root) + 'steamapps\libraryfolders.vdf');
  Library := Root;
  Start := 1;
  while Library <> '' do
  begin
    InstallDir := JsonValue(ReadText(AddBackslash(Library) + 'steamapps\appmanifest_2668510.acf'), 'installdir');
    if InstallDir = '' then
      InstallDir := 'Red Dead Redemption';
    Consider(AddBackslash(Library) + 'steamapps\common\' + InstallDir, Best);
    { libraryfolders.vdf: "path"		"D:\\SteamLibrary" }
    Start := Pos('"path"', Text);
    if Start = 0 then
      Library := ''
    else
    begin
      Delete(Text, 1, Start + 5);
      Delete(Text, 1, Pos('"', Text));
      Library := Copy(Text, 1, Pos('"', Text) - 1);
      Delete(Text, 1, Length(Library) + 1);
      StringChangeEx(Library, '\\', '\', True);
    end;
  end;
end;

procedure ConsiderEpic(var Best: String);
var
  Dir: String;
  Rec: TFindRec;
begin
  Dir := ExpandConstant('{commonappdata}\Epic\EpicGamesLauncher\Data\Manifests');
  if FindFirst(Dir + '\*.item', Rec) then
  try
    repeat
      Consider(JsonValue(ReadText(Dir + '\' + Rec.Name), 'InstallLocation'), Best);
    until not FindNext(Rec);
  finally
    FindClose(Rec);
  end;
end;

procedure ConsiderUninstallKeys(const RootKey: Integer; var Best: String);
var
  Names: TArrayOfString;
  I: Integer;
  Name, Dir, Key: String;
begin
  Key := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  if not RegGetSubkeyNames(RootKey, Key, Names) then
    Exit;
  for I := 0 to GetArrayLength(Names) - 1 do
    if RegQueryStringValue(RootKey, Key + '\' + Names[I], 'DisplayName', Name) and
       (Pos('RED DEAD REDEMPTION', Uppercase(Name)) > 0) and (Pos('REDEMPTION 2', Uppercase(Name)) = 0) and
       RegQueryStringValue(RootKey, Key + '\' + Names[I], 'InstallLocation', Dir) then
      Consider(Dir, Best);
end;

function DetectGameDir(): String;
var
  Names: TArrayOfString;
  I, Letter: Integer;
  Dir, Drive: String;
begin
  Result := '';
  ConsiderSteam(Result);
  ConsiderEpic(Result);
  if RegGetSubkeyNames(HKLM32, 'SOFTWARE\Rockstar Games', Names) then
    for I := 0 to GetArrayLength(Names) - 1 do
      if RegQueryStringValue(HKLM32, 'SOFTWARE\Rockstar Games\' + Names[I], 'InstallFolder', Dir) then
        Consider(Dir, Result);
  ConsiderUninstallKeys(HKLM64, Result);
  ConsiderUninstallKeys(HKLM32, Result);
  ConsiderUninstallKeys(HKCU, Result);
  for Letter := Ord('C') to Ord('Z') do
  begin
    Drive := Chr(Letter) + ':\';
    if DirExists(Drive) then
    begin
      Consider(Drive + 'Program Files\Rockstar Games\Red Dead Redemption', Result);
      Consider(Drive + 'Rockstar Games\Red Dead Redemption', Result);
      Consider(Drive + 'Program Files\Epic Games\RedDeadRedemption', Result);
      Consider(Drive + 'Epic Games\RedDeadRedemption', Result);
      Consider(Drive + 'SteamLibrary\steamapps\common\Red Dead Redemption', Result);
      Consider(Drive + 'Steam\steamapps\common\Red Dead Redemption', Result);
    end;
  end;
end;

{ ------------------------------------------------------------------ wizard pages }

procedure NexusClick(Sender: TObject);
var
  Code: Integer;
begin
  ShellExec('open', '{#NexusURL}', '', '', SW_SHOWNORMAL, ewNoWait, Code);
end;

{ A clickable line that opens the mod page on Nexus Mods in the browser. }
function NexusLink(Parent: TWinControl; Top: Integer): TNewStaticText;
begin
  Result := TNewStaticText.Create(WizardForm);
  Result.Parent := Parent;
  Result.Top := Top;
  Result.Caption := CustomMessage('NexusLink');
  Result.Cursor := crHand;
  Result.Font.Style := [fsUnderline];
  Result.Font.Color := clHotLight;
  Result.OnClick := @NexusClick;
end;

procedure InitializeWizard();
var
  Intro: TNewStaticText;
  ZipButton, FolderButton: TNewButton;
begin
  { Welcome page: the text, then the link to the mod page right below it. }
  WizardForm.WelcomeLabel2.AdjustHeight();
  NexusLink(WizardForm.WelcomeLabel2.Parent, WizardForm.WelcomeLabel2.Top + WizardForm.WelcomeLabel2.Height + ScaleY(12)).Left := WizardForm.WelcomeLabel2.Left;

  PackPage := CreateCustomPage(wpWelcome, CustomMessage('PackPageTitle'), CustomMessage('PackPageSubtitle'));
  Intro := TNewStaticText.Create(PackPage);
  Intro.Parent := PackPage.Surface;
  Intro.AutoSize := False;
  Intro.WordWrap := True;
  Intro.Width := PackPage.SurfaceWidth;
  Intro.Caption := CustomMessage('PackPageText') + #13#10#13#10 + CustomMessage('PackPageLabel');
  Intro.AdjustHeight();

  PackEdit := TNewEdit.Create(PackPage);
  PackEdit.Parent := PackPage.Surface;
  PackEdit.Top := Intro.Top + Intro.Height + ScaleY(8);
  PackEdit.Width := PackPage.SurfaceWidth;

  ZipButton := TNewButton.Create(PackPage);
  ZipButton.Parent := PackPage.Surface;
  ZipButton.Caption := CustomMessage('PackPickZip');
  ZipButton.Top := PackEdit.Top + PackEdit.Height + ScaleY(8);
  ZipButton.Width := ScaleX(130);
  ZipButton.Height := WizardForm.NextButton.Height;
  ZipButton.OnClick := @PickZipClick;

  FolderButton := TNewButton.Create(PackPage);
  FolderButton.Parent := PackPage.Surface;
  FolderButton.Caption := CustomMessage('PackPickFolder');
  FolderButton.Top := ZipButton.Top;
  FolderButton.Left := ZipButton.Left + ZipButton.Width + ScaleX(8);
  FolderButton.Width := ScaleX(130);
  FolderButton.Height := WizardForm.NextButton.Height;
  FolderButton.OnClick := @PickFolderClick;

  PackStatus := TNewStaticText.Create(PackPage);
  PackStatus.Parent := PackPage.Surface;
  PackStatus.AutoSize := False;
  PackStatus.WordWrap := True;
  PackStatus.Top := ZipButton.Top + ZipButton.Height + ScaleY(12);
  PackStatus.Width := PackPage.SurfaceWidth;
  PackStatus.Height := ScaleY(48);
  NexusLink(PackPage.Surface, PackStatus.Top + PackStatus.Height + ScaleY(8));

  PackEdit.Text := ExpandConstant('{param:MODPACK|}');
  if PackEdit.Text = '' then
    PackEdit.Text := DetectPack();
  ShowPackStatus();

  GamePage := CreateInputDirPage(PackPage.ID, CustomMessage('GamePageTitle'), CustomMessage('GamePageSubtitle'),
    CustomMessage('GamePageText'), False, '');
  GamePage.Add(CustomMessage('GamePageLabel'));
  GamePage.Values[0] := ExpandConstant('{param:GAMEDIR|}');
  if GamePage.Values[0] = '' then
    GamePage.Values[0] := GetPreviousData('GameDir', '');
  if not HasGame(GamePage.Values[0]) and (ExpandConstant('{param:GAMEDIR|}') = '') then
    GamePage.Values[0] := DetectGameDir();

  Progress := CreateOutputProgressPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Dir: String;
begin
  Result := True;
  if WizardSilent() then
    Exit;
  if CurPageID = PackPage.ID then
  begin
    ShowPackStatus();
    if not PackLooksValid(Trim(PackEdit.Text)) then
    begin
      MsgBox(FmtMessage(CustomMessage('PackInvalid'), [Trim(PackEdit.Text)]), mbError, MB_OK);
      Result := False;
    end;
  end
  else if CurPageID = GamePage.ID then
  begin
    Dir := NormalizeDir(GamePage.Values[0]);
    GamePage.Values[0] := Dir;
    if IsXbox(Dir) then
    begin
      MsgBox(CustomMessage('GameXbox'), mbError, MB_OK);
      Result := False;
    end
    else if not HasGame(Dir) then
    begin
      MsgBox(FmtMessage(CustomMessage('GameInvalid'), [Dir]), mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  Result := CustomMessage('ReadyPack') + NewLine + Space + Trim(PackEdit.Text) + NewLine + NewLine +
    CustomMessage('ReadyGame') + NewLine + Space + NormalizeDir(GamePage.Values[0]);
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  SetPreviousData(PreviousDataKey, 'GameDir', NormalizeDir(GamePage.Values[0]));
end;

{ ------------------------------------------------------------------ applying the dub }

function OnDownload(const Url, FileName: String; const Done, Total: Int64): Boolean;
begin
  if Total > 0 then
    Progress.SetProgress(Integer(Done div 1024), Integer(Total div 1024));
  Result := True;
end;

function OnExtract(const ArchiveName, FileName: String; const Done, Total: Int64): Boolean;
begin
  if Total > 0 then
    Progress.SetProgress(Integer(Done div 1024), Integer(Total div 1024));
  Result := True;
end;

procedure Step(const Text: String);
begin
  Log(Text);
  Progress.SetText(Text, '');
  Progress.SetProgress(0, 0);
end;

{ Newest Windows build of HDiffPatch on GitHub. The tested release is also the fallback when GitHub does not answer. }
procedure PickHdiffpatch(var Url, Sha: String);
var
  Text, Tag, Asset: String;
  P: Integer;
begin
  Url := '{#HdpTestedUrl}';
  Sha := '{#HdpTestedZipSha}';
  { Test hook: a download address that fails, to exercise the fallback without internet. }
  if ExpandConstant('{param:HDIFFPATCHURL|}') <> '' then
  begin
    Url := ExpandConstant('{param:HDIFFPATCHURL|}');
    Sha := '';
    Exit;
  end;
  try
    DownloadTemporaryFile('{#HdpApi}', 'hdiffpatch-latest.json', '', nil);
    Text := ReadText(ExpandConstant('{tmp}\hdiffpatch-latest.json'));
    Tag := JsonValue(Text, 'tag_name');
    if (Tag <> '') and (Tag <> '{#HdpTestedTag}') then
    begin
      { Only an asset of the author's own repository, built for 64-bit Windows. }
      P := Pos('"browser_download_url"', Text);
      while P > 0 do
      begin
        Delete(Text, 1, P - 1);
        Asset := JsonValue(Text, 'browser_download_url');
        if (Pos('https://github.com/sisong/HDiffPatch/releases/download/', Asset) = 1) and
           (Copy(Asset, Length(Asset) - Length('_bin_windows64.zip') + 1, MaxInt) = '_bin_windows64.zip') then
        begin
          Url := Asset;
          Sha := '';
          Break;
        end;
        Delete(Text, 1, Length('"browser_download_url"'));
        P := Pos('"browser_download_url"', Text);
      end;
    end;
    Log('HDiffPatch on GitHub: ' + Tag + ', using ' + Url);
  except
    Log('GitHub did not answer the release lookup, using the tested release: ' + GetExceptionMessage);
  end;
end;

function FindFileBelow(const Dir, Name: String): String;
var
  Rec: TFindRec;
begin
  Result := '';
  if FileExists(AddBackslash(Dir) + Name) then
  begin
    Result := AddBackslash(Dir) + Name;
    Exit;
  end;
  if FindFirst(AddBackslash(Dir) + '*', Rec) then
  try
    repeat
      if (Rec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and (Rec.Name <> '.') and (Rec.Name <> '..') then
      begin
        Result := FindFileBelow(AddBackslash(Dir) + Rec.Name, Name);
        if Result <> '' then
          Exit;
      end;
    until not FindNext(Rec);
  finally
    FindClose(Rec);
  end;
end;

{ Returns '' when the dub is in place, or the reason it is not. The game is untouched unless the end result checks out. }
function ApplyDub(): String;
var
  Pack, Data, Json, Url, Sha, ToolZip, Hpatchz, PatchFile, Game, Target, BackupDir, Backup, NewFile, State: String;
  OrigSize, DubSize, Free, Total: Int64;
  Code: Integer;
  MovedNow: Boolean;
begin
  Result := '';
  Pack := Trim(PackEdit.Text);
  Game := NormalizeDir(GamePage.Values[0]);
  Target := Game + '\{#AudioRel}';
  BackupDir := Game + '\{#BackupDirName}';
  Backup := BackupDir + '\audio_d11generic.rpf';
  NewFile := Target + '.ptbr-novo';

  Step(CustomMessage('StepCheckGame'));
  if GameRunning() then
  begin
    Result := CustomMessage('ErrGameOpen');
    Exit;
  end;
  if IsXbox(Game) then
  begin
    Result := CustomMessage('GameXbox');
    Exit;
  end;
  if not HasGame(Game) then
  begin
    Result := FmtMessage(CustomMessage('GameInvalid'), [Game]);
    Exit;
  end;

  { The package: an extracted folder, or the zip opened in the temporary folder. }
  if DirExists(Pack) then
    Data := PackDataDir(Pack)
  else
  begin
    Step(CustomMessage('StepExtractPack'));
    try
      ExtractArchive(Pack, ExpandConstant('{tmp}\pack'), '', True, @OnExtract);
    except
      Result := FmtMessage(CustomMessage('ErrPackOpen'), [GetExceptionMessage]);
      Exit;
    end;
    Data := ExtractFileDir(FindFileBelow(ExpandConstant('{tmp}\pack'), 'versao.json'));
  end;
  Json := ReadText(Data + '\versao.json');
  PatchFile := Data + '\' + JsonValue(Json, 'patch');
  PackVersion := JsonValue(Json, 'versao_mod');
  if (Data = '') or (JsonValue(Json, 'patch') = '') or not FileExists(PatchFile) then
  begin
    Result := CustomMessage('ErrPackMissing');
    Exit;
  end;
  OriginalSha := Uppercase(JsonValue(Json, 'original_sha256'));
  OrigSize := StrToInt64Def(JsonValue(Json, 'original_tamanho'), -1);
  DubSize := StrToInt64Def(JsonValue(Json, 'dublado_tamanho'), -1);

  { Where the game stands now. }
  Step(CustomMessage('StepHashGame'));
  State := 'other';
  if FileSize64(Target) = DubSize then
    if FileSha256(Target) = Uppercase(JsonValue(Json, 'dublado_sha256')) then
      State := 'dubbed';
  if (State = 'other') and (FileSize64(Target) = OrigSize) then
    if FileSha256(Target) = Uppercase(JsonValue(Json, 'original_sha256')) then
      State := 'original';
  if State = 'dubbed' then
  begin
    Log(FmtMessage(CustomMessage('AlreadyInstalled'), [PackVersion]));
    Exit;
  end;
  if FileExists(Backup) then
  begin
    if (FileSize64(Backup) <> OrigSize) or (FileSha256(Backup) <> Uppercase(JsonValue(Json, 'original_sha256'))) then
    begin
      Result := CustomMessage('ErrBackupOther');
      Exit;
    end;
  end
  else if State <> 'original' then
  begin
    Result := CustomMessage('ErrGameOther');
    Exit;
  end;

  if GetSpaceOnDisk64(Game, Free, Total) and (Free < DubSize + 314572800) then
  begin
    Result := FmtMessage(CustomMessage('ErrSpace'), [Format('%.1f', [(DubSize + 314572800) / 1073741824.0])]);
    Exit;
  end;

  { The program that applies the patch. }
  ToolZip := ExpandConstant('{param:HDIFFPATCHZIP|}');
  if ToolZip = '' then
  begin
    Step(CustomMessage('StepDownload'));
    PickHdiffpatch(Url, Sha);
    try
      DownloadTemporaryFile(Url, 'hdiffpatch.zip', Sha, @OnDownload);
      ToolZip := ExpandConstant('{tmp}\hdiffpatch.zip');
    except
      { Without internet: the tested release already in Downloads, if its fingerprint is the official one. }
      Log('Download failed: ' + GetExceptionMessage);
      ToolZip := DownloadsDir() + '\' + ExtractFileName('{#HdpTestedUrl}');
      if not FileExists(ToolZip) or (FileSha256(ToolZip) <> Uppercase('{#HdpTestedZipSha}')) then
      begin
        Result := FmtMessage(CustomMessage('ErrDownload'), [GetExceptionMessage]);
        Exit;
      end;
      Log('Using the HDiffPatch zip found in Downloads: ' + ToolZip);
    end;
  end;
  Step(CustomMessage('StepExtractTool'));
  try
    ExtractArchive(ToolZip, ExpandConstant('{tmp}\hdiffpatch'), '', True, @OnExtract);
  except
    Result := FmtMessage(CustomMessage('ErrDownload'), [GetExceptionMessage]);
    Exit;
  end;
  Hpatchz := ExpandConstant('{tmp}\hdiffpatch\windows64\hpatchz.exe');
  if not FileExists(Hpatchz) then
  begin
    Result := CustomMessage('ErrTool');
    Exit;
  end;

  { Original to PTBR-backup (same disk, so a rename), patch into a new file, check it, then swap. }
  MovedNow := False;
  if not FileExists(Backup) then
  begin
    Step(CustomMessage('StepBackup'));
    ForceDirectories(BackupDir);
    if not RenameFile(Target, Backup) then
    begin
      Result := FmtMessage(CustomMessage('ErrNoWrite'), [Target]);
      Exit;
    end;
    MovedNow := True;
  end;

  Step(CustomMessage('StepPatch'));
  DeleteFile(NewFile);
  if not Exec(Hpatchz, '-f "' + Backup + '" "' + PatchFile + '" "' + NewFile + '"', '', SW_HIDE, ewWaitUntilTerminated, Code) or (Code <> 0) then
    Result := FmtMessage(CustomMessage('ErrPatch'), [IntToStr(Code)])
  else
  begin
    Step(CustomMessage('StepHashResult'));
    if (FileSize64(NewFile) <> DubSize) or (FileSha256(NewFile) <> Uppercase(JsonValue(Json, 'dublado_sha256'))) then
      Result := CustomMessage('ErrResult')
    else
    begin
      DeleteFile(Target);
      if not RenameFile(NewFile, Target) then
        Result := FmtMessage(CustomMessage('ErrNoWrite'), [Target]);
    end;
  end;

  if Result <> '' then
  begin
    DeleteFile(NewFile);
    if not FileExists(Target) and MovedNow then
    begin
      RenameFile(Backup, Target);
      RemoveDir(BackupDir);
    end;
    Exit;
  end;
  Step(CustomMessage('StepDone'));
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Progress.Show;
  try
    Result := ApplyDub();
  finally
    Progress.Hide;
  end;
  if Result <> '' then
    Log('Not applied: ' + Result);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Ini: String;
begin
  if CurStep <> ssPostInstall then
    Exit;
  Ini := ExpandConstant('{app}\' + StateFile);
  SetIniString('jogo', 'pasta', NormalizeDir(GamePage.Values[0]), Ini);
  SetIniString('jogo', 'versao_dublagem', PackVersion, Ini);
  SetIniString('jogo', 'original_sha256', OriginalSha, Ini);
end;

{ ------------------------------------------------------------------ uninstall: the original goes back }

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Game, Target, BackupDir, Backup, Expected, Aside: String;
begin
  if CurUninstallStep <> usUninstall then
    Exit;
  Game := GetIniString('jogo', 'pasta', '', ExpandConstant('{app}\' + StateFile));
  Target := Game + '\{#AudioRel}';
  BackupDir := Game + '\{#BackupDirName}';
  Backup := BackupDir + '\audio_d11generic.rpf';
  { The hash of the original is the same for every version of the dub: it is the game's own file. }
  Expected := GetIniString('jogo', 'original_sha256', 'D25A21C3C6C1D8FACBD97DC4BEE1DCD8CE0537159578FAB0D6FC227683F0E8BB', ExpandConstant('{app}\' + StateFile));
  if (Game = '') or not FileExists(Backup) then
  begin
    SuppressibleMsgBox(FmtMessage(CustomMessage('UninstallNoBackup'), [BackupDir]), mbInformation, MB_OK, IDOK);
    Exit;
  end;
  if GameRunning() then
  begin
    SuppressibleMsgBox(CustomMessage('UninstallGameOpen'), mbError, MB_OK, IDOK);
    Abort;
  end;
  if FileSha256(Backup) <> Uppercase(Expected) then
  begin
    SuppressibleMsgBox(FmtMessage(CustomMessage('UninstallBackupOther'), [Backup]), mbError, MB_OK, IDOK);
    Exit;
  end;
  { The dubbed file steps aside first, so a failure never leaves the game without its audio. }
  Aside := Target + '.ptbr-velho';
  DeleteFile(Target + '.ptbr-novo');
  DeleteFile(Aside);
  if FileExists(Target) and not RenameFile(Target, Aside) then
  begin
    SuppressibleMsgBox(FmtMessage(CustomMessage('UninstallRestoreFailed'), [Target]), mbError, MB_OK, IDOK);
    Abort;
  end;
  if not RenameFile(Backup, Target) then
  begin
    RenameFile(Aside, Target);
    SuppressibleMsgBox(FmtMessage(CustomMessage('UninstallRestoreFailed'), [Target]), mbError, MB_OK, IDOK);
    Abort;
  end;
  DeleteFile(Aside);
  RemoveDir(BackupDir);
end;
