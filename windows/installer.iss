[Setup]
AppId={{C6287A14-992F-4A47-A103-8B3914872BD3}
AppName=رصد الشهري
AppVersion=1.0.0
AppPublisher=Tadween
AppPublisherURL=https://github.com/darshstudio/rasd-months
DefaultDirName={autopf}\Tadween\RasdMonths
DefaultGroupName=رصد الشهري
OutputDir=..\build\windows\installer
OutputBaseFilename=rasd-months-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "staging\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\رصد الشهري"; Filename: "{app}\rasd_months.exe"
Name: "{autodesktop}\رصد الشهري"; Filename: "{app}\rasd_months.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\rasd_months.exe"; Description: "{cm:LaunchProgram,رصد الشهري}"; Flags: nowait postinstall skipifsilent
