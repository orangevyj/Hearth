; Inno Setup 6 script for Hearth. Build it on Windows (or under wine):
;   powershell -ExecutionPolicy Bypass -File packaging\windows\build-inno.ps1
;
; The installer copies the app and then runs scripts\install-windows.ps1, which
; installs Python (winget or python.org) and creates the venv. Nothing is written
; outside %LOCALAPPDATA% and the user's Start menu.

#ifndef Version
  #define Version "0.2.0"
#endif
#ifndef SourceRoot
  #define SourceRoot "..\.."
#endif

[Setup]
AppId={{7A2F1C64-6F2B-4C8E-9B7A-6C0D2E9F4A11}
AppName=Hearth
AppVersion={#Version}
AppVerName=Hearth {#Version}
AppPublisher=Hearth
AppComment=Private, local-first AI workspace
DefaultDirName={localappdata}\Programs\Hearth
DefaultGroupName=Hearth
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#SourceRoot}\dist
OutputBaseFilename=hearth-{#Version}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\hearth.cmd
MinVersion=10.0

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#SourceRoot}\*"; DestDir: "{app}"; \
  Excludes: ".venv,.git,.tools,__pycache__,*.pyc,build,dist,*.egg-info"; \
  Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Hearth"; Filename: "{app}\hearth.cmd"; WorkingDir: "{app}"
Name: "{group}\Uninstall Hearth"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Hearth"; Filename: "{app}\hearth.cmd"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
; First the dependency bootstrap, then Hearth itself.
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\install-windows.ps1"""; \
  StatusMsg: "Installing Python and Hearth's dependencies (a few minutes)…"; \
  Flags: waituntilterminated runhidden
Filename: "{app}\hearth.cmd"; Description: "Start Hearth now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\.venv"
Type: files; Name: "{app}\hearth.cmd"
