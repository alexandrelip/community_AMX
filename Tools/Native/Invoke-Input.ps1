[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$Control,
    [Parameter(Mandatory)][double]$Value,
    [string]$ReportName,
    [hashtable]$ExpectedParameters,
    [ValidateRange(1,60)][int]$TimeoutSeconds=10,
    [switch]$Mouse,
    [ValidateRange(0,10000)][int]$ClickX,
    [ValidateRange(0,10000)][int]$ClickY,
    [switch]$RightButton,
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
        if($null -eq $new -or $null -eq $new.Value -or $new.Value -is [string] -or $new.Value -is [bool]){return $false}
        $actual=[double]$new.Value
        if([double]::IsNaN($actual) -or [double]::IsInfinity($actual) -or
            [Math]::Abs($actual-[double]$Expected[$name]) -gt 0.00001){return $false}
        if($null -eq $old){continue}
        if($null -eq $old.Value -or $old.Value -is [string] -or $old.Value -is [bool]){return $false}
        $previous=[double]$old.Value
        if([double]::IsNaN($previous) -or [double]::IsInfinity($previous)){return $false}
        if([Math]::Abs($actual-$previous) -gt 0.00001){$changed=$true}
    }
    return $changed
}
function Get-MouseControl($Binding,[object[]]$Catalog) {
    $mapped=@($Catalog | Where-Object {$_.Name -ceq $Binding.Name})
    if($mapped.Count -ne 1 -or $mapped[0].MouseMapped -cne 'true' -or
        [int]$mapped[0].InputCommand -ne [int]$Binding.Route -or
        $mapped[0].Connector -eq 'KEYBOARD_ONLY' -or $mapped[0].Connector -notmatch '^[A-Za-z0-9_-]+$'){
        throw 'No unique verified physical mouse mapping; no click sent.'
    }
    if($Binding.Name -eq 'IcpBrightness'){throw 'Mouse axis dragging is not implemented by the click helper; no click sent.'}
    return $mapped[0]
}
if($Mouse){
    if(-not $PSBoundParameters.ContainsKey('ClickX') -or -not $PSBoundParameters.ContainsKey('ClickY')){throw 'Mouse input requires explicit window coordinates.'}
    if(-not $ResolveOnly -and -not $ExpectedParameters){throw 'Mouse input requires expected producer effects.'}
}elseif($PSBoundParameters.ContainsKey('ClickX') -or $PSBoundParameters.ContainsKey('ClickY') -or $RightButton){
    throw 'Mouse coordinates and button selection require -Mouse.'
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
$mouseTarget=$null
if($Mouse){
    $catalogRelative='Doc/Integration/controls.csv'
    $catalogPath=Join-Path $state.Profile ('Mods/aircraft/AMXDENIS/'+$catalogRelative)
    $catalogHashes=@($state.RuntimeFiles | Where-Object {$_.Path.Replace('\','/') -ceq $catalogRelative})
    if($catalogHashes.Count -ne 1 -or (Get-FileHash -LiteralPath $catalogPath -Algorithm SHA256).Hash -ne $catalogHashes[0].SHA256){throw 'Mouse control catalog changed; no click sent.'}
    $mapped=Get-MouseControl $binding @(Import-Csv -LiteralPath $catalogPath -Delimiter '|')
    $mouseTarget=[ordered]@{X=$ClickX;Y=$ClickY;RightButton=[bool]$RightButton;Connector=$mapped.Connector;CatalogSHA256=$catalogHashes[0].SHA256}
}
if($binding.Key -notmatch '^F([1-9]|1[0-2])$'){throw 'Unexpected temporary key'}
$functionKey=[int]$binding.Key.Substring(1)
$scan=if($functionKey -le 10){58+$functionKey}elseif($functionKey -eq 11){87}else{88}
$arguments=@{RunRoot=$run;Action='ScanKey';ScanCode=$scan}
$mapping=@{LCtrl='Control';LShift='Shift';LAlt='Alt';RCtrl='RightControl';RShift='RightShift';RAlt='RightAlt'}
foreach($modifier in $binding.Modifiers.Split('+')){
    if(-not $mapping.ContainsKey($modifier)){throw 'Unknown input modifier'}
    $arguments[$mapping[$modifier]]=$true
}
if($ResolveOnly){return [pscustomobject]@{Binding=$binding;ScanCode=$scan;InputSent=$false;InputMethod=$(if($Mouse){'Mouse'}else{'Keyboard'});MouseTarget=$mouseTarget}}
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
$schema=if($Mouse){'AMXDENIS_NATIVE_MOUSE_INPUT_1'}else{'AMXDENIS_NATIVE_KEY_INPUT_1'}
$methodName=if($Mouse){'mouse'}else{'keyboard'}
$inputSource=if($Mouse){'Windows pointer move and click into native DCS clickable cockpit'}else{'Windows SendInput into native DCS input layer'}
$phase='ScanKey'
try {
    if($Mouse){
        $phase='Move'
        & (Join-Path $PSScriptRoot 'Window.ps1') -RunRoot $run -Action Move -X $ClickX -Y $ClickY | Write-Host
        $phase='Click'
        & (Join-Path $PSScriptRoot 'Window.ps1') -RunRoot $run -Action Click -X $ClickX -Y $ClickY -RightButton:$RightButton | Write-Host
    }else{& (Join-Path $PSScriptRoot 'Window.ps1') @arguments | Write-Host}
} catch {
    $inputFailure=$_
    $after=$null
    $observationError=$null
    try {$after=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run} catch {$observationError=$_.Exception.Message}
    $received=$null -ne $after -and $after.parameters.AMXDENIS_INPUT_RECEIVED -gt $before.parameters.AMXDENIS_INPUT_RECEIVED -and
        $after.parameters.AMXDENIS_INPUT_LAST_COMMAND -eq [int]$binding.Route
    Write-IntegrationJson $report ([ordered]@{Schema=$schema;Control=$Control;Value=$Value;Binding=$binding;
        InputSource=$inputSource;MouseTarget=$mouseTarget;InputPhase=$phase;InputDispatchCompleted=$false;
        InputError=$inputFailure.Exception.Message;ObservationError=$observationError;ObservedReceipt=$received;Before=$before;After=$after;
        ExpectedParameters=$ExpectedParameters;RequiredRelease=($binding.Release -eq '0');StableSamplesConfirmed=0;
        FunctionalEffectVerified=$false;PhysicalHotasApproval=$false;CommandAcceptanceIsNotPhysicalActuation=$true;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
    throw $inputFailure
}
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
Write-IntegrationJson $report ([ordered]@{Schema=$schema;Control=$Control;Value=$Value;Binding=$binding;
    InputSource=$inputSource;MouseTarget=$mouseTarget;InputPhase=$phase;InputDispatchCompleted=$true;ObservedReceipt=$received;Before=$before;After=$after;
    ExpectedParameters=$ExpectedParameters;RequiredRelease=$requiresRelease;WaitError=$waitError;
    StableSamplesConfirmed=if($waitError){0}else{3};FunctionalEffectVerified=($effect -and -not $waitError);
    PhysicalHotasApproval=$false;CommandAcceptanceIsNotPhysicalActuation=$true;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
if($waitError){throw "Native $methodName outcome not confirmed: $Control; report preserved at $report"}
if(-not $received){throw "Native $methodName receipt not confirmed: $Control; report preserved at $report"}
if($Mouse){Write-Host "AMXDENIS_MOUSE_RECEIVED|$Control|$Value|route=$($binding.Route)"}
else{Write-Host "AMXDENIS_KEY_RECEIVED|$Control|$Value|route=$($binding.Route)"}
return $after