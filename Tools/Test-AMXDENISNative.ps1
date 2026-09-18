[CmdletBinding()]
param(
    [ValidateSet('Prepare','Start','Await','Inspect','Command','Stop','Verify')][string]$Action='Inspect',
    [Parameter(Mandatory)][string]$RunRoot,
    [string]$CandidateRoot,
    [ValidateSet('GroundHot','GroundCold')][string]$StartMode='GroundHot',
    [string]$DcsRoot='D:\Program Files\DCS World',
    [ValidateSet('bin','bin-mt')][string]$EngineDirectory='bin-mt',
    [ValidateRange(800,2560)][int]$Width=1600,
    [ValidateRange(600,1440)][int]$Height=900,
    [ValidateRange(5,600)][int]$TimeoutSeconds=180,
    [ValidateRange(0,100000)][int]$Sequence=0,
    [string]$Control,
    [double]$Value=1
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$repo=Split-Path -Parent $PSScriptRoot
$run=Assert-IntegrationPath $RunRoot
$archive=Assert-IntegrationPath (Join-Path $env:LOCALAPPDATA 'AMXDENIS-Integration')
if ((Split-Path -Parent $run) -ne (Join-Path $archive 'Runs') -or (Split-Path -Leaf $run) -notmatch '^Native-REV07-[A-Za-z0-9_-]+$') {throw 'Use a new direct Native-REV07 run below the integration archive.'}
function PlainHash([string]$Path) { if(Test-Path -LiteralPath $Path -PathType Leaf){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash};return $null }
function PrivatePath([string]$Profile,[string]$Relative) {
    $full=[IO.Path]::GetFullPath($Profile)
    if ((Split-Path -Parent $full) -ne (Join-Path $env:USERPROFILE 'Saved Games') -or
        (Split-Path -Leaf $full) -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$') {throw 'Not an owned AMXDENIS test profile.'}
    $parts=$Relative.Replace('\','/').Split('/')
    if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '[<>:"|?*\x00-\x1f]' -or @($parts | Where-Object {-not $_ -or $_ -in @('.','..','.git') -or $_ -match '[. ]$'}).Count){throw 'Unsafe private relative path'}
    $path=[IO.Path]::GetFullPath((Join-Path $full $Relative));$parent=$path
    while($parent){if((Test-Path -LiteralPath $parent) -and ((Get-Item -LiteralPath $parent -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked profile path refused'};$parent=Split-Path -Parent $parent}
    return $path
}
function FreshCopy([string]$Source,[string]$Destination) {
    $hash=PlainHash $Source;if(-not $hash){throw "Missing copy source: $Source"}
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    [IO.File]::Copy($Source,$Destination,$false)
    if((PlainHash $Destination) -ne $hash -or (PlainHash $Source) -ne $hash){throw 'Copy verification failed'}
}
function SharedText([string]$Path,[int]$TailBytes=0) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return ''}
    $stream=[IO.FileStream]::new($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    $offset=if($TailBytes -gt 0){[Math]::Max(0,$stream.Length-$TailBytes)}else{0}
    if($offset -gt 0){[void]$stream.Seek($offset,[IO.SeekOrigin]::Begin)}
    $reader=[IO.StreamReader]::new($stream)
    try{if($offset -gt 0){[void]$reader.ReadLine()};return $reader.ReadToEnd()}finally{$reader.Dispose()}
}
function FreeEnvironment {
    if(@(Get-CimInstance Win32_Process -Filter "Name='DCS.exe' OR Name='DCS_updater.exe' OR Name='ModelViewer2.exe'").Count){throw 'Another simulator/viewer session exists; nothing will be closed or reused.'}
}
function CheckFiles($State) {
    foreach($row in $State.RuntimeFiles){if((PlainHash (PrivatePath $State.Profile ('Mods/aircraft/AMXDENIS/'+$row.Path))) -ne $row.SHA256){throw "Staged runtime changed: $($row.Path)"}}
    foreach($row in $State.PrivateScripts){if((PlainHash (PrivatePath $State.Profile $row.Path)) -ne $row.SHA256){throw "Private observer/input changed: $($row.Path)"}}
    $actualScripts=@(Get-ChildItem -LiteralPath (PrivatePath $State.Profile 'Scripts') -Filter '*.lua' -File -Recurse)
    $expectedScripts=@($State.PrivateScripts | Where-Object {$_.Path -like 'Scripts/*.lua'})
    if($actualScripts.Count -ne $expectedScripts.Count){throw 'Unexpected Lua observer/hook in isolated profile'}
    if((PlainHash $State.Mission) -ne $State.MissionSHA256){throw 'Mission changed after staging'}
}
function OwnedProcess($State) {
    $active=Get-Content -LiteralPath (Join-Path $run 'active.json') -Raw | ConvertFrom-Json -DateKind String
    $process=Get-Process -Id $active.ProcessId -ErrorAction SilentlyContinue
    if(-not $process){return $null}
    $cim=Get-CimInstance Win32_Process -Filter "ProcessId=$($active.ProcessId)"
    $pattern='(?:^|\s)-w\s+"?'+[regex]::Escape($State.ProfileName)+'"?(?:\s|$)'
    if($process.ProcessName -ne 'DCS' -or $process.StartTime.ToUniversalTime().Ticks -ne ([datetime]::Parse($active.Started).ToUniversalTime().Ticks) -or
        $cim.ExecutablePath -ne $State.Executable -or $cim.CommandLine -notmatch $pattern){throw 'Owned process identity mismatch; no action taken'}
    return $process
}
if($Action -eq 'Prepare') {
    FreeEnvironment
    if(Test-Path -LiteralPath $run){throw 'Native run already exists'}
    $candidate=Assert-IntegrationPath $CandidateRoot
    if((Split-Path -Parent $candidate) -ne (Join-Path $archive 'Candidates')){throw 'Candidate outside dedicated area'}
    $manifestPath=Join-Path $candidate 'candidate-manifest.json';$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
    if($manifest.Schema -ne 'AMXDENIS_CANDIDATE_1' -or $manifest.AircraftType -ne 'AMXT_M' -or $manifest.PilotSeat -ne 1 -or
        $manifest.ExternalResourcesChanged -ne $false -or $manifest.FlightModelChanged -ne $false){throw 'Wrong candidate scope'}
    foreach($row in $manifest.Files){if((Get-IntegrationHash (Resolve-IntegrationFile $candidate $row.Path)) -ne $row.SHA256){throw 'Candidate changed since build'}}
    $reference=Join-Path $PSScriptRoot 'Native\Reference'
    $references=Get-Content -LiteralPath (Join-Path $reference 'manifest.json') -Raw | ConvertFrom-Json -DateKind String
    foreach($row in $references.Files){if((PlainHash (Join-Path $reference $row.Path)) -ne $row.SHA256){throw 'Native test reference changed'}}
    $profileName='DCS.AMXDENIS-'+(Split-Path -Leaf $run)
    $profile=Join-Path (Join-Path $env:USERPROFILE 'Saved Games') $profileName
    $null=PrivatePath $profile 'Config/options.lua'
    if(Test-Path -LiteralPath $profile){throw 'Private profile must be new'}
    $normal=Join-Path (Join-Path $env:USERPROFILE 'Saved Games') 'DCS'
    $options=Join-Path $normal 'Config/options.lua'
    $lua=Join-Path $DcsRoot 'bin/luae.exe';$exe=Join-Path $DcsRoot ($EngineDirectory+'/DCS.exe')
    foreach($path in @($options,$lua,$exe)){if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw 'Missing native prerequisite'}}
    New-Item -ItemType Directory -Path $run | Out-Null
    $protectedPaths=@($options,(Join-Path $normal 'Scripts/Export.lua'))
    if(Test-Path -LiteralPath (Join-Path $normal 'Config/Input')){$protectedPaths+=@(Get-ChildItem -LiteralPath (Join-Path $normal 'Config/Input') -File -Recurse | Select-Object -ExpandProperty FullName)}
    foreach($bin in @('bin','bin-mt')){foreach($name in @('OptiScaler.ini','dxgi.dll')){$path=Join-Path $DcsRoot ($bin+'/'+$name);if(Test-Path -LiteralPath $path){$protectedPaths+=$path}}}
    $protected=@($protectedPaths | Sort-Object -Unique | ForEach-Object {[pscustomobject]@{Path=$_;SHA256=(PlainHash $_)}})
    Write-IntegrationJson (Join-Path $run 'protected.json') $protected
    FreshCopy $options (Join-Path $run 'options.before.lua')
    foreach($dir in @('Config','Scripts/Hooks','Logs','Tracks','ScreenShots','Config/Input/AMX/keyboard','Mods/aircraft/AMXDENIS')){New-Item -ItemType Directory -Path (PrivatePath $profile $dir) -Force | Out-Null}
    try {
        foreach($row in $manifest.Files){FreshCopy (Resolve-IntegrationFile $candidate $row.Path) (PrivatePath $profile ('Mods/aircraft/AMXDENIS/'+$row.Path))}
        foreach($name in @('authdata.bin','network.vault','pluginsEnabled.lua')){
            $source=Join-Path $normal ('Config/'+$name)
            if(Test-Path -LiteralPath $source){FreshCopy $source (PrivatePath $profile ('Config/'+$name))}
        }
        $template=Join-Path $run 'template';New-Item -ItemType Directory -Path $template | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $reference 'AMX_Free_Flight.miz'))
        try {foreach($entry in $zip.Entries){if($entry.FullName -notin @('mission','options','warehouses','l10n/DEFAULT/dictionary','l10n/DEFAULT/mapResource')){continue};$dest=Resolve-IntegrationFile $template $entry.FullName;New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null;[IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$dest,$false)}}finally{$zip.Dispose()}
        $preparation=@(& $lua (Join-Path $PSScriptRoot 'Native/prepare.lua') $profile $template (Join-Path $run 'options.before.lua') $StartMode $Width $Height 2>&1)
        $code=$LASTEXITCODE;$preparation | Set-Content -LiteralPath (Join-Path $run 'prepare.log') -Encoding utf8NoBOM
        if($code -ne 0 -or ($preparation -join "`n") -notmatch 'AMXDENIS_NATIVE_PREPARE_OK'){$preparation | Write-Output;throw 'Native preparation failed'}
        $mission=Join-Path $run 'AMXT_M-cockpit.miz';[IO.Compression.ZipFile]::CreateFromDirectory($template,$mission)
        FreshCopy (Join-Path $PSScriptRoot 'Native/observer.lua') (PrivatePath $profile 'Scripts/Export.lua')
        FreshCopy (Join-Path $PSScriptRoot 'Native/hook.lua') (PrivatePath $profile 'Scripts/Hooks/AMXDENIS-native.lua')
        $scripts=@(Get-ChildItem -LiteralPath (PrivatePath $profile 'Scripts') -Recurse -File | ForEach-Object {[pscustomobject]@{Path=[IO.Path]::GetRelativePath($profile,$_.FullName).Replace('\','/');SHA256=(PlainHash $_.FullName)}})
        $scripts+= [pscustomobject]@{Path='Config/Input/AMX/keyboard/Keyboard.diff.lua';SHA256=(PlainHash (PrivatePath $profile 'Config/Input/AMX/keyboard/Keyboard.diff.lua'))}
        $state=[ordered]@{Schema='AMXDENIS_NATIVE_RUN_1';RunRoot=$run;Profile=$profile;ProfileName=$profileName;Executable=$exe;DcsRoot=$DcsRoot;
            Candidate=$candidate;BuildId=$manifest.BuildId;CandidateManifestSHA256=(PlainHash $manifestPath);RuntimeFiles=$manifest.Files;
            Mission=$mission;MissionSHA256=(PlainHash $mission);PrivateScripts=$scripts;Prepared=$true;StartMode=$StartMode;
            Scope='native_front_cockpit_displays_inputs_only';SourceReadOnly=$true;NativeValidated=$false;UserAuthorizedNativeLaunch=$true}
        Write-IntegrationJson (Join-Path $run 'run.json') $state
        CheckFiles ([pscustomobject]$state)
        Write-Output "AMXDENIS_NATIVE_PREPARED|$profileName|files=$($manifest.Files.Count)|$run"
    } catch {
        foreach($name in @('authdata.bin','network.vault')){$path=PrivatePath $profile ('Config/'+$name);if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}}
        throw
    }
    return
}
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or $state.ProfileName -ne (Split-Path -Leaf $state.Profile)){throw 'Run identity mismatch'}
$null=PrivatePath $state.Profile 'Logs/AMXDENIS-native.jsonl'
if($Action -eq 'Start') {
    FreeEnvironment;CheckFiles $state
    if(Test-Path -LiteralPath (Join-Path $run 'active.json')){throw 'Use a fresh prepared run for every launch'}
    $process=Start-Process -FilePath $state.Executable -WorkingDirectory $state.DcsRoot -PassThru -ArgumentList @('-w',$state.ProfileName,'--force_disable_VR','--mission',('"'+$state.Mission+'"'))
    Write-IntegrationJson (Join-Path $run 'active.json') ([ordered]@{ProcessId=$process.Id;Started=$process.StartTime.ToUniversalTime().ToString('o');Profile=$state.ProfileName;UserOpened=$false;CloseAllowed=$true})
    Write-Output "AMXDENIS_NATIVE_STARTED|pid=$($process.Id)|$($state.ProfileName)";return
}
if($Action -in @('Await','Inspect','Command')) {
    if(-not(OwnedProcess $state)){throw 'Owned DCS is not running'}
    if($Action -eq 'Command') {
        if($Control -notmatch '^(Icp\w+|Mfd\w+|Master|HudBrightness|CautionAcknowledge|Battery|Generator[12]|View(Right|Up|Forward|Yaw|Pitch|Zoom|Reset))$' -or
            [double]::IsNaN($Value) -or [double]::IsInfinity($Value) -or $Value -lt -1 -or $Value -gt 1){throw 'Diagnostic request outside allowed display/system selectors'}
        $path=PrivatePath $state.Profile 'Scripts/request.txt';$sequence=1
        if(Test-Path -LiteralPath $path){$sequence=[int]((Get-Content -LiteralPath $path -Raw).Split('|')[0])+1}
        $text=$sequence.ToString()+'|'+$Control+'|'+$Value.ToString('R',[Globalization.CultureInfo]::InvariantCulture)
        [IO.File]::WriteAllText($path+'.tmp',$text,[Text.UTF8Encoding]::new($false));[IO.File]::Move($path+'.tmp',$path,$true)
        Write-Output "AMXDENIS_DIAGNOSTIC_REQUEST|$text|not_physical_input";return
    }
    $path=PrivatePath $state.Profile 'Logs/AMXDENIS-native.jsonl'
    if($Action -eq 'Await') {
        $watcher=[IO.FileSystemWatcher]::new((PrivatePath $state.Profile 'Logs'));$watcher.EnableRaisingEvents=$true
        $deadline=[datetime]::UtcNow.AddSeconds($TimeoutSeconds)
        try {while([datetime]::UtcNow -lt $deadline){
            if(-not(OwnedProcess $state)){throw 'DCS exited before cockpit readiness'}
            $text=SharedText $path $(if($Sequence -gt 0){2097152}else{0});$hook=SharedText (PrivatePath $state.Profile 'Logs/AMXDENIS-hook.log')
            if($text -match '"kind":"ERROR"' -or $hook -match '\|ERROR\|'){throw 'Private observer/hook error; preserve logs'}
            if($Sequence -gt 0 -and $text -match ('"kind":"REJECT"[^\r\n]*"sequence":'+$Sequence+'[,}]')){throw 'Requested observation command was rejected; no capture approval'}
            $observed=if($Sequence -gt 0){[regex]::Matches($text,'(?m)^\{[^\r\n]*"kind":"STATE"[^\r\n]*"sequence":'+$Sequence+'[,}]').Count -ge 3}else{$text -match '"kind":"READY"'}
            if($observed){CheckFiles $state;Write-Output "AMXDENIS_COCKPIT_OBSERVED|sequence=$Sequence|visual_and_input_verdict=PENDING";return}
            $native=SharedText (PrivatePath $state.Profile 'Logs/dcs.log')
            if($native -match 'C0000005|offline auth is not available|login was cancelled|missed aicraft descriptor for AMXT_M'){throw 'Native startup blocked; inspect raw DCS log'}
            [void]$watcher.WaitForChanged(([IO.WatcherChangeTypes]::Changed -bor [IO.WatcherChangeTypes]::Created),1000)
        };throw "Observation timed out for sequence $Sequence; inspect telemetry before classifying the request"}finally{$watcher.Dispose()}
    }
    $text=SharedText $path
    $records=@($text -split "`n" | Where-Object {$_ -match '^\{.*\}$'} | ForEach-Object {$_ | ConvertFrom-Json -Depth 30 -DateKind String})
    $records | Where-Object {$_.kind -ne 'STATE'} | Select-Object -Last 8 | ConvertTo-Json -Depth 6
    $last=$records | Where-Object kind -eq 'STATE' | Select-Object -Last 1
    if($last){$last | ConvertTo-Json -Depth 8}else{Write-Output 'No complete native sample yet'}
    return
}
if($Action -eq 'Stop') {
    $process=OwnedProcess $state
    if($process){[void]$process.CloseMainWindow();if(-not $process.WaitForExit(15000)){Stop-Process -InputObject $process; if(-not $process.WaitForExit(15000)){throw 'Owned DCS failed to stop'}}}
}
if($Action -in @('Stop','Verify')) {
    $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ');$report=Join-Path $run ('finalization-'+$stamp)
    New-Item -ItemType Directory -Path $report | Out-Null
    $passed=$true;$errors=[Collections.Generic.List[string]]::new()
    try {
        CheckFiles $state
        foreach($row in (Get-Content -LiteralPath (Join-Path $run 'protected.json') -Raw | ConvertFrom-Json -DateKind String)){
            if((PlainHash $row.Path) -ne $row.SHA256){$passed=$false;$errors.Add('Protected file changed, not restored: '+$row.Path)}
        }
        foreach($name in @('dcs.log','AMXDENIS-native.jsonl','AMXDENIS-hook.log','debrief.log')){$source=PrivatePath $state.Profile ('Logs/'+$name);if(Test-Path -LiteralPath $source){[IO.File]::WriteAllText((Join-Path $report $name),(SharedText $source),[Text.UTF8Encoding]::new($false))}}
    } catch {$passed=$false;$errors.Add($_.Exception.Message)}
    finally {
        if(-not(OwnedProcess $state)){foreach($name in @('authdata.bin','network.vault')){$path=PrivatePath $state.Profile ('Config/'+$name);if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path}}}
    }
    Write-IntegrationJson (Join-Path $report 'integrity.json') ([ordered]@{Schema='AMXDENIS_NATIVE_FINALIZATION_1';IntegrityPassed=$passed;Errors=$errors.ToArray();
        RuntimeBuildId=$state.BuildId;NativeAcceptanceGranted=$false;NormalProfileRestored=$false;ProfileRetained=$true;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
    Write-Output "AMXDENIS_NATIVE_FINALIZED|integrity=$passed|$report"
    if(-not $passed){throw 'Finalization integrity not approved; evidence retained'}
}