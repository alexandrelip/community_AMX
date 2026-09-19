[CmdletBinding()]
param([string]$RunRoot,[ValidateSet('Full','Mechanisms')][string]$Stages='Full',[switch]$Describe)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Test-CommandPathTravel {
    param($Before,$After,[ValidateSet(-1,1)][int]$Direction=1,
        [double]$Minimum=0,[double]$Maximum=1,[double]$MinimumChange=0.05)
    foreach($value in @($Before,$After,$Minimum,$Maximum,$MinimumChange)){
        if(($value -isnot [double] -and $value -isnot [int] -and $value -isnot [long] -and $value -isnot [decimal]) -or
            [double]::IsNaN($value) -or [double]::IsInfinity($value)){return $false}
    }
    if($Minimum -ge $Maximum -or $MinimumChange -le 0 -or
        $Before -lt $Minimum -or $Before -gt $Maximum -or $After -lt $Minimum -or $After -gt $Maximum){return $false}
    return [bool](($After-$Before)*$Direction -ge $MinimumChange)
}
function Get-CommandPathValue($Sample,[string]$Path) {
    $value=$Sample
    foreach($part in $Path.Split('.')){
        if($null -eq $value -or -not $value.PSObject.Properties[$part]){return $null}
        $value=$value.$part
    }
    return $value
}
function Get-CommandPathStages {
    param([ValidateSet('Full','Mechanisms')][string]$Stages='Full')
    # Mechanisms keeps the engine off, so surfaces can be compared on any aircraft
    # without the brake interlock that a running engine would require.
    $surfaces=@(
        @{Name='CameraYaw';Control='ViewYaw';Value=0.05;Path='camera.x.x';Direction=0;Minimum=-1;Maximum=1;Change=0.0005;Timeout=15;Required=$false}
        @{Name='CanopyClose';Control='Canopy';Value=1;Path='mechanisms.canopy.value';Direction=-1;Minimum=0;Maximum=1;Change=0.1;Timeout=20;Required=$false}
        @{Name='FlapsDown';Control='Flaps';Value=1;Path='external_arguments.9';Direction=1;Minimum=0;Maximum=1;Change=0.1;Timeout=35;Required=$false}
        @{Name='FlapsUp';Control='Flaps';Value=0;Path='external_arguments.9';Direction=-1;Minimum=0;Maximum=1;Change=0.1;Timeout=35;Required=$false}
        @{Name='AirbrakeOut';Control='NativeAirbrakeOn';Value=1;Path='mechanisms.speedbrakes.value';Direction=1;Minimum=0;Maximum=1;Change=0.1;Timeout=20;Required=$false}
        @{Name='AirbrakeIn';Control='NativeAirbrakeOff';Value=1;Path='mechanisms.speedbrakes.value';Direction=-1;Minimum=0;Maximum=1;Change=0.1;Timeout=20;Required=$false}
    )
    if($Stages -eq 'Mechanisms'){return $surfaces | ForEach-Object {[pscustomobject]$_}}
    @(
        $surfaces[0]
        $surfaces[1]
        @{Name='BrakeOn';Control='FlightBrake';Value=1;Path='mechanisms.wheelbrakes.value';Direction=1;Minimum=0;Maximum=1;Change=0.5;Timeout=10;Required=$true}
        @{Name='EngineStart';Control='NativeEnginesStart';Value=1;Path='engine.RPM.left';Direction=1;Minimum=0;Maximum=120;Change=53;Timeout=120;Required=$true}
        $surfaces[2]
        $surfaces[3]
        $surfaces[4]
        $surfaces[5]
        @{Name='ThrottleReducedAxis';Control='FlightThrottle';Value=0.3;Path='engine.RPM.left';Direction=1;Minimum=0;Maximum=120;Change=5;Timeout=35;Required=$false}
        @{Name='ThrottlePositive';Control='FlightThrottle';Value=1;Path='engine.RPM.left';Direction=-1;Minimum=0;Maximum=120;Change=5;Timeout=45;Required=$false}
        @{Name='EngineStop';Control='NativeEnginesStop';Value=1;Path='engine.RPM.left';Direction=-1;Minimum=0;Maximum=120;Change=40;Timeout=100;Required=$true}
    ) | ForEach-Object {[pscustomobject]$_}
}
function Assert-CommandPathStationary($Sample) {
    foreach($axis in @('x','y','z')){
        $value=Get-CommandPathValue $Sample ('velocity.'+$axis)
        if($null -eq $value -or $value -is [string] -or $value -is [bool] -or
            [double]::IsNaN($value) -or [double]::IsInfinity($value) -or [Math]::Abs($value) -gt 0.25){
            throw 'Command-path aircraft is moving or its velocity is unavailable.'
        }
    }
}
if($Describe){Get-CommandPathStages -Stages $Stages;return}
if(-not $RunRoot){throw 'RunRoot is required for a native command-path test.'}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
# GroundHot is only useful for the surface set, where the engine is never commanded.
$allowedModes=if($Stages -eq 'Mechanisms'){@('GroundCold','GroundHot')}else{@('GroundCold')}
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or $state.StartMode -notin $allowedModes -or
    -not $state.OperationalTest){throw 'Command-path probe requires an operational ground fixture matching the selected stages.'}
$reportPath=Resolve-IntegrationFile $run 'native-command-path.json'
if(Test-Path -LiteralPath $reportPath){throw 'Command-path report already exists.'}

