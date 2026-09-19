[CmdletBinding()]
param([string]$RunRoot,[ValidateSet('Keyboard','Native')][string]$AirbrakeSource='Keyboard',[switch]$Describe)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Assert-HydraulicStationary($Sample) {
    foreach($component in @('x','y','z')){
        $property=$Sample.velocity.PSObject.Properties[$component]
        if($null -eq $property -or $null -eq $property.Value -or $property.Value -is [string] -or
            [double]::IsNaN([double]$property.Value) -or [double]::IsInfinity([double]$property.Value) -or
            [Math]::Abs([double]$property.Value) -gt 0.25){throw 'Hydraulic fixture moved or velocity is unavailable; aborting.'}
    }
}

function Get-HydraulicStages {
    @{Name='Cold';Commands=@();Timeout=10;Condition={param($sample)
        $sample.engine.RPM.left -lt 0.1 -and $sample.parameters.AMXDENIS_HYD_1_BAR -eq 0 -and $sample.parameters.AMXDENIS_HYD_2_BAR -eq 0}}
    @{Name='SpinUp';Commands=@(@{Control='FlightThrottle';Value=1},@{Control='FlightBrake';Value=1},
        @{Control='Battery';Value=1},@{Control='Generator1';Value=1},@{Control='Generator2';Value=1},
        @{Control='Master';Value=1},@{Control='FuelShutoff';Value=1},@{Control='Starter';Value=1;Release=$true});Timeout=100;Condition={param($sample)
        $sample.engine.RPM.left -gt 53 -and $sample.parameters.AMXDENIS_HYD_1_BAR -gt 0 -and $sample.parameters.AMXDENIS_HYD_1_BAR -lt 180}}
    @{Name='Nominal';Commands=@();Timeout=60;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_1_BAR -gt 200 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 200}}
    @{Name='Fault1';Commands=@(@{Control='ModelHydraulicFault1';Value=1});Timeout=20;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_1_BAR -lt 93 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 200 -and $sample.parameters.L_HYD1 -eq 1}}
    @{Name='Recover1';Commands=@(@{Control='ModelHydraulicFault1';Value=0});Timeout=30;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_1_BAR -gt 200 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 200}}
    @{Name='Fault2';Commands=@(@{Control='ModelHydraulicFault2';Value=1});Timeout=20;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_2_BAR -lt 93 -and $sample.parameters.AMXDENIS_HYD_1_BAR -gt 200 -and $sample.parameters.L_HYD2 -eq 1}}
    @{Name='TotalLoss';Commands=@(@{Control='ModelHydraulicFault1';Value=1});Timeout=20;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_1_BAR -lt 93 -and $sample.parameters.AMXDENIS_HYD_2_BAR -lt 93 -and $sample.parameters.L_HYD1 -eq 1 -and $sample.parameters.L_HYD2 -eq 1}}
    @{Name='Recover2';Commands=@(@{Control='ModelHydraulicFault2';Value=0});Timeout=30;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_2_BAR -gt 200 -and $sample.parameters.AMXDENIS_HYD_1_BAR -lt 93}}
    @{Name='RestoreAll';Commands=@(@{Control='ModelHydraulicFault1';Value=0});Timeout=30;Condition={param($sample)
        $sample.parameters.AMXDENIS_HYD_1_BAR -gt 206 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 206}}
    @{Name='AirbrakeOut';Commands=@(@{Control='Airbrake';Value=1});Timeout=15;Condition={param($sample)
        $sample.parameters.AMXDENIS_AIRBRAKE_MOVING -eq 1 -and $sample.parameters.AMXDENIS_HYD_2_BAR -lt 206 -and $sample.parameters.AMXDENIS_HYD_1_BAR -gt 206}}
    @{Name='AirbrakeOutSettled';Commands=@();Timeout=15;Condition={param($sample)
        $sample.parameters.AMXDENIS_AIRBRAKE_POSITION -gt 0.95 -and $sample.parameters.AMXDENIS_AIRBRAKE_MOVING -eq 0 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 206}}
    @{Name='AirbrakeIn';Commands=@(@{Control='Airbrake';Value=0});Timeout=15;Condition={param($sample)
        $sample.parameters.AMXDENIS_AIRBRAKE_MOVING -eq 1 -and $sample.parameters.AMXDENIS_HYD_2_BAR -lt 206 -and $sample.parameters.AMXDENIS_HYD_1_BAR -gt 206}}
    @{Name='AirbrakeInSettled';Commands=@();Timeout=15;Condition={param($sample)
        $sample.parameters.AMXDENIS_AIRBRAKE_POSITION -lt 0.05 -and $sample.parameters.AMXDENIS_AIRBRAKE_MOVING -eq 0 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 206}}
    @{Name='Shutdown';Commands=@(@{Control='FuelShutoff';Value=0});Timeout=100;Condition={param($sample)
        $sample.engine.RPM.left -lt 0.1 -and $sample.parameters.AMXDENIS_HYD_1_BAR -gt 0 -and $sample.parameters.AMXDENIS_HYD_1_BAR -lt 200 -and $sample.parameters.AMXDENIS_HYD_2_BAR -gt 0}}
    @{Name='ReserveLow';Commands=@();Timeout=90;Condition={param($sample)
        $sample.engine.RPM.left -lt 0.1 -and $sample.parameters.AMXDENIS_HYD_1_BAR -le 93 -and $sample.parameters.AMXDENIS_HYD_2_BAR -le 93 -and $sample.parameters.L_HYD1 -eq 1 -and $sample.parameters.L_HYD2 -eq 1}}
    @{Name='PowerOff';Commands=@(@{Control='Master';Value=0},@{Control='Battery';Value=0});Timeout=10;Condition={param($sample)
        $sample.parameters.ELEC_P1 -eq 0 -and $sample.engine.RPM.left -lt 0.1}}
}

