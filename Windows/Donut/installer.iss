#define MyAppName "Donut"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "Donut"
#define MyAppExeName "Donut.exe"

[Setup]
AppId={{D9E1E0D7-4D71-4C1D-8C51-2E1D5D2EEA91}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Donut file conversion utility
VersionInfoProductName={#MyAppName}
VersionInfoTextVersion={#MyAppVersion}
SetupIconFile=Donut.ico
WizardImageFile=DonutWizard.bmp
WizardSmallImageFile=DonutWizardSmall.bmp
DefaultDirName={autopf}\Donut
DefaultGroupName=Donut
DisableProgramGroupPage=yes
OutputDir=installer
OutputBaseFilename=Install Donut
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "publish\win-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Donut"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Donut"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Donut"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--uninstall"; Flags: runhidden waituntilterminated

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Donut"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue

[UninstallDelete]
; Remove the complete installed application folder, including files created by an update.
Type: filesandordirs; Name: "{app}"
; Donut currently stores no user data, but clean these locations if a future version does.
Type: filesandordirs; Name: "{userappdata}\Donut"
Type: filesandordirs; Name: "{localappdata}\Donut"
