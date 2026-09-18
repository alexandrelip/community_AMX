[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$Control,
    [Parameter(Mandatory)][double]$Value,
    [string]$ReportName,
    [hashtable]$ExpectedParameters,
    [ValidateRange(1,60)][int]$TimeoutSeconds=10,
    [switch]$ResolveOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Test-InputEffect($Before,$After,[hashtable]$Expected) {
    if(-not $Expected -or $Expected.Count -eq 0){return $false}
    foreach($name in $Expected.Keys){
        if($name -notmatch '^[A-Za-z][A-Za-z0-9_]*$' -or $name -match '^AMXDENIS_(INPUT_|CONTROL_)'){
            throw 'Effect checks require producer parameters, not router feedback.'
        }
        $number=$Expected[$name]
        if($null -eq $number -or $number -is [string] -or $number -is [bool] -or
            [double]::IsNaN([double]$number) -or [double]::IsInfinity([double]$number)){
            throw 'Expected producer state must be a finite number.'
        }
    }
    if($After.model_time -le $Before.model_time -or $After.sequence -ne $Before.sequence){return $false}
    $changed=$false
    foreach($name in $Expected.Keys){
        $old=$Before.parameters.PSObject.Properties[$name]
        $new=$After.parameters.PSObject.Properties[$name]
        if($null -eq $old -or $null -eq $new -or $null -eq $old.Value -or $null -eq $new.Value -or
            $old.Value -is [string] -or $new.Value -is [string]){return $false}
        $actual=[double]$new.Value
        $previous=[double]$old.Value
        if([double]::IsNaN($actual) -or [double]::IsInfinity($actual) -or
            [double]::IsNaN($previous) -or [double]::IsInfinity($previous) -or
            [Math]::Abs($actual-[double]$Expected[$name]) -gt 0.00001){return $false}
        if([Math]::Abs($actual-$previous) -gt 0.00001){$changed=$true}
    }
    return $changed
}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
if((Split-Path -Parent $run) -ne (Join-Path $env:LOCALAPPDATA 'AMXDENIS-Integration\Runs')){throw 'Input requires the dedicated native run area.'}
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$' -or
    $state.Profile -ne (Join-Path (Join-Path $env:USERPROFILE 'Saved Games') $state.ProfileName)){throw 'Input profile identity mismatch.'}
