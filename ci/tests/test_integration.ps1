[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'Tools\AMXDENISIntegration.psm1') -Force
$restore = Join-Path $repo 'Tools\Restore-AMXDENISIntegration.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('AMXDENIS-Guards-' + [guid]::NewGuid().ToString('N'))
$checks = 0
function Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Rejected {
    param([scriptblock]$Operation, [string]$Message)
    $rejected = $false
    try { & $Operation | Out-Null } catch { $rejected = $true }
    Check $rejected $Message
}
try {
    $target = Join-Path $fixture 'Target'
    $snapshotRoot = Join-Path $fixture 'Snapshot'
    $source = Join-Path $fixture 'Source'
    New-Item -ItemType Directory -Path $target, $source, (Join-Path $snapshotRoot 'Target') | Out-Null
    $original = Join-Path $target 'entry.lua'
    $unrelated = Join-Path $target 'untouched.lua'
    [IO.File]::WriteAllText($original, 'original')
    [IO.File]::WriteAllText($unrelated, 'protected')
    $records = foreach ($relative in @('entry.lua', 'untouched.lua')) {
        Copy-Item -LiteralPath (Join-Path $target $relative) -Destination (Join-Path $snapshotRoot ('Target\' + $relative))
        [pscustomobject]@{Root='Target'; Path=$relative; SHA256=(Get-IntegrationHash (Join-Path $target $relative))}
    }
    Write-IntegrationJson (Join-Path $snapshotRoot 'snapshot.json') ([ordered]@{
        Schema='AMXDENIS_SNAPSHOT_1'; Id='fixture'; Roots=@{Target=$target; Source=$source}; Files=@($records)})
    Write-IntegrationJson (Join-Path $snapshotRoot 'verification.json') ([ordered]@{
        Schema='AMXDENIS_SNAPSHOT_VERIFICATION_1'; Id='fixture'; Files=$records.Count;
        SnapshotSHA256=(Get-IntegrationHash (Join-Path $snapshotRoot 'snapshot.json')); SourceAndCopyHashesMatch=$true})
    $snapshot = Read-IntegrationSnapshot $snapshotRoot $target
    Assert-IntegrationBaseline $snapshot
    Check ($snapshot.Files.Count -eq 2) 'Baseline did not retain both files.'
    foreach ($invalid in @('../outside', '.git/config', 'a/../file', 'a//file', 'a/./file', 'file:stream', 'file.', 'file ', 'C:\outside')) {
        Rejected { Resolve-IntegrationFile $target $invalid } "Unsafe path accepted: $invalid"
    }
    Check ((Resolve-IntegrationFile $target 'sub/file.lua') -eq (Join-Path $target 'sub\file.lua')) 'Valid nested path rejected.'
    Rejected { Assert-IntegrationPath 'C:\' } 'Drive root accepted.'
    foreach ($unsafe in @('D:\Program Files\DCS World', 'C:\Windows\Temp',
        (Join-Path $env:USERPROFILE 'Saved Games\DCS\Scripts\Export.lua'))) {
        Rejected { Assert-IntegrationPath $unsafe } 'Simulator profile or installation accepted.'
    }
    $link = Join-Path $target 'linked'
    New-Item -ItemType Junction -Path $link -Target $source | Out-Null
    Rejected { Resolve-IntegrationFile $target 'linked/file.lua' } 'Linked ancestor accepted.'
    Remove-Item -LiteralPath $link
    Rejected { Read-IntegrationSnapshot $snapshotRoot $source } 'Source accepted as rollback target.'
    [IO.File]::WriteAllText($original, 'integrated')
    $new = Join-Path $target 'new.lua'
    [IO.File]::WriteAllText($new, 'owned')
    $later = Join-Path $target 'later-user.lua'
    [IO.File]::WriteAllText($later, 'keep this')
    $receipt = Join-Path $fixture 'receipt.json'
    $options = @{SnapshotRoot=$snapshotRoot; TargetRoot=$target; ReceiptPath=$receipt}
    Rejected { & $restore @options -Action Record } 'Empty ownership list accepted.'
    & $restore @options -Action Record -OwnedPath 'entry.lua', 'new.lua' | Out-Null
    Check (Test-Path -LiteralPath $receipt) 'Receipt not created.'
    Rejected { & $restore @options -Action Record -OwnedPath 'entry.lua' } 'Existing receipt overwritten.'
    & $restore @options -Action Preview | Out-Null
    Check ((Get-Content -LiteralPath $original -Raw) -eq 'integrated' -and (Test-Path -LiteralPath $new)) 'Preview modified the worktree.'
    [IO.File]::WriteAllText($new, 'later edit')
    Rejected { & $restore @options -Action Apply } 'Later edit was overwritten.'
    Check ((Get-Content -LiteralPath $original -Raw) -eq 'integrated') 'Rollback modified an earlier file before detecting a conflict.'
    [IO.File]::WriteAllText($new, 'owned')
    $saved = Join-Path $snapshotRoot 'Target\entry.lua'
    [IO.File]::WriteAllText($saved, 'changed backup')
    Rejected { & $restore @options -Action Apply } 'Modified snapshot was restored.'
    [IO.File]::WriteAllText($saved, 'original')
    & $restore @options -Action Apply | Out-Null
    Check ((Get-Content -LiteralPath $original -Raw) -eq 'original') 'Original bytes not restored.'
    Check (-not (Test-Path -LiteralPath $new)) 'Owned new file remained.'
    Check ((Get-Content -LiteralPath $later -Raw) -eq 'keep this') 'Unrelated later file was removed.'
    Check ((Get-Content -LiteralPath $unrelated -Raw) -eq 'protected') 'Protected file was modified.'
    Check (@(Get-ChildItem -LiteralPath $source -Force).Count -eq 0) 'Source was modified.'
    Assert-IntegrationBaseline $snapshot
    Rejected { & $restore @options -Action Apply } 'Completed receipt was replayed.'
    $inventoryPath = Join-Path $fixture 'inventory.json'
    Write-IntegrationJson $inventoryPath ([ordered]@{schema='AMXDENIS_COCKPIT_INVENTORY_1';
        sha256=('0' * 64); bytes=0; missing_textures=@('missing'); duplicate_connectors=@{HUD=2}})
    $preflight = Join-Path $repo 'Tools\Test-AMXDENISPrerequisites.ps1'
    $configuration = Get-Content -LiteralPath (Join-Path $repo 'Config\AMXDENIS_INTEGRATION.json') -Raw | ConvertFrom-Json
    foreach ($permission in $configuration.Permissions) {
        $permission.State = 'UNCONFIRMED'
        $permission.Evidence = $null
    }
    $configurationPath = Join-Path $fixture 'configuration.json'
    Write-IntegrationJson $configurationPath $configuration
    $preflightOptions = @{SnapshotRoot=$snapshotRoot; TargetRoot=$target; InventoryPath=$inventoryPath;
        ConfigurationPath=$configurationPath; ReportPath=(Join-Path $fixture 'preflight.json')}
    $result = & $preflight @preflightOptions
    Check ($result.State -eq 'BLOQUEADO' -and -not $result.CandidateReady -and -not $result.NativeValidated) 'Preflight promoted missing prerequisites.'
    Check ('PERMISSION_UNCONFIRMED' -in $result.Blockers.Code -and 'INVENTORY_STALE' -in $result.Blockers.Code) 'Preflight omitted permission or stale inventory blockers.'
    $preflightOptions.ReportPath = Join-Path $fixture 'strict-preflight.json'
    Rejected { & $preflight @preflightOptions -RequireReady } 'Strict preflight accepted a blocked candidate.'
    Check (Test-Path -LiteralPath $preflightOptions.ReportPath) 'Strict preflight lost its blocker evidence.'
    Check (@(Get-ChildItem -LiteralPath $source -Force).Count -eq 0) 'Preflight copied into the source.'
    $tokens=$null;$parseErrors=$null
    $nativeAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tools/Test-AMXDENISNative.ps1'),[ref]$tokens,[ref]$parseErrors)
    Check ($parseErrors.Count -eq 0) 'Native runner syntax is invalid.'
    $guard=$nativeAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'AssertNativeStartup'},$true)
    Check ($null -ne $guard) 'Native startup guard is missing.'
    . ([scriptblock]::Create($guard.Extent.Text))
    AssertNativeStartup '2026-09-18 00:00:00.000 INFO Dispatcher (Main): COMPILE MISSION diagnostic text'
    AssertNativeStartup '2026-09-18 00:00:00.000 WARNING Dispatcher (Main): COMPILE MISSION diagnostic text'
    Check $true 'Non-error log text was mistaken for a compiler failure.'
    foreach($failure in @('2026-09-18 00:00:00.000 ERROR Dispatcher (Main): COMPILE MISSION bad argument',
        '# C0000005 access violation','offline auth is not available','missed aicraft descriptor for AMXT_M')){
        Rejected {AssertNativeStartup $failure} 'Native startup failure was accepted.'
    }
    $guardCall=$nativeAst.Find({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'AssertNativeStartup'},$true)
    $readyReturn=$nativeAst.Find({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.StartsWith('if($observed)')},$true)
    Check ($null -ne $guardCall -and $null -ne $readyReturn -and $guardCall.Extent.StartOffset -lt $readyReturn.Extent.StartOffset) 'READY can bypass native startup failures.'
    $inputAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tools/Native/Invoke-Input.ps1'),[ref]$tokens,[ref]$parseErrors)
    Check ($parseErrors.Count -eq 0) 'Native keyboard helper syntax is invalid.'
    $effect=$inputAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-InputEffect'},$true)
    Check ($null -ne $effect) 'Keyboard effect predicate is missing.'
    . ([scriptblock]::Create($effect.Extent.Text))
    $before=[pscustomobject]@{model_time=1;sequence=0;parameters=[pscustomobject]@{CMFD1On=0;CMFD2On=1}}
    $after=[pscustomobject]@{model_time=2;sequence=0;parameters=[pscustomobject]@{CMFD1On=1;CMFD2On=1}}
    Check (Test-InputEffect $before $after @{CMFD1On=1;CMFD2On=1}) 'Producer transition was rejected.'
    Check (-not (Test-InputEffect $after $after @{CMFD1On=1})) 'Stale sample approved an effect.'
    Check (-not (Test-InputEffect $before $after @{CMFD1On=0})) 'Wrong producer state approved an effect.'
    Check (-not (Test-InputEffect $before $after @{CMFD2On=1})) 'Already-set value approved a transition.'
    Check (-not (Test-InputEffect $before $after @{MissingParameter=1})) 'Missing producer was treated as valid.'
    $after.sequence=1
    Check (-not (Test-InputEffect $before $after @{CMFD1On=1})) 'Diagnostic command interference approved keyboard effect.'
    $after.sequence=0
    $after.parameters.CMFD1On=[double]::NaN
    Check (-not (Test-InputEffect $before $after @{CMFD1On=1})) 'Nonfinite producer value approved an effect.'
    Rejected {Test-InputEffect $before $after @{AMXDENIS_CONTROL_IcpCOM1=1}} 'Router feedback was used as function proof.'
    Rejected {Test-InputEffect $before $after @{CMFD1On=[double]::PositiveInfinity}} 'Nonfinite expected state was accepted.'
    $cases=@(& (Join-Path $repo 'Tools/Native/Test-KeyboardCore.ps1') -Describe)
    Check ($cases.Count -eq 31 -and @($cases.Control | Sort-Object -Unique).Count -eq 13) 'Keyboard subset coverage changed without review.'
    foreach($case in $cases){
        Check ($case.Expected.Count -gt 0 -and -not @($case.Expected.Keys | Where-Object {$_ -match '^AMXDENIS_(INPUT_|CONTROL_)'}).Count) 'Suite uses router feedback instead of producer state.'
        Check ($case.Control -notin @('Gear','Flaps','Canopy','Starter')) 'Core indication suite silently included physical actuation.'
    }
    $navigation=@(& (Join-Path $repo 'Tools/Native/Test-KeyboardCore.ps1') -Describe -Suite Navigation)
    Check ($navigation.Count -eq 92 -and @($navigation.Control | Sort-Object -Unique).Count -eq 39) 'Navigation coverage changed without review.'
    Check (@($navigation | Where-Object {$_.Expected.ContainsKey('AMX_ICP_EDIT_INVALID') -and $_.Expected.AMX_ICP_EDIT_INVALID -eq 1}).Count -eq 1) 'Invalid fuel entry is not exercised.'
    Check (@($navigation | Where-Object Control -eq 'IcpCLR').Count -eq 3) 'Edit recovery coverage changed without review.'
    foreach($digit in 0..9){Check (@($navigation | Where-Object Control -eq ('Icp'+$digit)).Count -gt 0) 'Navigation suite omitted a digit.'}
    foreach($case in $navigation){
        Check ($case.Expected.Count -gt 0 -and -not @($case.Expected.Keys | Where-Object {$_ -match '^AMXDENIS_(INPUT_|CONTROL_)'}).Count) 'Navigation case relies on router feedback.'
    }
    $layouts=@(& (Join-Path $repo 'Tools/Native/Test-KeyboardCore.ps1') -Describe -Suite DisplayLayout)
    Check ($layouts.Count -eq 18 -and @($layouts.Control | Sort-Object -Unique).Count -eq 8) 'Display layout coverage changed without review.'
    Check (@($layouts | Where-Object {$_.Control -match '^Mfd[12]Oss(15|17)$'}).Count -eq 8) 'Display layout suite omitted reversible FULL/swap actions.'
    foreach($case in $layouts){
        Check ($case.Expected.Count -gt 0 -and -not @($case.Expected.Keys | Where-Object {$_ -match '^AMXDENIS_(INPUT_|CONTROL_)'}).Count) 'Display layout case relies on router feedback.'
    }
    Check ($layouts[6].Expected.CMFD1SelTop -eq 14 -and $layouts[6].Expected.CMFD2SelTop -eq 15 -and
        $layouts[6].Expected.CMFD1FULL -eq 1 -and $layouts[6].Expected.CMFD2FULL -eq 0) 'Swap must exchange both selected pages and layout flags.'
    Check ($layouts[7].Expected.CMFD1SelTop -eq 15 -and $layouts[7].Expected.CMFD2SelTop -eq 14 -and
        $layouts[7].Expected.CMFD1FULL -eq 0 -and $layouts[7].Expected.CMFD2FULL -eq 1) 'Second swap must restore both original layouts.'
    Check ($layouts[3].Expected.CMFD1SelLeft -eq 15 -and $layouts[3].Expected.CMFD2SelLeft -eq 17) 'Native cold baseline must not use the navigation suite final layout.'
    Check ($layouts[6].Expected.CMFD1SelLeft -eq 17 -and $layouts[6].Expected.CMFD2SelLeft -eq 15) 'Swap must exchange lower-left selections as well.'
    $windowAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tools/Native/Window.ps1'),[ref]$tokens,[ref]$parseErrors)
    Check ($parseErrors.Count -eq 0) 'Window helper syntax is invalid.'
    $releaseFunction=$windowAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Complete-KeyboardChord'},$true)
    Check ($null -ne $releaseFunction) 'Keyboard release ordering helper is missing.'
    . ([scriptblock]::Create($releaseFunction.Extent.Text))
    $pressed=[Collections.Generic.List[ushort]]::new()
    $released=[Collections.Generic.List[ushort]]::new()
    foreach($code in @(0x2A,0x38,87)){$pressed.Add($code)}
    $sendRelease={param($code) $released.Add($code)}.GetNewClosure()
    $observeRelease={
        if($released.Count -ne 1 -or $released[0] -ne 87 -or $pressed.Count -ne 2){throw 'Modifiers released before observation'}
    }.GetNewClosure()
    Complete-KeyboardChord $pressed $sendRelease $observeRelease
    Check ($pressed.Count -eq 0 -and ($released -join ',') -eq '87,56,42') 'Primary release did not precede modifier releases.'
    $released.Clear()
    foreach($code in @(0x2A,0x38,87)){$pressed.Add($code)}
    Rejected {Complete-KeyboardChord $pressed $sendRelease {throw 'No fresh observation'}} 'Release observation failure was hidden.'
    Check ($pressed.Count -eq 0 -and ($released -join ',') -eq '87,56,42') 'Observation failure left modifiers held.'
    $released.Clear()
    Complete-KeyboardChord $pressed $sendRelease {throw 'Empty chord cannot observe release'}
    Check ($released.Count -eq 0) 'Empty chord invented a key release.'
    $hydraulicStages=@(& (Join-Path $repo 'Tools/Native/Test-Hydraulics.ps1') -Describe)
    Check ($hydraulicStages.Count -eq 14 -and @($hydraulicStages.Name | Sort-Object -Unique).Count -eq 14) 'Hydraulic native sequence must retain fourteen distinct stages.'
    foreach($stage in $hydraulicStages){Check ($stage.Condition -is [scriptblock] -and $stage.Timeout -le 100) 'Hydraulic stages require bounded functional conditions.'}
    foreach($name in @('SpinUp','Fault1','Fault2','TotalLoss','Recover1','Recover2','AirbrakeOut','AirbrakeIn','Shutdown','ReserveLow')){
        Check (@($hydraulicStages | Where-Object Name -eq $name).Count -eq 1) 'Hydraulic native sequence omitted a required condition.'
    }
    Check ($hydraulicStages[9].Commands[0].Shift -eq $true -and $hydraulicStages[10].Commands[0].Control -eq $true) 'Hydraulic consumer test must use explicit native airbrake on/off commands.'
    $nativeHydraulicStages=@(& (Join-Path $repo 'Tools/Native/Test-Hydraulics.ps1') -Describe -AirbrakeSource Native)
    Check ($nativeHydraulicStages[9].Commands[0].Control -eq 'NativeAirbrakeOn' -and $nativeHydraulicStages[10].Commands[0].Control -eq 'NativeAirbrakeOff') 'Native airbrake comparison must preserve separate directional commands.'
    $hydraulicAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tools/Native/Test-Hydraulics.ps1'),[ref]$tokens,[ref]$parseErrors)
    Check ($parseErrors.Count -eq 0) 'Hydraulic helper syntax is invalid.'
    $stationary=$hydraulicAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-HydraulicStationary'},$true)
    Check ($null -ne $stationary) 'Hydraulic stationary guard is missing.'
    . ([scriptblock]::Create($stationary.Extent.Text))
    Assert-HydraulicStationary ([pscustomobject]@{velocity=[pscustomobject]@{x=0;y=0;z=0}})
    Check $true 'Stationary fixture was rejected.'
    foreach($value in @(0.26,-0.26,[double]::NaN,[double]::PositiveInfinity,$null,'0')){
        Rejected {Assert-HydraulicStationary ([pscustomobject]@{velocity=[pscustomobject]@{x=$value;y=0;z=0}})} 'Unsafe or unavailable velocity was allowed before hydraulic commands.'
    }
    Write-Output "AMXDENIS INTEGRATION GUARDS: $checks/$checks checks passed"
} finally {
    if (Test-Path -LiteralPath (Join-Path $fixture 'Target\linked')) { Remove-Item -LiteralPath (Join-Path $fixture 'Target\linked') }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}