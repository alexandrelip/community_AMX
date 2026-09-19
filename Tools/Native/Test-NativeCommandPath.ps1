[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or $state.StartMode -ne 'GroundCold' -or
    -not $state.OperationalTest){throw 'Command-path probe requires an operational cold ground fixture.'}
$reportPath=Resolve-IntegrationFile $run 'native-command-path.json'
if(Test-Path -LiteralPath $reportPath){throw 'Command-path report already exists.'}

$read={& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run}
$send={param($Control,$Value,$Name,$Release)
    $arguments=@{RunRoot=$run;Control=$Control;Value=$Value;ReportName=('command-path-'+$Name+'.json')}
    if($Release){$arguments.Release=$true}
    $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') @arguments
}
$await={param($Predicate,$Seconds,$Name,$Before)
    try {
        $null=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $Predicate -AfterModelTime $Before.model_time -TimeoutSeconds $Seconds -ReportName ('command-path-wait-'+$Name+'.json')
        return $true
    } catch {
        if($_.Exception.Message -ne 'Native condition was not observed in time; raw evidence retained.'){throw}
        return $false
    }
}
$probes=[Collections.Generic.List[object]]::new()
$failure=$null
$resolution=$null
try {
    $cold=& $read
    if($cold.engine.RPM.left -gt 0.1){throw 'Engine is already running; cold fixture required.'}
    $resolution=[ordered]@{Source=$cold.parameters.AMXDENIS_MECHANISM_COMMAND_SOURCE;
        NamedCount=$cold.parameters.AMXDENIS_MECHANISM_COMMANDS_NAMED;
        GearUp=$cold.parameters.AMXDENIS_MECHANISM_CMD_GEARUP;GearDown=$cold.parameters.AMXDENIS_MECHANISM_CMD_GEARDOWN;
        FlapsOn=$cold.parameters.AMXDENIS_MECHANISM_CMD_FLAPSON;FlapsOff=$cold.parameters.AMXDENIS_MECHANISM_CMD_FLAPSOFF;
        Canopy=$cold.parameters.AMXDENIS_MECHANISM_CMD_CANOPY}

    # Camera runs first, while the cold aircraft is certainly stationary: it is the
    # positive control proving LoSetCommand itself reaches this DCS session.
    $beforeCamera=$cold
    $cameraRejected=$null
    try {& $send 'ViewYaw' 0.05 'camera' $false}
    catch {$cameraRejected=$_.Exception.Message}
    $cameraMoved=$false
    if(-not $cameraRejected){
        $cameraMoved=& $await {param($sample)
            $delta=0.0
            foreach($axis in @('x','y','z')){
                $delta=$delta+[Math]::Abs([double]$sample.camera.x.$axis-[double]$beforeCamera.camera.x.$axis)
            }
            return [bool]($delta -gt 0.0005)
        } 20 'camera' $beforeCamera
    }
    $afterCamera=& $read
    $probes.Add([ordered]@{Probe='CameraByNativeCommand';CommandPath='LoSetCommand view axis';Succeeded=$cameraMoved;
        Rejected=$cameraRejected;Before=$beforeCamera.camera;After=$afterCamera.camera})

    # Canopy and flaps are exercised cold through the cockpit producer, which is the
    # only path already proven to act on this aircraft (engine start uses it).
    # The cold canopy already rests at the open extreme (arg 38 = 0.9), so only a
    # measurable travel towards closed can count as movement.
    $beforeCanopy=& $read
    if([double]$beforeCanopy.external_arguments.'38' -lt 0.85){throw 'Canopy is not at the expected open extreme.'}
    $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') -RunRoot $run -Control 'Canopy' -Value 1 -ReportName 'command-path-canopy.json'
    $canopyMoved=& $await {param($sample) [bool]([double]$sample.external_arguments.'38' -lt 0.85)} 30 'canopy' $beforeCanopy
    $afterCanopy=& $read
    $probes.Add([ordered]@{Probe='CanopyByCockpitDevice';CommandPath='dispatch_action resolved canopy';Succeeded=$canopyMoved;
        Rejected=$null;Before=$beforeCanopy.external_arguments.'38';After=$afterCanopy.external_arguments.'38';
        DispatchAccepted=([int]$afterCanopy.parameters.AMXDENIS_MECHANISM_REQUESTS -gt [int]$beforeCanopy.parameters.AMXDENIS_MECHANISM_REQUESTS);
        DispatchError=$afterCanopy.parameters.AMXDENIS_MECHANISM_REQUEST_ERROR;
        LastCommand=$afterCanopy.parameters.AMXDENIS_LAST_NATIVE_COMMAND})

    $beforeFlaps=& $read
    $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') -RunRoot $run -Control 'Flaps' -Value 1 -ReportName 'command-path-flaps.json'
    $flapsMoved=& $await {param($sample) [bool]([double]$sample.mechanisms.flaps.value -gt 0.05)} 40 'flaps' $beforeFlaps
    $afterFlaps=& $read
    $probes.Add([ordered]@{Probe='FlapsByCockpitDevice';CommandPath='dispatch_action resolved flaps';Succeeded=$flapsMoved;
        Rejected=$null;Before=$beforeFlaps.mechanisms.flaps;After=$afterFlaps.mechanisms.flaps;
        DispatchAccepted=([int]$afterFlaps.parameters.AMXDENIS_MECHANISM_REQUESTS -gt [int]$beforeFlaps.parameters.AMXDENIS_MECHANISM_REQUESTS);
        DispatchError=$afterFlaps.parameters.AMXDENIS_MECHANISM_REQUEST_ERROR;
        LastCommand=$afterFlaps.parameters.AMXDENIS_LAST_NATIVE_COMMAND})

    # Same action, same identifier, different delivery path: this isolates whether the
    # aircraft ignores the command or the cockpit dispatch never reaches the simulation.
    $beforeNativeFlaps=& $read
    & $send 'NativeFlapsDown' 1 'flaps-native' $false
    $nativeFlapsMoved=& $await {param($sample) [bool]([double]$sample.mechanisms.flaps.value -gt 0.05)} 40 'flaps-native' $beforeNativeFlaps
    $afterNativeFlaps=& $read
    $probes.Add([ordered]@{Probe='FlapsByNativeCommand';CommandPath='LoSetCommand iCommandPlaneFlapsOn';Succeeded=$nativeFlapsMoved;
        Rejected=$null;Before=$beforeNativeFlaps.mechanisms.flaps;After=$afterNativeFlaps.mechanisms.flaps})

    foreach($step in @(@('Battery',1,'battery'),@('Master',1,'master'),@('Generator1',1,'gen1'),
        @('Generator2',1,'gen2'),@('FuelShutoff',1,'fuel'))){& $send $step[0] $step[1] $step[2] $false}
    & $send 'FlightBrake' 1 'brake' $false
    $beforeStart=& $read
    & $send 'Starter' 1 'starter' $true
    $running=& $await {param($sample) [bool]($sample.engine.RPM.left -gt 53)} 120 'idle' $beforeStart
    $idle=& $read
    $probes.Add([ordered]@{Probe='EngineIdleByCockpitDevice';CommandPath='dispatch_action engine start';Succeeded=$running;
        Rejected=$null;Before=$beforeStart.engine.RPM.left;After=$idle.engine.RPM.left})
    if($running){
        $beforeThrottle=& $read
        & $send 'FlightThrottle' 1 'throttle-max' $false
        $throttleMoved=& $await {param($sample) [bool]([double]$sample.engine.RPM.left -gt [double]$beforeThrottle.engine.RPM.left+5)} 40 'throttle-max' $beforeThrottle
        $afterThrottle=& $read
        $probes.Add([ordered]@{Probe='ThrottleByNativeCommand';CommandPath='LoSetCommand iCommandPlaneThrustCommon';Succeeded=$throttleMoved;
            Rejected=$null;Before=$beforeThrottle.engine.RPM.left;After=$afterThrottle.engine.RPM.left})
        & $send 'FlightThrottle' 0 'throttle-idle' $false
    }
} catch {$failure=$_.Exception.Message;throw} finally {
    try {& $send 'FuelShutoff' 0 'shutdown' $false} catch {}
    $native=@($probes | Where-Object {$_.CommandPath -like 'LoSetCommand*'})
    $cockpit=@($probes | Where-Object {$_.CommandPath -like 'dispatch_action*'})
    $control=@($probes | Where-Object Probe -eq 'CameraByNativeCommand')
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_NATIVE_COMMAND_PATH_1';Run=$state.ProfileName;BuildId=$state.BuildId;
        CommandResolution=$resolution;Probes=$probes.ToArray();Failure=$failure;
        NativeCommandsAttempted=$native.Count;NativeCommandsEffective=@($native | Where-Object Succeeded).Count;
        CockpitCommandsAttempted=$cockpit.Count;CockpitCommandsEffective=@($cockpit | Where-Object Succeeded).Count;
        PositiveControlEffective=[bool](@($control | Where-Object Succeeded).Count);
        Hypothesis='Mechanisms stayed immobile because the shipped command literals were never the identifiers DCS assigns; resolving the official names should let the already working cockpit dispatch path move them';
        Scope='Diagnostic command provenance only; not keyboard, mouse or physical HOTAS input';
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
