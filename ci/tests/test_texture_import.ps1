[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module (Join-Path $repo 'Tools\AMXDENISIntegration.psm1') -Force
$importer = Join-Path $repo 'Tools\Import-AMXDENISCockpitTextures.ps1'
$restore = Join-Path $repo 'Tools\Restore-AMXDENISIntegration.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('AMXDENIS-Textures-' + [guid]::NewGuid().ToString('N'))
$checks = 0
function Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Rejected {
    param([scriptblock]$Operation, [string]$Expected)
    $message = $null
    try { & $Operation | Out-Null } catch { $message = $_.Exception.Message }
    Check ($null -ne $message -and $message -match $Expected) "Expected rejection '$Expected', received '$message'."
}
function Candidate {
    param([string]$Path)
    return [pscustomobject]@{path=$Path; bytes=(Get-Item -LiteralPath $Path).Length; sha256=(Get-IntegrationHash $Path)}
}
try {
    $target = Join-Path $fixture 'Target'
    $primary = Join-Path $fixture 'SuppliedREV07'
    $fallback = Join-Path $fixture 'AuthorizedFallback'
    $snapshotRoot = Join-Path $fixture 'Snapshot'
    foreach ($path in @($target, $primary, $fallback, (Join-Path $target 'Shapes'),
        (Join-Path $target 'Textures'), (Join-Path $target 'Config'), (Join-Path $target 'Doc\Integration'))) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    [IO.File]::WriteAllText((Join-Path $target 'entry.lua'), 'original aircraft entry')
    $modelPath = Join-Path $target 'Shapes\AMX_COCKPIT_REV07_184.edm'
    [IO.File]::WriteAllText($modelPath, 'fixture only; not a real model')
    [IO.File]::WriteAllText((Join-Path $target 'Textures\exterior.dds'), 'protected exterior')
    $records = foreach ($relative in @('entry.lua', 'Shapes/AMX_COCKPIT_REV07_184.edm', 'Textures/exterior.dds')) {
        $saved = Resolve-IntegrationFile (Join-Path $snapshotRoot 'Target') $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $saved) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $target $relative) -Destination $saved
        [pscustomobject]@{Root='Target'; Path=$relative; SHA256=(Get-IntegrationHash $saved)}
    }
    Write-IntegrationJson (Join-Path $snapshotRoot 'snapshot.json') ([ordered]@{
        Schema='AMXDENIS_SNAPSHOT_1'; Id='texture-fixture'; Roots=@{Target=$target; Source=$fallback}; Files=@($records)})
    Write-IntegrationJson (Join-Path $snapshotRoot 'verification.json') ([ordered]@{
        Schema='AMXDENIS_SNAPSHOT_VERIFICATION_1'; Id='texture-fixture'; Files=$records.Count;
        SnapshotSHA256=(Get-IntegrationHash (Join-Path $snapshotRoot 'snapshot.json')); SourceAndCopyHashesMatch=$true})
    $configuration = Get-Content -LiteralPath (Join-Path $repo 'Config\AMXDENIS_INTEGRATION.json') -Raw | ConvertFrom-Json -DateKind String
    $configuration.InternalModel.SHA256 = Get-IntegrationHash $modelPath
    $configuration.InternalModel.Bytes = (Get-Item -LiteralPath $modelPath).Length
    $permission = Get-Content -LiteralPath (Join-Path $repo 'Doc\Integration\PERMISSIONS.json') -Raw | ConvertFrom-Json -DateKind String
    $permission.Statement = 'Test fixture only; not an actual grant of rights.'
    $permissionPath = Join-Path $target 'Doc\Integration\PERMISSIONS.json'
    Write-IntegrationJson $permissionPath $permission
    Write-IntegrationJson (Join-Path $target 'Config\AMXDENIS_INTEGRATION.json') $configuration
    $permissionBytes = [IO.File]::ReadAllBytes($permissionPath)
    $verified = Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources'
    Check ($verified.State -eq 'AUTHORIZED_LOCAL' -and $verified.Scope -eq 'LOCAL_AMXDENIS_M1') 'Recorded local scope was lost.'
    $configuration.Permissions[1].State = 'UNCONFIRMED'
    Rejected { Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources' } 'not recorded'
    $configuration.Permissions[1].State = 'AUTHORIZED_LOCAL'
    $configuration.Permissions[1].Evidence = 'absent.json'
    Rejected { Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources' } 'absent'
    $configuration.Permissions[1].Evidence = '../other.json'
    Rejected { Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources' } 'Invalid integration-relative'
    $configuration.Permissions[1].Evidence = 'Doc/Integration/PERMISSIONS.json'
    $permission.Scope = 'DIFFERENT_PROJECT'
    [IO.File]::WriteAllText($permissionPath, ($permission | ConvertTo-Json -Depth 8))
    Rejected { Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources' } 'does not cover'
    [IO.File]::WriteAllBytes($permissionPath, $permissionBytes)
    Rejected { Assert-IntegrationPermission $target $configuration 'Unapproved binary' } 'not recorded'

    $shared = Join-Path $primary 'Panel.png'
    $oldShared = Join-Path $fallback 'Panel.png'
    $normal = Join-Path $fallback 'Panel_nml.png'
    [IO.File]::WriteAllText($shared, 'new REV07 panel bytes')
    [IO.File]::WriteAllText($oldShared, 'different legacy panel bytes')
    [IO.File]::WriteAllText($normal, 'authorized normal map bytes')
    [IO.File]::WriteAllText((Join-Path $primary 'Panel.png.tx'), 'editor cache must not be copied')
    [IO.File]::WriteAllText((Join-Path $primary 'unreferenced.png'), 'not a model dependency')
    $inventory = [ordered]@{schema='AMXDENIS_COCKPIT_INVENTORY_1';
        sha256=$configuration.InternalModel.SHA256; bytes=$configuration.InternalModel.Bytes;
        materials=@(@{textures=@(@{name='panel'}, @{name='panel_nml'}, @{name='missing'})});
        textures=@(@{name='panel'; candidates=@((Candidate $shared), (Candidate $oldShared))},
            @{name='panel_nml'; candidates=@((Candidate $normal))}, @{name='missing'; candidates=@()})}
    $inventoryPath = Join-Path $fixture 'inventory.json'
    Write-IntegrationJson $inventoryPath $inventory
    $options = @{SnapshotRoot=$snapshotRoot; TargetRoot=$target}
    $planOptions = @{InventoryPath=$inventoryPath; SourceRoot=@($primary, $fallback)}
    $planPath = Join-Path $fixture 'plan.json'
    & $importer @options @planOptions -Action Plan -ReportPath $planPath | Out-Null
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json -DateKind String
    Check ($plan.Files.Count -eq 2 -and $plan.MissingTextures[0] -eq 'missing' -and -not $plan.Complete) 'Available files and unresolved names were not separated.'
    Check ($plan.Files[0].SHA256 -eq (Get-IntegrationHash $shared) -and $plan.Files[0].SourceIndex -eq 0) 'Explicit source priority was not respected.'
    Check ($plan.Files[1].SourceIndex -eq 1) 'Authorized fallback was not selected for the absent primary name.'
    Check (-not (Test-Path -LiteralPath (Join-Path $target 'Cockpit'))) 'Plan copied files.'
    Rejected { & $importer @options @planOptions -Action Plan -ReportPath $planPath } 'already exists'
    Rejected { & $importer @options -Action Import -PlanPath $planPath -ReportPath (Join-Path $fixture 'refused-incomplete.json') } 'AllowIncomplete'
    Check (-not (Test-Path -LiteralPath (Join-Path $target 'Cockpit'))) 'Incomplete refusal left imported textures.'
    [IO.File]::WriteAllText($shared, 'concurrent source edit')
    Rejected { & $importer @options -Action Import -AllowIncomplete -PlanPath $planPath -ReportPath (Join-Path $fixture 'refused-source.json') } 'source changed'
    Check (-not (Test-Path -LiteralPath (Join-Path $target 'Cockpit'))) 'Stale source detection happened after copying.'
    [IO.File]::WriteAllText($shared, 'new REV07 panel bytes')

    $second = Join-Path $primary 'Panel.dds'
    [IO.File]::WriteAllText($second, 'ambiguous same-source basename')
    $inventory.textures[0].candidates += Candidate $second
    $ambiguousPath = Join-Path $fixture 'ambiguous.json'
    Write-IntegrationJson $ambiguousPath $inventory
    Rejected { & $importer @options -Action Plan -SourceRoot $primary,$fallback -InventoryPath $ambiguousPath -ReportPath (Join-Path $fixture 'ambiguous-plan.json') } 'Ambiguous'
    Remove-Item -LiteralPath $second
    $inventory.textures[0].candidates = @((Candidate $shared), (Candidate $oldShared))
    $inventory.textures[0].name = 'undeclared'
    Write-IntegrationJson (Join-Path $fixture 'undeclared.json') $inventory
    Rejected { & $importer @options -Action Plan -SourceRoot $primary,$fallback -InventoryPath (Join-Path $fixture 'undeclared.json') -ReportPath (Join-Path $fixture 'undeclared-plan.json') } 'undeclared'
    $inventory.textures[0].name = 'panel'
    $conflicting = Join-Path $primary 'exterior.dds'
    [IO.File]::WriteAllText($conflicting, 'different exterior bytes')
    $conflict = [ordered]@{schema=$inventory.schema; sha256=$inventory.sha256; bytes=$inventory.bytes;
        materials=@(@{textures=@(@{name='exterior'})}); textures=@(@{name='exterior';candidates=@((Candidate $conflicting))})}
    Write-IntegrationJson (Join-Path $fixture 'conflict.json') $conflict
    Rejected { & $importer @options -Action Plan -SourceRoot $primary -InventoryPath (Join-Path $fixture 'conflict.json') -ReportPath (Join-Path $fixture 'conflict-plan.json') } 'protected exterior'

    $importPath = Join-Path $fixture 'import.json'
    & $importer @options -Action Import -AllowIncomplete -PlanPath $planPath -ReportPath $importPath | Out-Null
    $manifestPath = Join-Path $target 'Config\AMXDENIS_TEXTURES.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
    Check ($manifest.Files.Count -eq 2 -and -not $manifest.Complete -and -not $manifest.NativeValidated) 'Partial resource import became cockpit approval.'
    foreach ($record in $manifest.Files) {
        Check ((Get-IntegrationHash (Join-Path $target $record.Path)) -eq $record.SHA256) 'Imported bytes differ.'
        Check ($null -eq $record.PSObject.Properties['SourcePath']) 'Runtime manifest requires an absolute source workspace path.'
    }
    $textureDirectory = Join-Path $target 'Cockpit\AMX-A1M\Textures'
    Check (@(Get-ChildItem -LiteralPath $textureDirectory -File).Count -eq 2) 'Caches or unrelated textures were copied.'
    Rejected { & $importer @options -Action Import -AllowIncomplete -PlanPath $planPath -ReportPath (Join-Path $fixture 'reimport.json') } 'already exists'
    Remove-Item -LiteralPath $shared, $oldShared, $normal
    $verifyPath = Join-Path $fixture 'verify.json'
    & $importer @options -Action Verify -ReportPath $verifyPath | Out-Null
    $verification = Get-Content -LiteralPath $verifyPath -Raw | ConvertFrom-Json
    Check ($verification.Passed -and $verification.FilesChecked -eq 2 -and -not $verification.SourceRootsRead) 'Verification depends on the old source files.'
    Check (-not $verification.NativeValidated -and $verification.MissingTextures[0] -eq 'missing') 'Verification concealed incomplete resources.'
    Rejected { & $importer @options -Action Verify -ReportPath $verifyPath } 'already exists'
    $localInventory = Join-Path $fixture 'local-inventory.json'
    Write-IntegrationJson $localInventory ([ordered]@{schema=$inventory.schema; sha256=$inventory.sha256;
        bytes=$inventory.bytes; missing_textures=@('missing'); duplicate_connectors=@{}})
    $preflight = & (Join-Path $repo 'Tools\Test-AMXDENISPrerequisites.ps1') @options -InventoryPath $localInventory `
        -ConfigurationPath (Join-Path $target 'Config\AMXDENIS_INTEGRATION.json') -ReportPath (Join-Path $fixture 'preflight.json')
    Check ($preflight.ImportedFiles -eq 2 -and -not $preflight.CandidateReady) 'Preflight lost imported resources or approved an incomplete cockpit.'
    Check ('PERMISSION_UNCONFIRMED' -notin $preflight.Blockers.Code -and 'TEXTURE_SET_INCOMPLETE' -in $preflight.Blockers.Code) 'Recorded permission was confused with missing resources.'
    $installedPanel = Join-Path $textureDirectory 'Panel.png'
    [IO.File]::WriteAllText($installedPanel, 'later user edit')
    Rejected { & $importer @options -Action Verify -ReportPath (Join-Path $fixture 'changed-local.json') } 'Local texture changed'
    Check ((Get-Content -LiteralPath $installedPanel -Raw) -eq 'later user edit') 'Verification overwrote a later edit.'
    [IO.File]::WriteAllText($installedPanel, 'new REV07 panel bytes')
    $unrelated = Join-Path $textureDirectory 'later-note.txt'
    [IO.File]::WriteAllText($unrelated, 'preserve unrelated work')
    Rejected { & $importer @options -Action Verify -ReportPath (Join-Path $fixture 'unexpected.json') } 'Unexpected resources'
    $receiptPath = Join-Path $fixture 'receipt.json'
    & $restore @options -Action Record -ReceiptPath $receiptPath -OwnedPath (@($manifest.Files.Path) + @('Config/AMXDENIS_TEXTURES.json')) | Out-Null
    & $restore @options -Action Apply -ReceiptPath $receiptPath | Out-Null
    Check (-not (Test-Path -LiteralPath $installedPanel) -and -not (Test-Path -LiteralPath $manifestPath)) 'Texture rollback left owned files.'
    Check ((Get-Content -LiteralPath $unrelated -Raw) -eq 'preserve unrelated work') 'Texture rollback removed unrelated later work.'
    Assert-IntegrationBaseline (Read-IntegrationSnapshot $snapshotRoot $target)
    Check ((Get-Content -LiteralPath (Join-Path $target 'entry.lua') -Raw) -eq 'original aircraft entry') 'Import or rollback changed the loader.'
    Write-Output "AMXDENIS TEXTURE GUARDS: $checks/$checks checks passed"
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}