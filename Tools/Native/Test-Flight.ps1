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
# The first landing touched down at sea level twenty six kilometres beyond the field
# because the aircraft simply flew straight out, so the runway frame is recorded at
# the start and every later stage is steered relative to it.
$global:FlightOrigin=$null
$global:FlightRunwayHeading=0.0
$global:FlightRollSign=1
$global:FlightBankSign=1
$global:FlightProbeHeading=0.0
$global:FlightProbeBank=0.0
$global:FlightCircuitArmed=$false
$global:FlightApproachHeight=850.0
function Get-FlightAngleError([double]$Command,[double]$Actual) {
    $error=$Command-$Actual
    while($error -gt [Math]::PI){$error-=2*[Math]::PI}
    while($error -lt -[Math]::PI){$error+=2*[Math]::PI}
    return $error
}
function Get-FlightTrack($Sample) {
    $x=[double](Get-FlightValue $Sample 'own_position.x')
    $z=[double](Get-FlightValue $Sample 'own_position.z')
    $north=$x-$global:FlightOrigin.x;$east=$z-$global:FlightOrigin.z
    $cosine=[Math]::Cos($global:FlightRunwayHeading);$sine=[Math]::Sin($global:FlightRunwayHeading)
    return [pscustomobject]@{Along=$north*$cosine+$east*$sine;Cross=-$north*$sine+$east*$cosine
        Height=[double](Get-FlightValue $Sample 'own_position.y')-[double]$global:FlightOrigin.y}
}
function Get-FlightRollDemand($Sample,[double]$CommandedHeading) {
    $heading=[double](Get-FlightValue $Sample 'own_heading')
    $bank=[double](Get-FlightValue $Sample 'attitude.bank_rad')*$global:FlightBankSign
    # The roll axis is a rate command served by a loop that only runs about once a
    # second, so a stiff law drove the bank to eighty degrees and bled the altitude away.
    $demand=[Math]::Max(-0.45,[Math]::Min(0.45,0.8*(Get-FlightAngleError $CommandedHeading $heading)))
    return [Math]::Round([Math]::Max(-0.3,[Math]::Min(0.3,0.7*($demand-$bank)))*$global:FlightRollSign,2)
}
function Get-FlightPitchDemand($Sample,[double]$TargetRate) {
    $agl=[double](Get-FlightValue $Sample 'agl')
    $rate=[double](Get-FlightValue $Sample 'velocity.y')
    $speed=[double](Get-FlightValue $Sample 'ias')
    $attitude=[double](Get-FlightValue $Sample 'attitude.pitch_rad')
    # A gain of one hundredth could only reach five metres per second of descent, so a
    # four hundred metre height error was never recovered on the approach.
    $pitch=0.02+0.020*($TargetRate-$rate)-0.25*($attitude+0.05)
    if($speed -lt 80){$pitch=[Math]::Min($pitch,0.02)}
    if($speed -lt 74){$pitch=[Math]::Min($pitch,-0.06)}
    return [Math]::Round([Math]::Max(-0.25,[Math]::Min(0.20,$pitch)),3)
}
function Get-FlightThrustDemand($Sample,[double]$TargetSpeed) {
    $speed=[double](Get-FlightValue $Sample 'ias')
    $throttle=0.4+0.05*($speed-$TargetSpeed)
    if($speed -lt ($TargetSpeed-4)){$throttle=-0.6}
    # Integer literals here made the overload resolver truncate the limit to zero, so
    # every bound in this file is written as a double on purpose.
    return [Math]::Round([Math]::Max(-0.6,[Math]::Min(1.0,$throttle)),2)
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
        # The roll axis sense is measured instead of assumed, because the thrust and
        # pitch axes both turned out to be inverted from the obvious reading. It is a
        # rate command: a fixed deflection kept rolling between loop iterations and dived
        # the aircraft into the ground at sixty metres per second, so the probe stops
        # itself at the first measurable bank and the sense is then read from a held one.
        @{Name='RollProbe';Commands=@(@{Control='FlightCancel';Value=1});Timeout=90;StableSamples=3;Seed=@{FlightPitch=0.0;FlightThrottle=0.4;FlightRoll=0.0};
            Guidance={param($s,$sent)
                $bank=[Math]::Abs([double](Get-FlightValue $s 'attitude.bank_rad'))
                @{FlightRoll=$(if($bank -lt 0.12){0.12}else{0.0})
                  FlightPitch=Get-FlightPitchDemand $s 2.0;FlightThrottle=Get-FlightThrustDemand $s 140}}
            Condition={param($s)
                (Test-FlightNumber (Get-FlightValue $s 'attitude.bank_rad') -1.5 1.5) -and
                [Math]::Abs((Get-FlightValue $s 'attitude.bank_rad')) -gt 0.12}}
        @{Name='RollSense';Commands=@();Timeout=180;StableSamples=70;Seed=@{FlightPitch=0.0;FlightThrottle=0.4;FlightRoll=0.12};
            Guidance={param($s,$sent)
                $bank=[double](Get-FlightValue $s 'attitude.bank_rad')
                $sense=if($global:FlightProbeBank -ge 0){1}else{-1}
                $target=0.25*$sense
                @{FlightRoll=[Math]::Round([Math]::Max(-0.3,[Math]::Min(0.3,0.7*($target-$bank)*$sense)),3)
                  FlightPitch=Get-FlightPitchDemand $s 2.0;FlightThrottle=Get-FlightThrustDemand $s 140}}
            Condition={param($s)
                # A bank bound here kept resetting the dwell, so the window only needs a
                # safe height and a readable heading.
                (Test-FlightNumber (Get-FlightValue $s 'agl') 120 20000) -and
                (Test-FlightNumber (Get-FlightValue $s 'own_heading') -10 10)}}
        # Landing back on the departure runway needs the reciprocal direction, so the
        # circuit continues seaward, turns around and intercepts the extended centreline.
        @{Name='Circuit';Commands=@();Timeout=600;StableSamples=3;Seed=@{FlightPitch=0.0;FlightThrottle=0.4;FlightRoll=0.0};
            Guidance={param($s,$sent)
                $track=Get-FlightTrack $s
                $landing=$global:FlightRunwayHeading+[Math]::PI
                # Without a latch the aircraft turned outbound again as soon as it came
                # back inside the entry point, so the outbound leg is armed only once.
                if($track.Along -gt 22000){$global:FlightCircuitArmed=$true}
                $heading=if($global:FlightCircuitArmed){
                    $landing+[Math]::Max(-0.7,[Math]::Min(0.7,0.0004*$track.Cross))
                } else {
                    $global:FlightRunwayHeading+[Math]::Atan2(6000.0-$track.Cross,26000.0-$track.Along)
                }
                $targetRate=[Math]::Max(-12.0,[Math]::Min(8.0,0.06*(900.0-$track.Height)))
                @{FlightRoll=Get-FlightRollDemand $s $heading
                  FlightPitch=Get-FlightPitchDemand $s $targetRate
                  FlightThrottle=Get-FlightThrustDemand $s 100}}
            Condition={param($s)
                (Test-FlightNumber (Get-FlightValue $s 'own_position.x') -1000000 1000000) -and
                (Test-FlightNumber (Get-FlightValue $s 'own_heading') -10 10) -and
                $global:FlightCircuitArmed -and
                $($track=Get-FlightTrack $s
                  $track.Along -gt 12000 -and $track.Along -lt 40000 -and [Math]::Abs($track.Cross) -lt 1200 -and
                  [Math]::Abs((Get-FlightAngleError ($global:FlightRunwayHeading+[Math]::PI) (Get-FlightValue $s 'own_heading'))) -lt 0.25)}}
        # Leaving these two as open waits stopped the closed loop for ten seconds and the
        # aircraft dived; leaving the roll rate command applied between stages rolled it
        # over and drove it into the ground at sixty eight metres per second.
        @{Name='GearDown';Commands=@(@{Control='Gear';Value=1});Timeout=60;StableSamples=3;Seed=@{FlightPitch=0.0;FlightThrottle=0.4;FlightRoll=0.0};
            Guidance={param($s,$sent)
                $track=Get-FlightTrack $s
                $heading=$global:FlightRunwayHeading+[Math]::PI+[Math]::Max(-0.35,[Math]::Min(0.35,0.0012*$track.Cross))
                @{FlightRoll=Get-FlightRollDemand $s $heading
                  FlightPitch=Get-FlightPitchDemand $s ([Math]::Max(-6.0,[Math]::Min(6.0,0.06*($global:FlightApproachHeight-$track.Height))))
                  FlightThrottle=Get-FlightThrustDemand $s 95}}
            Condition={param($s)
                (Test-FlightNumber (Get-FlightValue $s 'external_arguments.0') 0 1) -and (Get-FlightValue $s 'external_arguments.0') -gt 0.9}}
        @{Name='FlapsApproach';Commands=@(@{Control='Flaps';Value=1});Timeout=60;StableSamples=3;Seed=@{FlightPitch=0.0;FlightThrottle=0.4;FlightRoll=0.0};
            Guidance={param($s,$sent)
                $track=Get-FlightTrack $s
                $heading=$global:FlightRunwayHeading+[Math]::PI+[Math]::Max(-0.35,[Math]::Min(0.35,0.0012*$track.Cross))
                @{FlightRoll=Get-FlightRollDemand $s $heading
                  FlightPitch=Get-FlightPitchDemand $s ([Math]::Max(-6.0,[Math]::Min(6.0,0.06*($global:FlightApproachHeight-$track.Height))))
                  FlightThrottle=Get-FlightThrustDemand $s 90}}
            Condition={param($s)
                (Test-FlightNumber (Get-FlightValue $s 'external_arguments.9') 0 1) -and (Get-FlightValue $s 'external_arguments.9') -gt 0.9}}
        # Fixed commands destroyed the aircraft twice: an idle flare from six metres
        # stalled it at twenty five metres per second. An incremental law then wound up
        # into a forty metre per second phugoid, and a narrow nose down limit let the
        # aircraft zoom, stall and depart at minus fifty five metres per second. The law
        # is now proportional, damped by the pitch attitude, given real nose down
        # authority and overridden by speed protection.
        @{Name='Autoland';Commands=@();Timeout=600;StableSamples=3;Seed=@{FlightPitch=0.02;FlightThrottle=0.4;FlightRoll=0.0};
            Guidance={param($s,$sent)
                $track=Get-FlightTrack $s
                $agl=[double](Get-FlightValue $s 'agl')
                $speed=[double](Get-FlightValue $s 'ias')
                # Aiming at the threshold made the slope reach the ground before the
                # pavement and the aircraft was destroyed, so it aims inside the runway
                # and accepts the float, which stopped the aircraft intact.
                $remaining=$track.Along-1500
                $landing=$global:FlightRunwayHeading+[Math]::PI
                $heading=$landing+[Math]::Max(-0.35,[Math]::Min(0.35,0.0012*$track.Cross))
                # Triggering the flare on distance alone levelled the aircraft at two
                # hundred and seventy metres and it flew past the field, so the round out
                # is commanded by height and the slope is followed until then.
                $targetRate=if($agl -lt 12){-0.7}elseif($agl -lt 40){-1.6}else{
                    $glide=[Math]::Min(900.0,0.0524*$remaining)
                    [Math]::Max(-10.0,[Math]::Min(4.0,-0.0524*$speed+0.05*($glide-$track.Height)))}
                @{FlightRoll=Get-FlightRollDemand $s $heading
                  FlightPitch=Get-FlightPitchDemand $s $targetRate
                  FlightThrottle=Get-FlightThrustDemand $s $(if($agl -gt 40){88}else{80})}}
            Condition={param($s)
                (Get-FlightValue $s 'parameters.BASE_SENSOR_WOW_LEFT_GEAR') -eq 1 -and
                (Test-FlightNumber (Get-FlightValue $s 'agl') 0 30) -and (Get-FlightValue $s 'agl') -lt 6}}
        @{Name='Rollout';Commands=@(@{Control='FlightBrake';Value=1},@{Control='FlightPitch';Value=0});Timeout=120;Condition={param($s)
            (Get-FlightValue $s 'parameters.BASE_SENSOR_WOW_LEFT_GEAR') -eq 1 -and
            (Test-FlightNumber (Get-FlightValue $s 'ias') 0 400) -and (Get-FlightValue $s 'ias') -lt 5}}
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
        if($null -eq $global:FlightOrigin){
            if($null -eq (Get-FlightValue $before 'own_position.x') -or $null -eq (Get-FlightValue $before 'own_heading')){
                throw 'The runway frame needs the observed position and heading.'
            }
            $global:FlightOrigin=$before.own_position
            $global:FlightRunwayHeading=[double]$before.own_heading
        }
        foreach($command in $stage.Commands){
            $null=& (Join-Path $PSScriptRoot 'Invoke-Diagnostic.ps1') -RunRoot $run -Control $command.Control -Value $command.Value -ReportName ('flight-'+$stage.Name+'-'+$command.Control+'.json')
        }
        $row=[ordered]@{Stage=$stage.Name;BeforeModelTime=$before.model_time;Reached=$false;Error=$null;
            Ias=$null;Agl=$null;GearArgument=$null;FlapArgument=$null;PitchRad=$null;Along=$null;Cross=$null;Height=$null;Note=$null}
        try {
            $samples=if($stage.PSObject.Properties['StableSamples']){$stage.StableSamples}else{3}
            $after=if($stage.PSObject.Properties['Guidance']){
                & (Join-Path $PSScriptRoot 'Invoke-Guided.ps1') -RunRoot $run -Guidance $stage.Guidance -Condition $stage.Condition -Seed $stage.Seed -AfterModelTime $before.model_time -TimeoutSeconds $stage.Timeout -StableSamples $samples -ReportName ('flight-guided-'+$stage.Name+'.json')
            } else {
                & (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $stage.Condition -AfterModelTime $before.model_time -TimeoutSeconds $stage.Timeout -StableSamples $samples -ReportName ('flight-wait-'+$stage.Name+'.json')
            }
            $row.Reached=$true
            $row.Ias=Get-FlightValue $after 'ias';$row.Agl=Get-FlightValue $after 'agl'
            $row.GearArgument=Get-FlightValue $after 'external_arguments.0'
            $row.FlapArgument=Get-FlightValue $after 'external_arguments.9'
            $row.PitchRad=Get-FlightValue $after 'attitude.pitch_rad'
            $track=Get-FlightTrack $after
            $row.Along=$track.Along;$row.Cross=$track.Cross;$row.Height=$track.Height
            if($stage.Name -eq 'Circuit'){$global:FlightApproachHeight=$track.Height}
            if($stage.Name -eq 'RollProbe'){
                $global:FlightProbeHeading=[double](Get-FlightValue $before 'own_heading')
                $global:FlightProbeBank=[double](Get-FlightValue $after 'attitude.bank_rad')
            }
            if($stage.Name -eq 'RollSense'){
                $bank=[double](Get-FlightValue $after 'attitude.bank_rad')
                $turn=Get-FlightAngleError ([double](Get-FlightValue $after 'own_heading')) $global:FlightProbeHeading
                # A six second sample produced a turn of one degree and the sign was
                # noise; a forty second hold wrapped past half a circle and inverted it.
                if([Math]::Abs($turn) -lt 0.08 -or [Math]::Abs($turn) -gt 2.0){throw 'The roll axis did not change the measured heading.'}
                $global:FlightRollSign=if($turn -ge 0){1}else{-1}
                $global:FlightBankSign=if(($bank -ge 0) -eq ($turn -ge 0)){1}else{-1}
                $row.Note="roll_sign=$global:FlightRollSign;bank_sign=$global:FlightBankSign;turn_rad=$([Math]::Round($turn,4))"
            }
        } catch {$row.Error=$_.Exception.Message;throw} finally {$records.Add([pscustomobject]$row)}
        Write-Host ("FLIGHT_STAGE_OK|{0}|ias={1}|agl={2}" -f $stage.Name,$row.Ias,$row.Agl)
    }
} catch {$failure=$_.Exception.Message} finally {
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_FLIGHT_1';Run=$state.ProfileName;BuildId=$state.BuildId;
        Planned=$plan.Count;Attempted=$records.Count;Reached=@($records | Where-Object Reached).Count;
        Stages=$records.ToArray();Failure=$failure;
        RunwayFrame=[ordered]@{Origin=$global:FlightOrigin;HeadingRad=$global:FlightRunwayHeading;
            RollSign=$global:FlightRollSign;BankSign=$global:FlightBankSign};
        SequenceCompleted=($records.Count -eq $plan.Count -and -not $failure);
        NativeAcceptanceGranted=$false;
        Scope='Scripted flight axes on a private runway fixture; not physical HOTAS input';
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}
if($failure){throw $failure}
Write-Output ("AMXDENIS_FLIGHT|reached={0}/{1}|{2}" -f @($records | Where-Object Reached).Count,$plan.Count,$reportPath)
