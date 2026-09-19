[CmdletBinding()]
param([string]$RunRoot,[switch]$Describe)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-FlightValue($Sample,[string]$Path) {
    $value=$Sample
    foreach($part in $Path.Split('.')){
        if($null -eq $value -or -not $value.PSObject.Properties[$part]){return $null}
        $value=$value.$part
    }
    return $value
}
function Test-FlightNumber($Value,[double]$Minimum,[double]$Maximum) {
    if($null -eq $Value -or $Value -is [string] -or $Value -is [bool]){return $false}
    if([double]::IsNaN($Value) -or [double]::IsInfinity($Value)){return $false}
    return [bool]($Value -ge $Minimum -and $Value -le $Maximum)
}
function Get-FlightStages {
    # V_take_off 65 m/s and AOA_take_off 0.16 rad are declared in Entry/AMXT_M.lua.
    @(
        # The thrust axis is inverted: measured 0.3 gave 74 RPM and 1.0 gave idle 60 RPM.
        @{Name='Roll';Commands=@(@{Control='FlightThrottle';Value=-1},@{Control='FlightBrake';Value=0});Timeout=60;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'ias') 20 400) -and (Get-FlightValue $s 'ias') -gt 20}}
        @{Name='Rotate';Commands=@();Timeout=90;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'ias') 0 400) -and (Get-FlightValue $s 'ias') -ge 65}}
        # A negative pitch axis pushed the nose down and the aircraft overran the runway.
        # A negative pitch axis pushed the nose down and the aircraft overran the runway.
        @{Name='Airborne';Commands=@(@{Control='FlightPitch';Value=0.5});Timeout=60;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'agl') 0 20000) -and (Get-FlightValue $s 'agl') -gt 30}}
        # Holding 0.5 bled the speed below stall, so the climb attitude is reduced early.
        @{Name='ClimbAttitude';Commands=@(@{Control='FlightPitch';Value=0.12});Timeout=40;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'agl') 0 20000) -and (Get-FlightValue $s 'agl') -gt 120 -and
            (Test-FlightNumber (Get-FlightValue $s 'ias') 0 400) -and (Get-FlightValue $s 'ias') -gt 80}}
        @{Name='GearUp';Commands=@(@{Control='Gear';Value=0});Timeout=40;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'external_arguments.0') 0 1) -and (Get-FlightValue $s 'external_arguments.0') -lt 0.1}}
        @{Name='Climb';Commands=@();Timeout=120;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'agl') 0 20000) -and (Get-FlightValue $s 'agl') -gt 400 -and
            (Test-FlightNumber (Get-FlightValue $s 'ias') 0 400) -and (Get-FlightValue $s 'ias') -gt 80}}
        @{Name='Level';Commands=@(@{Control='FlightPitch';Value=0},@{Control='FlightAltitudeHold';Value=1});Timeout=60;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'velocity.y') -200 200) -and
            [Math]::Abs((Get-FlightValue $s 'velocity.y')) -lt 8 -and (Get-FlightValue $s 'agl') -gt 250}}
        @{Name='Cruise';Commands=@();Timeout=90;StableSamples=25;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'agl') 200 20000) -and
            (Test-FlightNumber (Get-FlightValue $s 'ias') 80 400) -and
            [Math]::Abs((Get-FlightValue $s 'velocity.y')) -lt 10}}
        @{Name='GearDown';Commands=@(@{Control='Gear';Value=1});Timeout=40;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'external_arguments.0') 0 1) -and (Get-FlightValue $s 'external_arguments.0') -gt 0.9}}
        @{Name='FlapsApproach';Commands=@(@{Control='Flaps';Value=1});Timeout=40;Condition={param($s)
            (Test-FlightNumber (Get-FlightValue $s 'external_arguments.9') 0 1) -and (Get-FlightValue $s 'external_arguments.9') -gt 0.9}}
    ) | ForEach-Object {[pscustomobject]$_}
}
if($Describe){Get-FlightStages;return}
if(-not $RunRoot){throw 'RunRoot is required for a native flight test.'}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or $state.StartMode -ne 'RunwayHot' -or
    -not $state.OperationalTest){throw 'Flight test requires an operational runway fixture.'}
$reportPath=Resolve-IntegrationFile $run 'flight-results.json'
if(Test-Path -LiteralPath $reportPath){throw 'Flight report already exists.'}
$plan=@(Get-FlightStages)
$records=[Collections.Generic.List[object]]::new()
$failure=$null
try {
    foreach($stage in $plan){
        $before=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
        foreach($command in $stage.Commands){
            $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') -RunRoot $run -Control $command.Control -Value $command.Value -ReportName ('flight-'+$stage.Name+'-'+$command.Control+'.json')
        }
        $row=[ordered]@{Stage=$stage.Name;BeforeModelTime=$before.model_time;Reached=$false;Error=$null;
            Ias=$null;Agl=$null;GearArgument=$null;FlapArgument=$null;PitchRad=$null}
        try {
            $samples=if($stage.PSObject.Properties['StableSamples']){$stage.StableSamples}else{3}
            $after=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $stage.Condition -AfterModelTime $before.model_time -TimeoutSeconds $stage.Timeout -StableSamples $samples -ReportName ('flight-wait-'+$stage.Name+'.json')
            $row.Reached=$true
            $row.Ias=Get-FlightValue $after 'ias';$row.Agl=Get-FlightValue $after 'agl'
            $row.GearArgument=Get-FlightValue $after 'external_arguments.0'
            $row.FlapArgument=Get-FlightValue $after 'external_arguments.9'
            $row.PitchRad=Get-FlightValue $after 'attitude.pitch_rad'
        } catch {$row.Error=$_.Exception.Message;throw} finally {$records.Add([pscustomobject]$row)}
        Write-Host ("FLIGHT_STAGE_OK|{0}|ias={1}|agl={2}" -f $stage.Name,$row.Ias,$row.Agl)
    }
} catch {$failure=$_.Exception.Message} finally {
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_FLIGHT_1';Run=$state.ProfileName;BuildId=$state.BuildId;
        Planned=$plan.Count;Attempted=$records.Count;Reached=@($records | Where-Object Reached).Count;
        Stages=$records.ToArray();Failure=$failure;
        SequenceCompleted=($records.Count -eq $plan.Count -and -not $failure);
        NativeAcceptanceGranted=$false;
        Scope='Scripted flight axes on a private runway fixture; not physical HOTAS input and not a landing';
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
if($failure){throw $failure}
Write-Output ("AMXDENIS_FLIGHT|reached={0}/{1}|{2}" -f @($records | Where-Object Reached).Count,$plan.Count,$reportPath)
