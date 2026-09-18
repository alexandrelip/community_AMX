[CmdletBinding()]
param(
    [ValidateSet('Plan', 'Import', 'Verify')][string]$Action = 'Plan',
    [Parameter(Mandatory)][string]$SnapshotRoot,
    [Parameter(Mandatory)][string]$ReportPath,
    [string]$InventoryPath,
    [string[]]$SourceRoot = @(),
    [string]$PlanPath,
    [string]$TargetRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$AllowIncomplete
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$snapshot = Read-IntegrationSnapshot $SnapshotRoot $TargetRoot
Assert-IntegrationBaseline $snapshot
$configurationPath = Resolve-IntegrationFile $snapshot.Target 'Config/AMXDENIS_INTEGRATION.json'
$configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json -DateKind String
if ($configuration.Schema -ne 'AMXDENIS_M1_PLAN_1' -or $configuration.AircraftType -ne 'AMXT_M' -or
    $configuration.PilotSeat -ne 1 -or $configuration.PluginId -ne 'Embraer AMX' -or
    $configuration.DeveloperName -ne 'BR') { throw 'Unexpected local candidate identity.' }
foreach ($flag in @('EnabledInWorkingTree', 'NativeFlir', 'HelmetDisplay', 'NativeRadioProbe',
    'ExternalResourcesMutable', 'FlightModelMutable')) {
    if ($configuration.$flag -ne $false) { throw "Out-of-scope configuration: $flag" }
}
$permission = Assert-IntegrationPermission $snapshot.Target $configuration 'REV07 textures and indicator resources'
$modelPath = Resolve-IntegrationFile $snapshot.Target $configuration.InternalModel.Path
if ((Get-IntegrationHash $modelPath) -ne $configuration.InternalModel.SHA256 -or
    (Get-Item -LiteralPath $modelPath).Length -ne $configuration.InternalModel.Bytes) {
    throw 'REV07 identity changed; textures cannot be imported against a different model.'
}
$textureDirectory = 'Cockpit/AMX-A1M/Textures'
$manifestRelative = 'Config/AMXDENIS_TEXTURES.json'
$manifestPath = Resolve-IntegrationFile $snapshot.Target $manifestRelative
$reportFile = Assert-IntegrationPath $ReportPath
foreach ($root in @($snapshot.Target, $snapshot.Source, $snapshot.Root)) {
    if ($reportFile -eq $root -or $reportFile.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Operation reports must remain outside repositories and immutable snapshots.'
    }
}
if (Test-Path -LiteralPath $reportFile) { throw 'Operation report already exists; never overwrite previous evidence.' }
$extensions = @('.dds', '.png', '.bmp', '.tga', '.jpg', '.jpeg')

function Test-UnderRoot {
    param([string]$File, [string]$Root)
    return $File.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Assert-TextureRecord {
    param($Record)
    $path = Resolve-IntegrationFile $snapshot.Target $Record.Path
    if ($Record.Path -cne ($textureDirectory + '/' + [IO.Path]::GetFileName($path)) -or
        [IO.Path]::GetExtension($path).ToLowerInvariant() -notin $extensions -or
        [IO.Path]::GetFileNameWithoutExtension($path) -ine $Record.Name -or
        $Record.SHA256 -notmatch '^[A-Fa-f0-9]{64}$' -or $Record.Bytes -le 0) {
        throw 'Texture manifest contains an unexpected destination or identity.'
    }
    return $path
}

if ($Action -eq 'Plan') {
    if (-not $InventoryPath -or -not $SourceRoot.Count) { throw 'Plan requires a fresh inventory and explicitly ordered texture sources.' }
    $inventoryFile = Assert-IntegrationPath $InventoryPath
    $inventoryHash = Get-IntegrationHash $inventoryFile
    $inventory = Get-Content -LiteralPath $inventoryFile -Raw | ConvertFrom-Json -DateKind String
    if ($inventory.schema -ne 'AMXDENIS_COCKPIT_INVENTORY_1' -or
        $inventory.sha256 -ne $configuration.InternalModel.SHA256 -or
        $inventory.bytes -ne $configuration.InternalModel.Bytes) { throw 'Inventory is stale or belongs to another cockpit.' }
    $roots = @($SourceRoot | ForEach-Object { Assert-IntegrationPath $_ })
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container) -or
            $root -eq $snapshot.Target -or (Test-UnderRoot $root $snapshot.Target) -or
            (Test-UnderRoot $snapshot.Target $root) -or $reportFile -eq $root -or
            (Test-UnderRoot $reportFile $root)) { throw 'Unsafe texture source or evidence location.' }
    }
    if (@($roots | Sort-Object -Unique).Count -ne $roots.Count) { throw 'Duplicate texture source roots.' }
    $materialNames = @($inventory.materials | ForEach-Object { $_.textures } |
        ForEach-Object { $_.name } | Sort-Object -Unique)
    $seen = @{}
    $files = [Collections.Generic.List[object]]::new()
    $missing = [Collections.Generic.List[string]]::new()
    foreach ($texture in $inventory.textures) {
        $name = [string]$texture.name
        $null = Resolve-IntegrationFile $snapshot.Target ($textureDirectory + '/' + $name + '.png')
        if ($name -notin $materialNames -or $seen.ContainsKey($name)) { throw 'Inventory contains an undeclared or duplicate material texture.' }
        $seen[$name] = $true
        $selected = $null
        $sourceIndex = -1
        for ($index = 0; $index -lt $roots.Count; $index++) {
            $matchesInRoot = @($texture.candidates | Where-Object {
                Test-UnderRoot (Assert-IntegrationPath $_.path) $roots[$index]
            })
            if ($matchesInRoot.Count -gt 1) { throw "Ambiguous texture within one source: $name" }
            if ($matchesInRoot.Count -eq 1) { $selected=$matchesInRoot[0]; $sourceIndex=$index; break }
        }
        if ($null -eq $selected) { $missing.Add($name); continue }
        $source = Assert-IntegrationPath $selected.path
        $relative = $textureDirectory + '/' + [IO.Path]::GetFileName($source)
        $record = [pscustomobject]@{Name=$name; Path=$relative; Bytes=$selected.bytes; SHA256=$selected.sha256;
            SourceIndex=$sourceIndex; SourceRelative=[IO.Path]::GetRelativePath($roots[$sourceIndex], $source).Replace('\','/');
            SourcePath=$source; Alternatives=@($texture.candidates)}
        $destination = Assert-TextureRecord $record
        if ((Get-IntegrationHash $source) -ne $record.SHA256 -or
            (Get-Item -LiteralPath $source).Length -ne $record.Bytes) { throw "Texture changed since inventory: $name" }
        if (Test-Path -LiteralPath $destination) { throw "Destination already exists; use Verify instead of overwriting: $relative" }
        foreach ($protected in $snapshot.Files.Values | Where-Object {
            $_.Path.Replace('\','/') -match '^(Textures|Liveries)/' -and
            [IO.Path]::GetFileNameWithoutExtension($_.Path) -ieq $name
        }) {
            if ($protected.SHA256 -ne $record.SHA256) { throw "Texture would collide with protected exterior resources: $name" }
        }
        $files.Add($record)
    }
    if ($seen.Count -ne $materialNames.Count -or $files.Count -eq 0 -or
        (Get-IntegrationHash $inventoryFile) -ne $inventoryHash) { throw 'Incomplete or changing texture inventory.' }
    $plan = [ordered]@{Schema='AMXDENIS_TEXTURE_PLAN_1'; TargetRoot=$snapshot.Target;
        SnapshotId=$snapshot.Id; SnapshotSHA256=$snapshot.SHA256; ModelSHA256=$configuration.InternalModel.SHA256;
        ConfigurationSHA256=(Get-IntegrationHash $configurationPath); Permission=$permission;
        InventorySHA256=$inventoryHash; SourceRoots=$roots; TextureDirectory=$textureDirectory;
        Files=$files.ToArray(); MissingTextures=$missing.ToArray(); Complete=($missing.Count -eq 0);
        NativeValidated=$false; CopiedFiles=0; SourcePriority='First exact basename in explicitly ordered roots; no aliases or substitutes'}
    Write-IntegrationJson $reportFile $plan
    Write-Output "REV07_TEXTURE_PLAN|files=$($files.Count)|missing=$($missing.Count)|copied=0|$reportFile"
    return
}

if ($Action -eq 'Import') {
    if (-not $PlanPath) { throw 'Import requires the previously reviewed plan.' }
    $planFile = Assert-IntegrationPath $PlanPath
    $planHash = Get-IntegrationHash $planFile
    $plan = Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json -DateKind String
    if ($plan.Schema -ne 'AMXDENIS_TEXTURE_PLAN_1' -or $plan.TargetRoot -ne $snapshot.Target -or
        $plan.SnapshotId -ne $snapshot.Id -or $plan.SnapshotSHA256 -ne $snapshot.SHA256 -or
        $plan.ModelSHA256 -ne $configuration.InternalModel.SHA256 -or
        $plan.ConfigurationSHA256 -ne (Get-IntegrationHash $configurationPath) -or
        $plan.Permission.SHA256 -ne $permission.SHA256 -or $plan.TextureDirectory -ne $textureDirectory -or
        $plan.Complete -ne (@($plan.MissingTextures).Count -eq 0) -or -not @($plan.Files).Count) {
        throw 'Texture plan identity or permission evidence changed.'
    }
    if (-not $plan.Complete -and -not $AllowIncomplete) { throw 'Unresolved textures require explicit AllowIncomplete; this cannot approve a cockpit or flight.' }
    if (Test-Path -LiteralPath $manifestPath) { throw 'Texture manifest already exists; no silent reimport.' }
    $seen = @{}
    foreach ($record in $plan.Files) {
        $destination = Assert-TextureRecord $record
        if ($seen.ContainsKey($record.Path) -or (Test-Path -LiteralPath $destination)) { throw 'Duplicate or already occupied texture destination.' }
        $seen[$record.Path] = $true
        if ($record.SourceIndex -lt 0 -or $record.SourceIndex -ge $plan.SourceRoots.Count) { throw 'Unknown texture source index.' }
        $source = Resolve-IntegrationFile $plan.SourceRoots[$record.SourceIndex] $record.SourceRelative
        if ($source -ne $record.SourcePath -or (Get-IntegrationHash $source) -ne $record.SHA256 -or
            (Get-Item -LiteralPath $source).Length -ne $record.Bytes) { throw "Planned texture source changed: $($record.Name)" }
        if (Test-UnderRoot $reportFile $plan.SourceRoots[$record.SourceIndex]) { throw 'Import evidence cannot modify texture sources.' }
    }
    Write-IntegrationJson ($reportFile + '.intent.json') ([ordered]@{Schema='AMXDENIS_TEXTURE_IMPORT_INTENT_1';
        PlanSHA256=$planHash; OwnedNewPaths=@($plan.Files.Path) + @($manifestRelative); Files=$plan.Files})
    $copied = [Collections.Generic.List[string]]::new()
    try {
        foreach ($record in $plan.Files) {
            $destination = Assert-TextureRecord $record
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            $inputStream = [IO.File]::Open($record.SourcePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
            try {
                $outputStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                try { $inputStream.CopyTo($outputStream); $outputStream.Flush($true) }
                finally { $outputStream.Dispose() }
            } finally { $inputStream.Dispose() }
            if ((Get-IntegrationHash $destination) -ne $record.SHA256 -or
                (Get-IntegrationHash $record.SourcePath) -ne $record.SHA256) { throw "Copied texture differs: $($record.Name)" }
            $copied.Add($record.Path)
        }
        Assert-IntegrationBaseline $snapshot
        if ((Get-IntegrationHash $planFile) -ne $planHash -or
            (Get-IntegrationHash $configurationPath) -ne $plan.ConfigurationSHA256 -or
            (Get-IntegrationHash (Resolve-IntegrationFile $snapshot.Target $permission.Path)) -ne $permission.SHA256) {
            throw 'Plan, configuration or authorization changed during import.'
        }
        # Runtime consumers read only these relative target paths, never SourceRoots/SourcePath.
        $manifest = [ordered]@{Schema='AMXDENIS_COCKPIT_TEXTURES_1'; ModelPath=$configuration.InternalModel.Path;
            ModelSHA256=$configuration.InternalModel.SHA256; Directory=$textureDirectory;
            Permission=$permission; PlanSHA256=$planHash; InventorySHA256=$plan.InventorySHA256;
            State='IMPLEMENTADO_NAO_VALIDADO'; Complete=[bool]$plan.Complete; NativeValidated=$false;
            MissingTextures=@($plan.MissingTextures);
            Files=@($plan.Files | Select-Object Name,Path,Bytes,SHA256,SourceIndex,SourceRelative)}
        Write-IntegrationJson $manifestPath $manifest
        Write-IntegrationJson $reportFile ([ordered]@{Schema='AMXDENIS_TEXTURE_IMPORT_RESULT_1'; Passed=$true;
            CopiedFiles=$copied.Count; MissingTextures=@($plan.MissingTextures); Complete=[bool]$plan.Complete;
            ManifestSHA256=(Get-IntegrationHash $manifestPath); ProtectedBaselinePreserved=$true;
            SourceFilesPreserved=$true; NativeValidated=$false; CompletedUtc=[DateTime]::UtcNow.ToString('o')})
    } catch {
        $failure = $_
        if (-not (Test-Path -LiteralPath $reportFile)) {
            Write-IntegrationJson $reportFile ([ordered]@{Schema='AMXDENIS_TEXTURE_IMPORT_RESULT_1'; Passed=$false;
                Error=$failure.Exception.Message; VerifiedCopiedFiles=$copied.ToArray(); NativeValidated=$false;
                Recovery='Preserve files and intent; restore only with a verified ownership receipt. No automatic deletion.'})
        }
        throw $failure
    }
    Write-Output "REV07_TEXTURE_IMPORT_OK|files=$($copied.Count)|missing=$(@($plan.MissingTextures).Count)|native=false"
    return
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
if ($manifest.Schema -ne 'AMXDENIS_COCKPIT_TEXTURES_1' -or
    $manifest.ModelSHA256 -ne $configuration.InternalModel.SHA256 -or $manifest.Directory -ne $textureDirectory -or
    $manifest.Permission.SHA256 -ne $permission.SHA256 -or $manifest.NativeValidated -ne $false -or
    $manifest.Complete -ne (@($manifest.MissingTextures).Count -eq 0) -or -not @($manifest.Files).Count) {
    throw 'Unexpected local texture manifest.'
}
$seen = @{}
foreach ($record in $manifest.Files) {
    $path = Assert-TextureRecord $record
    if ($seen.ContainsKey($record.Path) -or (Get-IntegrationHash $path) -ne $record.SHA256 -or
        (Get-Item -LiteralPath $path).Length -ne $record.Bytes) { throw "Local texture changed or is missing: $($record.Name)" }
    $seen[$record.Path] = $true
}
$installed = @(Get-ChildItem -LiteralPath (Resolve-IntegrationFile $snapshot.Target $textureDirectory) -Recurse -Force)
if (@($installed | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count -or
    @($installed | Where-Object { -not $_.PSIsContainer }).Count -ne $seen.Count) { throw 'Unexpected resources or links in the internal texture directory.' }
Write-IntegrationJson $reportFile ([ordered]@{Schema='AMXDENIS_TEXTURE_VERIFY_1'; Passed=$true;
    FilesChecked=$seen.Count; SourceRootsRead=$false; Complete=[bool]$manifest.Complete;
    MissingTextures=@($manifest.MissingTextures); NativeValidated=$false;
    ManifestSHA256=(Get-IntegrationHash $manifestPath); ProtectedBaselinePreserved=$true})
Write-Output "REV07_TEXTURE_VERIFY_OK|files=$($seen.Count)|missing=$(@($manifest.MissingTextures).Count)|source_roots_read=false|native=false"