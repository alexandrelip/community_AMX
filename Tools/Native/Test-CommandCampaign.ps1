[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CandidateRoot,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$CampaignName,
    [ValidateRange(1,3)][int]$Cycles=2,
    [switch]$NativeValuePayload,
    [ValidateSet('bin','bin-mt')][string]$EngineDirectory='bin'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$tools=Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $tools 'AMXDENISIntegration.psm1') -Force
$archive=Assert-IntegrationPath (Join-Path $env:LOCALAPPDATA 'AMXDENIS-Integration/Runs')
$destination=Resolve-IntegrationFile $archive ('CommandCampaign-'+$CampaignName)
$scenarios=@(for($cycle=1;$cycle -le $Cycles;$cycle++){
    [pscustomobject]@{Name=('AMXT_M-REV07-'+$cycle);Aircraft='none'}
})
if(Test-Path -LiteralPath $destination){throw 'Campaign already exists; historical results are never overwritten.'}
foreach($scenario in $scenarios){
    $path=Resolve-IntegrationFile $archive ('Native-REV07-'+$CampaignName+'-'+$scenario.Name)
    if(Test-Path -LiteralPath $path){throw 'A campaign run already exists; choose a new campaign name.'}
}
New-Item -ItemType Directory -Path $destination | Out-Null
$runs=[Collections.Generic.List[object]]::new()
$fatal=$null
try {
    foreach($scenario in $scenarios){
        $run=Resolve-IntegrationFile $archive ('Native-REV07-'+$CampaignName+'-'+$scenario.Name)
        $row=[ordered]@{Scenario=$scenario.Name;ControlAircraft=$scenario.Aircraft;RunRoot=$run;
            Error=$null;FinalizationError=$null;IntegrityPassed=$false;Planned=0;Attempted=0;Effective=0;
            SequenceCompleted=$false;AllTransitionsPassed=$false;Artifacts=@()}
        try {
            & (Join-Path $tools 'Test-AMXDENISNative.ps1') -Action Prepare -RunRoot $run -CandidateRoot $CandidateRoot -StartMode GroundCold -Operational -IsolateHardwareDevices -FuelKg 1500 -EngineDirectory $EngineDirectory -NativeValuePayload:$NativeValuePayload
            & (Join-Path $tools 'Test-AMXDENISNative.ps1') -Action Start -RunRoot $run
            & (Join-Path $tools 'Test-AMXDENISNative.ps1') -Action Await -RunRoot $run -TimeoutSeconds 180
            & (Join-Path $PSScriptRoot 'Test-NativeCommandPath.ps1') -RunRoot $run
        } catch {$row.Error=$_.Exception.Message} finally {
            if(Test-Path -LiteralPath (Join-Path $run 'run.json')){
                try {
                    & (Join-Path $tools 'Test-AMXDENISNative.ps1') -Action Stop -RunRoot $run
                    $final=@(Get-ChildItem -LiteralPath $run -Directory -Filter 'finalization-*' | Sort-Object Name -Descending)[0]
                    $integrity=Get-Content -LiteralPath (Join-Path $final.FullName 'integrity.json') -Raw | ConvertFrom-Json
                    $row.IntegrityPassed=$integrity.IntegrityPassed -eq $true
                    if(-not $row.IntegrityPassed){throw 'Campaign finalization did not preserve integrity.'}
                } catch {$row.FinalizationError=$_.Exception.Message;$fatal=$row.FinalizationError}
            }
            $reportPath=Join-Path $run 'native-command-path.json'
            if(Test-Path -LiteralPath $reportPath){
                $report=Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
                foreach($field in @('Planned','Attempted','Effective','SequenceCompleted','AllTransitionsPassed')){$row[$field]=$report.$field}
                if($row.Error -or $row.FinalizationError -or -not $row.IntegrityPassed){$row.AllTransitionsPassed=$false}
            }
            if(Test-Path -LiteralPath $run){
                $row.Artifacts=@(Get-ChildItem -LiteralPath $run -File -Recurse | Where-Object {$_.Extension -in @('.json','.jsonl','.log')} | ForEach-Object {
                    [pscustomobject]@{Path=$_.FullName;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
                })
            }
            $runs.Add([pscustomobject]$row)
            Write-Output "AMXDENIS_CAMPAIGN_RUN|$($scenario.Name)|effects=$($row.Effective)/$($row.Planned)|integrity=$($row.IntegrityPassed)|error=$($row.Error)"
        }
        if($fatal){throw $fatal}
    }
} catch {$fatal=$_.Exception.Message} finally {
    $helperPaths=@((Join-Path $PSScriptRoot 'Test-CommandCampaign.ps1'),(Join-Path $PSScriptRoot 'Test-NativeCommandPath.ps1'),
        (Join-Path $tools 'Test-AMXDENISNative.ps1'),(Join-Path $PSScriptRoot 'observer.lua'),(Join-Path $PSScriptRoot 'hook.lua'),(Join-Path $PSScriptRoot 'prepare.lua'))
    $passed=$runs.Count -eq $scenarios.Count -and @($runs | Where-Object {-not $_.AllTransitionsPassed -or -not $_.IntegrityPassed}).Count -eq 0 -and -not $fatal
    Write-IntegrationJson (Join-Path $destination 'summary.json') ([ordered]@{
        Schema='AMXDENIS_COMMAND_CAMPAIGN_1';Name=$CampaignName;Candidate=$CandidateRoot;Aircraft='AMXT_M';Cockpit='REV07';PlannedRuns=$Cycles;
        Runs=$runs.ToArray();AutomationCompleted=($runs.Count -eq $scenarios.Count -and -not $fatal);
        AllTransitionsPassed=$passed;FatalError=$fatal;NativeAcceptanceGranted=$false;
        Scope='Repeated AMXT_M REV07 private ground tests only; not a full flight, keyboard, mouse, physical X56 or advanced-systems acceptance';
        Helpers=@($helperPaths | ForEach-Object {[pscustomobject]@{Path=$_;SHA256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}});
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
if($fatal){throw $fatal}
Write-Output "AMXDENIS_CAMPAIGN_RECORDED|all_transitions=$passed|$destination"