$read={& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run}
$send={param($Control,$Value,$Name)
    $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') -RunRoot $run -Control $Control -Value $Value -ReportName ('command-path-'+$Name+'.json')
}
$probes=[Collections.Generic.List[object]]::new()
$cleanupErrors=[Collections.Generic.List[string]]::new()
$failure=$null
$engineRequested=$false
$plan=@(Get-CommandPathStages -Stages $Stages)
try {
    $cold=& $read
    Assert-CommandPathStationary $cold
    $rpm=Get-CommandPathValue $cold 'engine.RPM.left'
    if($null -eq $rpm -or $rpm -is [string] -or [double]::IsNaN($rpm) -or $rpm -lt 0){throw 'Engine reading is unavailable.'}
    if($state.StartMode -eq 'GroundHot'){
        if($rpm -lt 53){throw 'Hot fixture requires a running engine before comparing surfaces.'}
    } elseif($rpm -gt 0.1){throw 'Engine is already running; cold fixture required.'}
    foreach($stage in $plan){
        $before=& $read
        Assert-CommandPathStationary $before
        $beforeValue=Get-CommandPathValue $before $stage.Path
        $probe=[ordered]@{Probe=$stage.Name;Control=$stage.Control;CommandValue=$stage.Value;Path=$stage.Path;
            Before=$beforeValue;BeforeModelTime=$before.model_time;After=$null;AfterModelTime=$null;
            DispatchAccepted=$false;Succeeded=$false;StableSamples=0;Error=$null}
        try {
            if($stage.Name -eq 'CanopyClose' -and ($null -eq $beforeValue -or $beforeValue -lt 0.85)){
                throw 'Canopy is not at the expected open extreme.'
            }
            if($stage.Name -eq 'EngineStart'){
                if((Get-CommandPathValue $before 'mechanisms.wheelbrakes.value') -lt 0.5){throw 'Confirmed wheel brakes are required before starting.'}
                & $send 'FlightThrottle' 1 'initial-positive-throttle'
                $engineRequested=$true
            }
            & $send $stage.Control $stage.Value $stage.Name
            $probe.DispatchAccepted=$true
            $condition={param($sample)
                Assert-CommandPathStationary $sample
                $actual=Get-CommandPathValue $sample $stage.Path
                $direction=$stage.Direction
                if($direction -eq 0){
                    if($null -eq $actual -or $null -eq $beforeValue){return $false}
                    $direction=if($actual -ge $beforeValue){1}else{-1}
                }
                Test-CommandPathTravel $beforeValue $actual -Direction $direction -Minimum $stage.Minimum -Maximum $stage.Maximum -MinimumChange $stage.Change
            }
            $after=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $condition -AfterModelTime $before.model_time -TimeoutSeconds $stage.Timeout -ReportName ('command-path-wait-'+$stage.Name+'.json')
            $probe.After=Get-CommandPathValue $after $stage.Path
            $probe.AfterModelTime=$after.model_time
            $probe.StableSamples=3;$probe.Succeeded=$true
        } catch {
            $probe.Error=$_.Exception.Message
            try {$after=& $read;$probe.After=Get-CommandPathValue $after $stage.Path;$probe.AfterModelTime=$after.model_time}catch {$cleanupErrors.Add('Outcome read: '+$_.Exception.Message)}
            if($probe.Error -ne 'Native condition was not observed in time; raw evidence retained.' -or $stage.Required){throw}
        } finally {$probes.Add($probe)}
        if($stage.Name -eq 'EngineStart'){
            $null=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -AfterModelTime $after.model_time -TimeoutSeconds 120 -StableSamples 15 -ReportName 'command-path-idle-settled.json' -Condition {
                param($sample)
                Assert-CommandPathStationary $sample
                $rpm=Get-CommandPathValue $sample 'engine.RPM.left'
                return [bool]($null -ne $rpm -and $rpm -ge 53 -and $rpm -le 65)
            }
        }
    }
} catch {$failure=$_.Exception.Message} finally {
    if($engineRequested){
        try {& $send 'FlightThrottle' 1 'cleanup-positive-throttle'}catch {$cleanupErrors.Add($_.Exception.Message)}
        try {& $send 'NativeEnginesStop' 1 'cleanup-stop'}catch {$cleanupErrors.Add($_.Exception.Message)}
    }
    $effective=@($probes | Where-Object Succeeded)
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_NATIVE_COMMAND_PATH_2';Run=$state.ProfileName;BuildId=$state.BuildId;
        ControlAircraft=$(if($state.PSObject.Properties['ControlAircraft']){$state.ControlAircraft}else{'none'});
        StartMode=$state.StartMode;Stages=$Stages;Probes=$probes.ToArray();Failure=$failure;CleanupErrors=$cleanupErrors.ToArray();
        Planned=$plan.Count;Attempted=$probes.Count;Effective=$effective.Count;
        SequenceCompleted=($probes.Count -eq $plan.Count -and -not $failure);
        AllTransitionsPassed=($probes.Count -eq $plan.Count -and $effective.Count -eq $plan.Count -and -not $failure -and $cleanupErrors.Count -eq 0);
        NativeAcceptanceGranted=$false;Scope='Measured native command transitions only; no keyboard, mouse, physical HOTAS or full-flight approval';
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
if($failure){throw $failure}
if($cleanupErrors.Count){throw ('Command-path cleanup failed: '+($cleanupErrors -join '; '))}
Write-Output "AMXDENIS_COMMAND_PATH|effective=$($effective.Count)/$($plan.Count)|$reportPath"
