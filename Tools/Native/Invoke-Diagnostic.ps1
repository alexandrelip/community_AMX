[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$Control,
    [Parameter(Mandatory)][double]$Value,
    [switch]$Release,
    [string]$ReportName
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$' -or
    $state.Profile -ne (Join-Path (Join-Path $env:USERPROFILE 'Saved Games') $state.ProfileName)){throw 'Diagnostic run identity mismatch.'}
if($Release){
    $bindings=Import-Csv -LiteralPath (Join-Path $state.Profile 'Scripts/private-bindings.csv') -Delimiter '|'
    $button=@($bindings | Where-Object {$_.Name -ceq $Control -and $_.Release -eq '0'})
    if(-not $button.Count -or $Value -eq 0){throw 'Release is limited to generated momentary/button controls.'}
}
$before=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
$native=Join-Path (Split-Path -Parent $PSScriptRoot) 'Test-AMXDENISNative.ps1'
$values=if($Release){@($Value,0)}else{@($Value)}
foreach($requestValue in $values){
    & $native -Action Command -RunRoot $run -Control $Control -Value $requestValue | Write-Host
    $sequence=[int]((Get-Content -LiteralPath (Join-Path $state.Profile 'Scripts/request.txt') -Raw).Split('|')[0])
    & $native -Action Await -RunRoot $run -Sequence $sequence -TimeoutSeconds 20 | Write-Host
}
$after=& (Join-Path $PSScriptRoot 'Read-State.ps1') -RunRoot $run
if(-not $ReportName){$ReportName='diagnostic-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+$Control+'.json'}
Write-IntegrationJson (Resolve-IntegrationFile $run $ReportName) ([ordered]@{Schema='AMXDENIS_EXPLICIT_DIAGNOSTIC_1';
    Control=$Control;RequestedValue=$Value;ReleaseRequested=[bool]$Release;Before=$before;After=$after;
    InputSource='Explicit diagnostic request via private Export; NOT physical keyboard/mouse/HOTAS';
    PhysicalInputApproved=$false;PhysicalActuationApproved=$false;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
return $after