$relative='Scripts/private-bindings.csv'
$path=Join-Path $state.Profile $relative
$manifestRow=@($state.PrivateScripts | Where-Object Path -eq $relative)
if($manifestRow.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $manifestRow[0].SHA256){throw 'Private input map changed.'}
$matchesFound=@(Import-Csv -LiteralPath $path -Delimiter '|' | Where-Object {
    $_.Name -ceq $Control -and [double]::Parse($_.Value,[Globalization.CultureInfo]::InvariantCulture) -eq $Value
})
if($matchesFound.Count -ne 1){throw 'No unique generated keyboard binding for the requested control/value.'}
$binding=$matchesFound[0]
if($binding.Key -notmatch '^F([1-9]|1[0-2])$'){throw 'Unexpected temporary key'}
$functionKey=[int]$binding.Key.Substring(1)
$scan=if($functionKey -le 10){58+$functionKey}elseif($functionKey -eq 11){87}else{88}
$arguments=@{RunRoot=$run;Action='ScanKey';ScanCode=$scan}
$mapping=@{LCtrl='Control';LShift='Shift';LAlt='Alt';RCtrl='RightControl';RShift='RightShift';RAlt='RightAlt'}
foreach($modifier in $binding.Modifiers.Split('+')){
    if(-not $mapping.ContainsKey($modifier)){throw 'Unknown input modifier'}
    $arguments[$mapping[$modifier]]=$true
}
if($ResolveOnly){return [pscustomobject]@{Binding=$binding;ScanCode=$scan;InputSent=$false}}
$nativeValidity=Join-Path $state.Profile 'Scripts/native-input-validity.csv'
if(-not(Test-Path -LiteralPath $nativeValidity -PathType Leaf)){throw 'Native input audit has not completed; no key sent.'}
$validation=@(Import-Csv -LiteralPath $nativeValidity -Delimiter '|' | Where-Object {
    $_.Name -ceq $Control -and [double]::Parse($_.Value,[Globalization.CultureInfo]::InvariantCulture) -eq $Value
})
if($validation.Count -ne 1 -or $validation[0].Valid -cne 'true'){
    $reason=if($validation.Count){$validation[0].Reason}else{'binding not reported'}
    throw "Native binding is invalid; no key sent: $Control ($reason)"
}
$before=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
if($PSBoundParameters.ContainsKey('ExpectedParameters')){
    if(-not $ExpectedParameters -or $ExpectedParameters.Count -eq 0){throw 'Empty expected state is not a functional test.'}
    $null=Test-InputEffect $before $before $ExpectedParameters
}
if(-not $ReportName){$ReportName='input-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+$Control+'.json'}
$report=Resolve-IntegrationFile $run $ReportName
if(Test-Path -LiteralPath $report){throw 'Input report already exists; no key sent.'}
& (Join-Path $PSScriptRoot 'Window.ps1') @arguments | Write-Host
$requiresRelease=$binding.Release -eq '0'
$effectCheck=${function:Test-InputEffect}
$condition={param($sample)
    $receipt=$sample.parameters.AMXDENIS_INPUT_RECEIVED -gt $before.parameters.AMXDENIS_INPUT_RECEIVED -and
        $sample.parameters.AMXDENIS_INPUT_LAST_COMMAND -eq [int]$binding.Route
    $released=-not $requiresRelease -or ($sample.parameters.AMXDENIS_INPUT_LAST_VALUE_VALID -eq 1 -and
        $sample.parameters.AMXDENIS_INPUT_LAST_VALUE -eq 0 -and
        ($sample.parameters.AMXDENIS_INPUT_RECEIVED-$before.parameters.AMXDENIS_INPUT_RECEIVED) -ge 2)
    return [bool]($receipt -and $released -and $sample.sequence -eq $before.sequence -and
        (-not $ExpectedParameters -or (& $effectCheck $before $sample $ExpectedParameters)))
}.GetNewClosure()
$waitError=$null
try {
    $after=& (Join-Path $PSScriptRoot 'Wait-State.ps1') -RunRoot $run -Condition $condition -AfterModelTime $before.model_time -TimeoutSeconds $TimeoutSeconds
} catch {
    if($_.Exception.Message -ne 'Native condition was not observed in time; raw evidence retained.'){throw}
    $waitError=$_.Exception.Message
    $after=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
}
$received=$after.parameters.AMXDENIS_INPUT_RECEIVED -gt $before.parameters.AMXDENIS_INPUT_RECEIVED -and
    $after.parameters.AMXDENIS_INPUT_LAST_COMMAND -eq [int]$binding.Route
$effect=Test-InputEffect $before $after $ExpectedParameters
Write-IntegrationJson $report ([ordered]@{Schema='AMXDENIS_NATIVE_KEY_INPUT_1';Control=$Control;Value=$Value;Binding=$binding;
    InputSource='Windows SendInput into native DCS input layer';ObservedReceipt=$received;Before=$before;After=$after;
    ExpectedParameters=$ExpectedParameters;RequiredRelease=$requiresRelease;WaitError=$waitError;
    StableSamplesConfirmed=if($waitError){0}else{3};FunctionalEffectVerified=($effect -and -not $waitError);
    PhysicalHotasApproval=$false;CommandAcceptanceIsNotPhysicalActuation=$true;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
if($waitError){throw "Native keyboard outcome not confirmed: $Control; report preserved at $report"}
if(-not $received){throw "Native keyboard receipt not confirmed: $Control; report preserved at $report"}
Write-Host "AMXDENIS_KEY_RECEIVED|$Control|$Value|route=$($binding.Route)"
return $after