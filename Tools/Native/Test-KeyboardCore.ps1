[CmdletBinding()]
param(
    [string]$RunRoot,
    [string]$ReportName='keyboard-core.json',
    [ValidateSet('Core','Navigation')][string]$Suite='Core',
    [ValidateRange(1,3)][int]$Cycles=1,
    [switch]$Describe
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-KeyboardCoreCases {
    @(
        @{Control='Battery';Value=1;Expected=@{T_BATT=1;ELEC_P1=1}}
        @{Control='Master';Value=1;Expected=@{AMX_AVIONICS_MASTER=1;CMFD1On=1;CMFD2On=1}}
        @{Control='Mfd1Power';Value=0;Expected=@{CMFD1On=0;CMFD2On=1}}
        @{Control='Mfd1Power';Value=1;Expected=@{CMFD1On=1;CMFD2On=1}}
        @{Control='Mfd2Power';Value=0;Expected=@{CMFD1On=1;CMFD2On=0}}
        @{Control='Mfd2Power';Value=1;Expected=@{CMFD1On=1;CMFD2On=1}}
        @{Control='Mfd1Brightness';Value=-1;Expected=@{CMFD1_BRIGHT=0.5;CMFD2_BRIGHT=1}}
        @{Control='Mfd1Brightness';Value=1;Expected=@{CMFD1_BRIGHT=1;CMFD2_BRIGHT=1}}
        @{Control='Mfd2Brightness';Value=-1;Expected=@{CMFD1_BRIGHT=1;CMFD2_BRIGHT=0.5}}
        @{Control='Mfd2Brightness';Value=1;Expected=@{CMFD1_BRIGHT=1;CMFD2_BRIGHT=1}}
        @{Control='HudBrightness';Value=0.25;Expected=@{AMX_HUD_DIMMER=0.25}}
        @{Control='HudBrightness';Value=0;Expected=@{AMX_HUD_DIMMER=0}}
        @{Control='HudBrightness';Value=1;Expected=@{AMX_HUD_DIMMER=1}}
        @{Control='IcpBrightness';Value=0.5;Expected=@{AMX_UFCP_BRIGHT=0.5}}
        @{Control='IcpBrightness';Value=0;Expected=@{AMX_UFCP_BRIGHT=0}}
        @{Control='IcpBrightness';Value=1;Expected=@{AMX_UFCP_BRIGHT=1}}
        @{Control='IcpDayNight';Value=-1;Expected=@{AMX_HUD_MODE=-1}}
        @{Control='IcpDayNight';Value=1;Expected=@{AMX_HUD_MODE=1}}
        @{Control='IcpDayNight';Value=0;Expected=@{AMX_HUD_MODE=0}}
        @{Control='IcpRadarAltimeter';Value=1;Expected=@{UFCP_RALT_SWITCH_STATE=1}}
        @{Control='IcpRadarAltimeter';Value=0;Expected=@{UFCP_RALT_SWITCH_STATE=0}}
        @{Control='IcpCOM1';Value=1;Expected=@{AMX_ICP_FORMAT=1}}
        @{Control='IcpCOM1';Value=1;Expected=@{AMX_ICP_FORMAT=0}}
        @{Control='IcpCOM2';Value=1;Expected=@{AMX_ICP_FORMAT=2}}
        @{Control='IcpCOM2';Value=1;Expected=@{AMX_ICP_FORMAT=0}}
        @{Control='SmsPower';Value=1;Expected=@{AMX_SMS_MASTER=1}}
        @{Control='SmsPower';Value=0;Expected=@{AMX_SMS_MASTER=0}}
        @{Control='Master';Value=0;Expected=@{AMX_AVIONICS_MASTER=0;CMFD1On=0;CMFD2On=0}}
        @{Control='Master';Value=1;Expected=@{AMX_AVIONICS_MASTER=1;CMFD1On=1;CMFD2On=1}}
        @{Control='Master';Value=0;Expected=@{AMX_AVIONICS_MASTER=0;CMFD1On=0;CMFD2On=0}}
        @{Control='Battery';Value=0;Expected=@{T_BATT=0;ELEC_P1=0}}
    )
}

function Get-KeyboardNavigationCases {
    @{Control='Battery';Value=1;Expected=@{T_BATT=1;ELEC_P1=1}}
    @{Control='Master';Value=1;Expected=@{AMX_AVIONICS_MASTER=1;CMFD1On=1;CMFD2On=1}}
    foreach($entry in @(@('Mode',2,24),@('Mode',3,3),@('Mode',3,4),@('Mode',4,5),@('Mode',4,6),@('Mode',1,2),
        @('IcpA_G',1,24),@('IcpNAV',1,2),@('IcpA_A',1,5),@('IcpNAV',1,2))){
        @{Control=$entry[0];Value=$entry[1];Expected=@{AVIONICS_MASTER_MODE=$entry[2]}}
    }
    @{Control='IcpNAVAIDS';Value=1;Expected=@{AMX_ICP_FORMAT=4}}
    @{Control='IcpNAVAIDS';Value=1;Expected=@{AMX_ICP_FORMAT=0}}
    @{Control='IcpJOY_RIGHT';Value=1;Expected=@{AMX_ICP_FORMAT=13}}
    @{Control='IcpENTR';Value=1;Expected=@{AMX_ICP_FORMAT=28}}
    foreach($digits in @('0125','0345','0675','0895','1595','0140')){
        for($index=0;$index -lt $digits.Length;$index++){
            $expected=@{AMX_ICP_FORMAT=28;AMX_ICP_EDIT_INVALID=0;AMX_ICP_EDIT_POS=$index+1}
            if($index -eq 3){
                $expected.AMX_ICP_EDIT_POS=0
                $expected.UFCP_FUEL_BINGO=[int]$digits
                $expected.AMX_FUEL_BINGO_VALID=1
                $expected.AMX_FUEL_BINGO_ACTIVE=[int]($digits -eq '1595')
            }
            @{Control=('Icp'+$digits[$index]);Value=1;Expected=$expected}
        }
    }
    foreach($position in 1..4){
        @{Control='Icp9';Value=1;Expected=@{AMX_ICP_EDIT_POS=$position;AMX_ICP_EDIT_INVALID=[int]($position -eq 4);UFCP_FUEL_BINGO=140;AMX_FUEL_BINGO_ACTIVE=0}}
    }
    @{Control='IcpCLR';Value=1;Expected=@{AMX_ICP_EDIT_POS=0;AMX_ICP_EDIT_INVALID=0;UFCP_FUEL_BINGO=140}}
    @{Control='Icp0';Value=1;Expected=@{AMX_ICP_EDIT_POS=1;UFCP_FUEL_BINGO=140}}
    @{Control='Icp6';Value=1;Expected=@{AMX_ICP_EDIT_POS=2;UFCP_FUEL_BINGO=140}}
    @{Control='IcpCLR';Value=1;Expected=@{AMX_ICP_EDIT_POS=1;UFCP_FUEL_BINGO=140}}
    @{Control='IcpCLR';Value=1;Expected=@{AMX_ICP_EDIT_POS=0;UFCP_FUEL_BINGO=140}}
    foreach($entry in @(@('6',1),@('7',2),@('5',3))){
        @{Control=('Icp'+$entry[0]);Value=1;Expected=@{AMX_ICP_EDIT_POS=$entry[1];AMX_ICP_EDIT_INVALID=0;UFCP_FUEL_BINGO=140}}
    }
    @{Control='IcpENTR';Value=1;Expected=@{AMX_ICP_EDIT_POS=0;AMX_ICP_EDIT_INVALID=0;UFCP_FUEL_BINGO=675}}
    foreach($entry in @(@('0',1),@('1',2),@('4',3),@('0',0))){
        @{Control=('Icp'+$entry[0]);Value=1;Expected=@{AMX_ICP_EDIT_POS=$entry[1];AMX_ICP_EDIT_INVALID=0;UFCP_FUEL_BINGO=$(if($entry[1] -eq 0){140}else{675})}}
    }
    @{Control='IcpJOY_LEFT';Value=1;Expected=@{AMX_ICP_FORMAT=0}}
    foreach($side in 1..2){
        foreach($page in @(@(10,6),@(23,14),@(24,15),@(26,17),@(14,10),@(21,11),@(11,7),@(12,8))){
            $parameter='CMFD'+$side+'Format'
            @{Control=('Mfd'+$side+'Oss20');Value=1;Expected=@{$parameter=1}}
            @{Control=('Mfd'+$side+'Oss'+$page[0]);Value=1;Expected=@{$parameter=$page[1]}}
        }
    }
    @{Control='Master';Value=0;Expected=@{AMX_AVIONICS_MASTER=0;CMFD1On=0;CMFD2On=0}}
    @{Control='Battery';Value=0;Expected=@{T_BATT=0;ELEC_P1=0}}
}

$cases=if($Suite -eq 'Core'){@(Get-KeyboardCoreCases)}else{@(Get-KeyboardNavigationCases)}
if($Describe){return $cases}
if($Suite -ne 'Core' -and -not $PSBoundParameters.ContainsKey('ReportName')){$ReportName='keyboard-navigation.json'}
if(-not $RunRoot){throw 'A prepared private run is required.'}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.StartMode -ne 'GroundCold' -or $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$'){
    throw 'Core keyboard checks require a new private cold-start fixture.'
}
$reportPath=Resolve-IntegrationFile $run $ReportName
if(Test-Path -LiteralPath $reportPath){throw 'Keyboard suite report already exists.'}
$initial=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
if($initial.parameters.T_BATT -ne 0 -or $initial.parameters.AMX_AVIONICS_MASTER -ne 0 -or
    $initial.parameters.AMX_ICP_FORMAT -ne 0 -or $initial.engine.RPM.left -gt 0.1 -or
    [Math]::Abs($initial.velocity.x) -gt 0.25 -or [Math]::Abs($initial.velocity.z) -gt 0.25){
    throw 'Initial cold and stationary state differs; no suite keys sent.'
}
if($Suite -eq 'Navigation' -and ($state.RequestedFuelKg -ne 1500 -or
    $initial.parameters.UFCP_FUEL_BINGO -ne 140)){
    throw 'Navigation suite requires the documented 1500 kg fixture and initial BINGO 140.'
}
$results=[Collections.Generic.List[object]]::new()
$failure=$null
try {
    for($cycle=1;$cycle -le $Cycles;$cycle++){
        for($index=0;$index -lt $cases.Count;$index++){
            $case=$cases[$index]
            $stepName=('keyboard-{0}-{1:D2}-{2:D3}-{3}.json' -f $Suite.ToLowerInvariant(),$cycle,($index+1),$case.Control)
            $entry=[ordered]@{Cycle=$cycle;Step=$index+1;Control=$case.Control;Value=$case.Value;
                ExpectedParameters=$case.Expected;Report=$stepName;Passed=$false;SHA256=$null}
            try {
                $null=& (Join-Path $PSScriptRoot 'Invoke-Input.ps1') -RunRoot $run -Control $case.Control -Value $case.Value -ExpectedParameters $case.Expected -ReportName $stepName
                $step=Get-Content -LiteralPath (Join-Path $run $stepName) -Raw | ConvertFrom-Json -Depth 40 -DateKind String
                if(-not $step.FunctionalEffectVerified -or $step.StableSamplesConfirmed -ne 3){throw 'Input receipt is not a functional suite pass.'}
                $entry.Passed=$true
                Write-Host ('KEYBOARD_CORE_EFFECT_OK|cycle='+$cycle+'|step='+($index+1)+'|control='+$case.Control)
            } finally {
                $stepPath=Join-Path $run $stepName
                if(Test-Path -LiteralPath $stepPath){$entry.SHA256=(Get-FileHash -LiteralPath $stepPath -Algorithm SHA256).Hash}
                $results.Add($entry)
            }
        }
    }
} catch {$failure=$_.Exception.Message;throw} finally {
    Write-IntegrationJson $reportPath ([ordered]@{Schema='AMXDENIS_KEYBOARD_CORE_1';Suite=$Suite;BuildId=$state.BuildId;
        Run=$state.ProfileName;Passed=($null -eq $failure -and $results.Count -eq $cases.Count*$Cycles);
        InputSource='Windows SendInput; no diagnostic cockpit commands';Cycles=$Cycles;PlannedSteps=$cases.Count*$Cycles;
        CatalogTotal=105;UniqueControls=@($cases.Control | Sort-Object -Unique).Count;Results=$results.ToArray();
        Failure=$failure;FullKeyboardApproval=$false;PhysicalHotasApproval=$false;
        Scope='Selected producer transitions and page selections, not all catalog functions, sensor capabilities, rendered pixels or mechanical actuation';
        RecordedUtc=[DateTime]::UtcNow.ToString('o')})
}