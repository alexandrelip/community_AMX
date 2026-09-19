[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][scriptblock]$Condition,
    [ValidateRange(1,3600)][int]$TimeoutSeconds=30,
    [ValidateRange(1,100)][int]$StableSamples=3,
    [double]$AfterModelTime=-1,
    [string]$ReportName
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$'){throw 'Wait requires an owned native run.'}
$active=Get-Content -LiteralPath (Join-Path $run 'active.json') -Raw | ConvertFrom-Json -DateKind String
$directory=Join-Path $state.Profile 'Logs'
$watcher=[IO.FileSystemWatcher]::new($directory,'AMXDENIS-native.jsonl')
$watcher.NotifyFilter=[IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::Size
$watcher.EnableRaisingEvents=$true
$deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
$progress=[DateTime]::UtcNow
$lastTime=$AfterModelTime
$consecutive=0
$sample=$null
$passed=$false
try {
    while([DateTime]::UtcNow -lt $deadline){
        $process=Get-Process -Id $active.ProcessId -ErrorAction SilentlyContinue
        if(-not $process -or $process.ProcessName -ne 'DCS' -or
            $process.StartTime.ToUniversalTime().Ticks -ne ([DateTime]::Parse($active.Started).ToUniversalTime().Ticks)){throw 'Owned process exited or identity changed while observing.'}
        $sample=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
        # Short transients are missed by sampling only the newest record, so every
        # sample recorded since the last one is evaluated in order.
        foreach($recorded in @(& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run -Since $lastTime)){
            $lastTime=$recorded.model_time
            $sample=$recorded
            $conditionResult=& $Condition $recorded
            if($conditionResult -isnot [bool]){throw 'Observation condition must return one Boolean.'}
            if($conditionResult){$consecutive++}else{$consecutive=0}
            if($consecutive -ge $StableSamples){$passed=$true;break}
        }
        if($passed){break}
        if(([DateTime]::UtcNow-$progress).TotalSeconds -ge 10){
            Write-Host "AMXDENIS_WAIT|model_time=$lastTime|matching_samples=$consecutive/$StableSamples"
            $progress=[DateTime]::UtcNow
        }
        [void]$watcher.WaitForChanged([IO.WatcherChangeTypes]::Changed,1000)
    }
} finally {
    $watcher.Dispose()
    if($ReportName){
        Write-IntegrationJson (Resolve-IntegrationFile $run $ReportName) ([ordered]@{Schema='AMXDENIS_NATIVE_CONDITION_1';
            Condition=$Condition.ToString();AfterModelTime=$AfterModelTime;RequiredSamples=$StableSamples;ConsecutiveSamples=$consecutive;
            Passed=$passed;LastObserved=$sample;TimedObservationSeconds=$TimeoutSeconds;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
    }
}
if(-not $passed){throw 'Native condition was not observed in time; raw evidence retained.'}
Write-Host "AMXDENIS_CONDITION_OBSERVED|model_time=$lastTime|samples=$consecutive"
return $sample