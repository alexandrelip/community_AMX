[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [ValidateSet('Info','Activate','FitViewport','Capture','Key','ScanKey','Move','Click','Close')][string]$Action='Info',
    [string]$OutputPath,[string]$Keys,[int]$X,[int]$Y,
    [ValidateRange(1,127)][int]$ScanCode=1,
    [switch]$Control,[switch]$Shift,[switch]$Alt,[switch]$RightControl,[switch]$RightShift,[switch]$Extended,
    [switch]$DesktopCapture,[switch]$RightButton,
    [int]$ViewportWidth=1600,[int]$ViewportHeight=900
)
$ErrorActionPreference='Stop'
$state=Get-Content -LiteralPath (Join-Path $RunRoot 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne [IO.Path]::GetFullPath($RunRoot) -or
    $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$'){throw 'Window control requires an owned native run'}
$active=Get-Content -LiteralPath (Join-Path $RunRoot 'active.json') -Raw | ConvertFrom-Json -DateKind String
$process=Get-CimInstance Win32_Process -Filter "ProcessId=$($active.ProcessId)"
if(-not $process -or $process.ExecutablePath -ne $state.Executable -or
    $process.CommandLine -notmatch ('(?:^|\s)-w\s+"?'+[regex]::Escape($state.ProfileName)+'"?(?:\s|$)')){throw 'Window process/profile mismatch'}
if($Action -in @('Move','Click','ScanKey') -and -not($Action -eq 'ScanKey' -and $ScanCode -eq 1)) {
    $telemetry=Join-Path $state.Profile 'Logs/AMXDENIS-native.jsonl'
    if(-not(Test-Path -LiteralPath $telemetry -PathType Leaf) -or
        ([DateTime]::UtcNow-(Get-Item -LiteralPath $telemetry).LastWriteTimeUtc).TotalSeconds -gt 2) {
        throw 'Fresh cockpit telemetry required; mission may be paused. No input sent.'
    }
}
if($OutputPath -and -not [IO.Path]::GetFullPath($OutputPath).StartsWith($state.RunRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Capture must remain inside owned run'}
$reference=Join-Path $PSScriptRoot 'Reference/Window-M1.ps1'
if((Get-FileHash -LiteralPath $reference -Algorithm SHA256).Hash -ne '640A1D26B470BA83F7713421C59AA2039D0A3BFF435FF16AC7D8CBE576952AA2'){throw 'Frozen input/capture implementation changed'}
$source=[IO.File]::ReadAllText($reference).Replace('DCS\.AMXM1-','DCS\.AMXDENIS-').Replace('M1-display.log','AMXDENIS-native.jsonl')
if($RightButton){$source=$source.Replace('::mouse_event(2, 0, 0, 0','::mouse_event(8, 0, 0, 0').Replace('::mouse_event(4, 0, 0, 0','::mouse_event(16, 0, 0, 0')}
$arguments=@{RunFile=(Join-Path $RunRoot 'active.json');ProcessName='DCS';Action=$Action;OutputPath=$OutputPath;Keys=$Keys;X=$X;Y=$Y;
    ScanCode=$ScanCode;Control=$Control;Shift=$Shift;Alt=$Alt;RightControl=$RightControl;RightShift=$RightShift;Extended=$Extended;
    DesktopCapture=$DesktopCapture;ViewportWidth=$ViewportWidth;ViewportHeight=$ViewportHeight}
$record=[ordered]@{Action=$Action;RequestedUtc=[DateTime]::UtcNow.ToString('o');RightButton=[bool]$RightButton;Succeeded=$false;Error=$null}
try {& ([scriptblock]::Create($source)) @arguments;$record.Succeeded=$true}
catch {$record.Error=$_.Exception.Message;throw}
finally {
    $path=Join-Path $RunRoot ('window-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)+'.json')
    $record | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding utf8NoBOM
}