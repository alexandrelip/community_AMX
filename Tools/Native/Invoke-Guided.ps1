[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][scriptblock]$Guidance,
    [Parameter(Mandatory)][scriptblock]$Condition,
    [Parameter(Mandatory)][hashtable]$Seed,
    [ValidateRange(1,3600)][int]$TimeoutSeconds=300,
    [ValidateRange(1,100)][int]$StableSamples=3,
    [ValidateRange(0.001,1)][double]$Deadband=0.015,
    [double]$AfterModelTime=-1,
    [string]$ReportName
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$' -or
    $state.Profile -ne (Join-Path (Join-Path $env:USERPROFILE 'Saved Games') $state.ProfileName)){throw 'Guided stage requires an owned native run.'}
if(-not $state.OperationalTest){throw 'Guided stage requires an operational fixture.'}
$active=Get-Content -LiteralPath (Join-Path $run 'active.json') -Raw | ConvertFrom-Json -DateKind String
$native=Join-Path (Split-Path -Parent $PSScriptRoot) 'Test-AMXDENISNative.ps1'
$read=Join-Path $PSScriptRoot 'Read-State.ps1'
$watcher=[IO.FileSystemWatcher]::new((Join-Path $state.Profile 'Logs'),'AMXDENIS-native.jsonl')
$watcher.NotifyFilter=[IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::Size
$watcher.EnableRaisingEvents=$true
# Fixed commands could not hold a landing attitude: the open loop flare stalled the
# aircraft from six metres, so each axis is corrected from the measured state instead.
$commanded=@{}
foreach($key in $Seed.Keys){$commanded[$key]=[double]$Seed[$key]}
$trail=[Collections.Generic.List[object]]::new()
$deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
$progress=[DateTime]::UtcNow
$lastTime=$AfterModelTime
$lastSequence=-1
$consecutive=0
$sample=$null
$passed=$false
# The seed only states what the previous stage was believed to leave behind; when it
# was wrong the deadband suppressed the first correction and the aircraft dived away.
$primed=$false
try {
    while([DateTime]::UtcNow -lt $deadline){
        $process=Get-Process -Id $active.ProcessId -ErrorAction SilentlyContinue
        if(-not $process -or $process.ProcessName -ne 'DCS' -or
            $process.StartTime.ToUniversalTime().Ticks -ne ([DateTime]::Parse($active.Started).ToUniversalTime().Ticks)){throw 'Owned process exited or identity changed while guiding.'}
        foreach($recorded in @(& $read -RunRoot $run -Since $lastTime)){
            $lastTime=$recorded.model_time
            $sample=$recorded
            if($recorded.PSObject.Properties['sequence'] -and [int]$recorded.sequence -gt $lastSequence){$lastSequence=[int]$recorded.sequence}
            $conditionResult=& $Condition $recorded
            if($conditionResult -isnot [bool]){throw 'Guidance condition must return one Boolean.'}
            if($conditionResult){$consecutive++}else{$consecutive=0}
            if($consecutive -ge $StableSamples){$passed=$true;break}
        }
        if($passed){break}
        $dispatched=$false
        if($null -ne $sample){
            $desired=& $Guidance $sample $commanded
            if($desired -isnot [hashtable]){throw 'Guidance must return one hashtable of axis demands.'}
            foreach($control in @($desired.Keys)){
                $value=[double]$desired[$control]
                if([double]::IsNaN($value) -or [double]::IsInfinity($value)){throw 'Guidance produced a value that is not a finite number.'}
                if($primed -and $commanded.ContainsKey($control) -and [Math]::Abs($commanded[$control]-$value) -lt $Deadband){continue}
                # Waiting for each request to be echoed made the loop slower than the
                # phugoid it had to damp, so acknowledgement is read from the telemetry.
                & $native -Action Command -RunRoot $run -Control $control -Value $value | Out-Null
                $requested=[int]((Get-Content -LiteralPath (Join-Path $state.Profile 'Scripts/request.txt') -Raw).Split('|')[0])
                $commanded[$control]=$value
                $dispatched=$true
                $trail.Add([pscustomobject]@{ModelTime=$sample.model_time;Control=$control;Value=$value;Sequence=$requested;
                    Agl=$sample.agl;Ias=$sample.ias;VerticalSpeed=$sample.velocity.y})
            }
            $primed=$true
        }
        if(([DateTime]::UtcNow-$progress).TotalSeconds -ge 10){
            $height=if($null -ne $sample){[Math]::Round([double]$sample.agl,1)}else{'none'}
            $rate=if($null -ne $sample){[Math]::Round([double]$sample.velocity.y,2)}else{'none'}
            Write-Host "AMXDENIS_GUIDED|model_time=$lastTime|agl=$height|vy=$rate|matching_samples=$consecutive/$StableSamples"
            $progress=[DateTime]::UtcNow
        }
        if(-not $dispatched){[void]$watcher.WaitForChanged([IO.WatcherChangeTypes]::Changed,1000)}
    }
} finally {
    $watcher.Dispose()
    # Roll is a rate command: one stage ended with it deflected and the aircraft kept
    # rolling through the gap before the next stage took over.
    if($commanded.ContainsKey('FlightRoll') -and $commanded['FlightRoll'] -ne 0){
        try {
            & $native -Action Command -RunRoot $run -Control 'FlightRoll' -Value 0 | Out-Null
            $commanded['FlightRoll']=0
            $trail.Add([pscustomobject]@{ModelTime=$lastTime;Control='FlightRoll';Value=0;Sequence=-1;
                Agl=$null;Ias=$null;VerticalSpeed=$null})
        } catch {Write-Host ('AMXDENIS_GUIDED_NEUTRAL_FAILED|'+$_.Exception.Message)}
    }
    if($ReportName){
        $acknowledged=@($trail | Where-Object {$_.Sequence -le $lastSequence}).Count
        Write-IntegrationJson (Resolve-IntegrationFile $run $ReportName) ([ordered]@{Schema='AMXDENIS_NATIVE_GUIDANCE_1';
            Guidance=$Guidance.ToString();Condition=$Condition.ToString();Seed=$Seed;Deadband=$Deadband;
            AfterModelTime=$AfterModelTime;RequiredSamples=$StableSamples;ConsecutiveSamples=$consecutive;
            Passed=$passed;Commands=$trail.ToArray();AcknowledgedCommands=$acknowledged;HighestObservedSequence=$lastSequence;
            LastObserved=$sample;TimedObservationSeconds=$TimeoutSeconds;
            InputSource='Closed loop axis demands via private Export; NOT physical keyboard/mouse/HOTAS';
            PhysicalInputApproved=$false;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
    }
}
if(-not $passed){throw 'Guided condition was not observed in time; raw evidence retained.'}
Write-Host "AMXDENIS_GUIDED_OBSERVED|model_time=$lastTime|commands=$($trail.Count)"
return $sample
