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
    Write-Output "AMXDENIS INTEGRATION GUARDS: $checks/$checks checks passed"
} finally {
    if (Test-Path -LiteralPath (Join-Path $fixture 'Target\linked')) { Remove-Item -LiteralPath (Join-Path $fixture 'Target\linked') }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}