$stages=@(Get-HydraulicStages)
if($AirbrakeSource -eq 'Native'){
    $stages[9].Commands=@(@{Control='NativeAirbrakeOn';Value=1})
    $stages[10].Commands=@(@{Control='NativeAirbrakeOff';Value=1})
}
if($Describe){return $stages}
if(-not $RunRoot){throw 'An owned native hydraulic test run is required.'}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or $state.StartMode -ne 'GroundCold' -or
    -not $state.OperationalTest -or -not $state.HardwareIsolationRequested){throw 'Hydraulic sequence requires an operational isolated cold ground fixture.'}
$reportPath=Resolve-IntegrationFile $run 'hydraulic-sequence.json'
if(Test-Path -LiteralPath $reportPath){throw 'Hydraulic sequence report already exists.'}
$results=[Collections.Generic.List[object]]::new()
$failure=$null
try {
    for($index=0;$index -lt $stages.Count;$index++){
        $stage=$stages[$index]
        $before=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
        Assert-HydraulicStationary $before
        if($before.parameters.AMXDENIS_HYDRAULICS_DYNAMIC -ne 1 -or $before.parameters.AMXDENIS_HYDRAULICS_CALIBRATED -ne 0){throw 'Expected explicit uncalibrated hydraulic project model is not loaded.'}
        $reportName=('hydraulic-{0:D2}-{1}.json' -f ($index+1),$stage.Name)
        $entry=[ordered]@{Stage=$stage.Name;Passed=$false;Condition=$stage.Condition.ToString();Before=$before;After=$null;Report=$reportName;SHA256=$null;Error=$null}
        try {
            foreach($command in $stage.Commands){
                Assert-HydraulicStationary (& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run)
                if($command.ContainsKey('ScanCode')){
                    $key=@{RunRoot=$run;Action='ScanKey';ScanCode=$command.ScanCode}
                    foreach($modifier in @('Shift','Control')){if($command.ContainsKey($modifier)){$key[$modifier]=$true}}
                    & (Join-Path $PSScriptRoot 'Window.ps1') @key | Write-Host
                }else{
                    $arguments=@{RunRoot=$run;Control=$command.Control;Value=$command.Value;ReportName=('hydraulic-{0:D2}-command-{1}.json' -f ($index+1),$command.Control)}
                    if($command.ContainsKey('Release')){$arguments.Release=$true}
                    $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') @arguments
                }
            }
            $expected=$stage.Condition
            $stationary=${function:Assert-HydraulicStationary}
            $condition={param($sample)
                & $stationary $sample
                if($sample.parameters.AMXDENIS_HYD_1_VALID -ne 1 -or $sample.parameters.AMXDENIS_HYD_2_VALID -ne 1){return $false}
                return [bool](& $expected $sample)
            }.GetNewClosure()
            $after=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $condition -AfterModelTime $before.model_time -TimeoutSeconds $stage.Timeout -ReportName $reportName
            $entry.After=$after
            $entry.Passed=$true
            Write-Host ('HYDRAULIC_STAGE_OK|'+$stage.Name+'|P1='+$after.parameters.AMXDENIS_HYD_1_BAR+'|P2='+$after.parameters.AMXDENIS_HYD_2_BAR)
        } catch {
            $entry.Error=$_.Exception.Message
            if($stage.Name -notin @('AirbrakeOut','AirbrakeIn') -or $entry.Error -ne 'Native condition was not observed in time; raw evidence retained.'){throw}
            if($null -eq $failure){$failure=$stage.Name+': '+$entry.Error}
            $entry.After=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
            Write-Host ('HYDRAULIC_CONSUMER_FAILED|'+$stage.Name+'|continuing_to_safe_shutdown')
        } finally {
            $path=Join-Path $run $reportName
            if(Test-Path -LiteralPath $path){$entry.SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
            $results.Add($entry)
        }
    }
} catch {if($null -eq $failure){$failure=$_.Exception.Message};throw} finally {
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_HYDRAULIC_SEQUENCE_1';Run=$state.ProfileName;BuildId=$state.BuildId;
        Passed=($null -eq $failure -and $results.Count -eq $stages.Count);Stages=$results.ToArray();PlannedStages=$stages.Count;Failure=$failure;
        Scope='Uncalibrated project pressure model, explicit model faults and observed native consumer movement';PhysicalHydraulicsApproval=$false;
        FullKeyboardApproval=$false;AirbrakeSource=$AirbrakeSource;InputSource='Diagnostic cockpit/native commands; model faults separately logged; airbrake source explicit';RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
    if($failure){throw ('Hydraulic sequence incomplete: '+$failure)}