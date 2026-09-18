[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SnapshotRoot,
    [Parameter(Mandatory)][string]$InventoryPath,
    [Parameter(Mandatory)][string]$ReportPath,
    [string]$TargetRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ConfigurationPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Config\AMXDENIS_INTEGRATION.json'),
    [switch]$RequireReady
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$snapshot = Read-IntegrationSnapshot $SnapshotRoot $TargetRoot
Assert-IntegrationBaseline $snapshot
$reportFile = Assert-IntegrationPath $ReportPath
foreach ($root in @($snapshot.Target, $snapshot.Source, $snapshot.Root)) {
    if ($reportFile -eq $root -or $reportFile.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Preflight evidence must be written outside repositories and immutable backups.'
    }
}
$configuration = Get-Content -LiteralPath (Assert-IntegrationPath $ConfigurationPath) -Raw | ConvertFrom-Json
$inventory = Get-Content -LiteralPath (Assert-IntegrationPath $InventoryPath) -Raw | ConvertFrom-Json
if ($configuration.Schema -ne 'AMXDENIS_M1_PLAN_1' -or
    $inventory.schema -ne 'AMXDENIS_COCKPIT_INVENTORY_1') { throw 'Unknown prerequisite contract.' }
if ($configuration.AircraftType -ne 'AMXT_M' -or $configuration.PilotSeat -ne 1 -or
    $configuration.PluginId -ne 'Embraer AMX' -or $configuration.DeveloperName -ne 'BR') {
    throw 'The authorized aircraft, seat and original identity must be preserved.'
}
foreach ($flag in @('EnabledInWorkingTree', 'NativeFlir', 'HelmetDisplay', 'NativeRadioProbe',
    'ExternalResourcesMutable', 'FlightModelMutable')) {
    if ($configuration.$flag -ne $false) { throw "Out-of-scope configuration: $flag" }
}
$blockers = [Collections.Generic.List[object]]::new()
$modelPath = Resolve-IntegrationFile $snapshot.Target $configuration.InternalModel.Path
$actualHash = Get-IntegrationHash $modelPath
if ($actualHash -ne $configuration.InternalModel.SHA256 -or
    ($actualHash -and (Get-Item -LiteralPath $modelPath).Length -ne $configuration.InternalModel.Bytes)) {
    $blockers.Add([pscustomobject]@{Code='MODEL_IDENTITY'; Resource=$configuration.InternalModel.Path})
}
if ($inventory.sha256 -ne $configuration.InternalModel.SHA256 -or $inventory.bytes -ne $configuration.InternalModel.Bytes) {
    $blockers.Add([pscustomobject]@{Code='INVENTORY_STALE'; Resource='Run a fresh inspection of the approved REV07'})
}
foreach ($texture in $inventory.missing_textures) {
    $blockers.Add([pscustomobject]@{Code='TEXTURE_UNRESOLVED'; Resource=$texture})
}
foreach ($duplicate in $inventory.duplicate_connectors.PSObject.Properties) {
    $blockers.Add([pscustomobject]@{Code='CONNECTOR_AMBIGUOUS'; Resource=$duplicate.Name; Count=$duplicate.Value})
}
$importedTextures = 0
$textureManifestHash = $null
$textureManifestPath = Resolve-IntegrationFile $snapshot.Target 'Config/AMXDENIS_TEXTURES.json'
if (-not (Test-Path -LiteralPath $textureManifestPath -PathType Leaf)) {
    $blockers.Add([pscustomobject]@{Code='TEXTURES_NOT_IMPORTED'; Resource='No local texture manifest exists'})
} else {
    try {
        $textureManifestHash = Get-IntegrationHash $textureManifestPath
        $textureManifest = Get-Content -LiteralPath $textureManifestPath -Raw | ConvertFrom-Json -DateKind String
        if ($textureManifest.Schema -ne 'AMXDENIS_COCKPIT_TEXTURES_1' -or
            $textureManifest.ModelSHA256 -ne $actualHash -or
            $textureManifest.Directory -ne 'Cockpit/AMX-A1M/Textures' -or
            -not @($textureManifest.Files).Count) { throw 'Unexpected texture manifest identity.' }
        $seen = @{}
        foreach ($file in $textureManifest.Files) {
            $path = Resolve-IntegrationFile $snapshot.Target $file.Path
            if ($seen.ContainsKey($file.Path) -or
                $file.Path -cne ('Cockpit/AMX-A1M/Textures/' + [IO.Path]::GetFileName($path)) -or
                (Get-IntegrationHash $path) -ne $file.SHA256 -or
                (Get-Item -LiteralPath $path).Length -ne $file.Bytes) { throw "Missing or changed local texture: $($file.Name)" }
            $seen[$file.Path] = $true
        }
        if ((Get-IntegrationHash $textureManifestPath) -ne $textureManifestHash) { throw 'Texture manifest changed while being read.' }
        $importedTextures = $seen.Count
        if ($textureManifest.Complete -ne $true -or @($textureManifest.MissingTextures).Count) {
            $blockers.Add([pscustomobject]@{Code='TEXTURE_SET_INCOMPLETE'; Resource='Local import preserves unresolved names; no substitutions were made'})
        }
    } catch {
        $blockers.Add([pscustomobject]@{Code='TEXTURE_INTEGRITY'; Resource=$_.Exception.Message})
    }
}
foreach ($permission in $configuration.Permissions) {
    try {
        $null = Assert-IntegrationPermission $snapshot.Target $configuration $permission.Component
    } catch {
        $blockers.Add([pscustomobject]@{Code='PERMISSION_UNCONFIRMED'; Resource=$permission.Component;
            Reason=$_.Exception.Message})
    }
}
if ($configuration.BindingsState -ne 'ACEITO_NO_ESCOPO') {
    $blockers.Add([pscustomobject]@{Code='REV07_BINDINGS_UNVALIDATED'; Resource='Old cockpit bindings are not approval for REV07'})
}
if ($configuration.RuntimeState -ne 'BANCADA') {
    $blockers.Add([pscustomobject]@{Code='RUNTIME_NOT_BUILT'; Resource='No integrated runtime or reproducible candidate exists yet'})
}
$result = [pscustomobject][ordered]@{
    Schema='AMXDENIS_M1_PREFLIGHT_1'; RecordedUtc=[DateTime]::UtcNow.ToString('o');
    AircraftType=$configuration.AircraftType; PilotSeat=$configuration.PilotSeat;
    InternalModelSHA256=$actualHash; SnapshotId=$snapshot.Id;
    ConfigurationSHA256=(Get-IntegrationHash $ConfigurationPath);
    InventorySHA256=(Get-IntegrationHash $InventoryPath);
    BaselineFilesChecked=$snapshot.Files.Count; BaselinePreserved=$true;
    State=$(if ($blockers.Count) { 'BLOQUEADO' } else { 'BANCADA' });
    CandidateReady=($blockers.Count -eq 0); NativeValidated=$false;
    ImportedFiles=$importedTextures; ImportedFileScope='Verified local cockpit textures only';
    TextureManifestSHA256=$textureManifestHash; Blockers=$blockers.ToArray()
}
Write-IntegrationJson $reportFile $result
if ($RequireReady -and -not $result.CandidateReady) {
    throw "Native-readiness prerequisites are blocked ($($blockers.Count)); this preflight does not authorize a native launch. Isolated bench assembly has its own guards. Report: $reportFile"
}
return $result