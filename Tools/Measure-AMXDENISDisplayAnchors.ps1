[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryPath,
    [Parameter(Mandatory)][string]$ReportPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$target = Split-Path -Parent $PSScriptRoot
$configuration = Get-Content -LiteralPath (Join-Path $target 'Config\AMXDENIS_INTEGRATION.json') -Raw | ConvertFrom-Json -DateKind String
$inventoryFile = Assert-IntegrationPath $InventoryPath
$inventoryHash = Get-IntegrationHash $inventoryFile
$inventory = Get-Content -LiteralPath $inventoryFile -Raw | ConvertFrom-Json -DateKind String
$modelPath = Resolve-IntegrationFile $target $configuration.InternalModel.Path
if ($inventory.schema -ne 'AMXDENIS_COCKPIT_INVENTORY_1' -or
    $inventory.sha256 -ne $configuration.InternalModel.SHA256 -or
    (Get-IntegrationHash $modelPath) -ne $inventory.sha256) { throw 'Display measurements require the current REV07 inventory and model.' }

function Get-StaticAnchorPosition {
    param($Connector)
    # These specific REV07 anchors are a single transform under the identity root.
    # Do not reuse the historical evaluator that omitted animation base transforms.
    if ($Connector.ancestry.Count -ne 2 -or $Connector.ancestry[0].node.type -ne 'TransformNode' -or
        $Connector.ancestry[0].index -ne $Connector.parent -or $Connector.ancestry[0].node.parent_idx -ne 0 -or
        $Connector.ancestry[1].index -ne 0 -or $Connector.ancestry[1].node.type -ne 'Node' -or
        $Connector.ancestry[1].node.parent_idx -ne -1) { throw 'Unsupported or animated display anchor ancestry; no guessed transform.' }
    $matrix = @($Connector.ancestry[0].node.matrix)
    if ($matrix.Count -ne 16) { throw 'Invalid static anchor matrix.' }
    foreach ($component in $matrix) {
        if ($component -isnot [ValueType] -or [double]::IsNaN([double]$component) -or
            [double]::IsInfinity([double]$component)) { throw 'Nonfinite static anchor matrix.' }
    }
    if ($matrix[3] -ne 0 -or $matrix[7] -ne 0 -or $matrix[11] -ne 0 -or $matrix[15] -ne 1) {
        throw 'Unsupported projective anchor matrix.'
    }
    return @([double]$matrix[12], [double]$matrix[13], [double]$matrix[14])
}

function Get-AnchorDistance {
    param([double[]]$Left, [double[]]$Right)
    if ($Left.Count -ne 3 -or $Right.Count -ne 3) { throw 'Three coordinates are required.' }
    $squared = 0.0
    for ($axis = 0; $axis -lt 3; $axis++) { $squared += ($Right[$axis] - $Left[$axis]) * ($Right[$axis] - $Left[$axis]) }
    $distance = [Math]::Sqrt($squared)
    if ([double]::IsNaN($distance) -or [double]::IsInfinity($distance) -or $distance -le 0) { throw 'Degenerate display connector distance.' }
    return $distance
}

$sets = @(
    @{Id='LEFT'; Names=@('FP_LMFD_Center','FP_LMFD_Bot','FP_LMFD_Right'); Parents=@(97,96,95)},
    @{Id='RIGHT'; Names=@('FP_RMFD_Center','FP_RMFD_Bot','FP_RMFD_Right'); Parents=@(100,99,98)},
    @{Id='LOWER_DUPLICATE'; Names=@('PTR-HUD-CENTER','PTR-HUD-DOWN','PTR-HUD-RIGHT'); Parents=@(92,93,94)},
    @{Id='UPPER_DUPLICATE'; Names=@('PTR-HUD-CENTER','PTR-HUD-DOWN','PTR-HUD-RIGHT'); Parents=@(108,107,106)}
)
$measurements = foreach ($set in $sets) {
    $points = @()
    for ($index = 0; $index -lt 3; $index++) {
        $found = @($inventory.connectors | Where-Object { $_.name -ceq $set.Names[$index] -and $_.parent -eq $set.Parents[$index] })
        if ($found.Count -ne 1) { throw 'REV07 display connector identity changed.' }
        $points += [pscustomobject]@{Name=$found[0].name;Parent=$found[0].parent;PositionDcsM=@(Get-StaticAnchorPosition $found[0])}
    }
    $width = Get-AnchorDistance $points[0].PositionDcsM $points[2].PositionDcsM
    $height = Get-AnchorDistance $points[0].PositionDcsM $points[1].PositionDcsM
    $dot = 0.0
    for ($axis = 0; $axis -lt 3; $axis++) {
        $dot += ($points[2].PositionDcsM[$axis] - $points[0].PositionDcsM[$axis]) *
            ($points[1].PositionDcsM[$axis] - $points[0].PositionDcsM[$axis])
    }
    [pscustomobject]@{Id=$set.Id;Connectors=$points;CenterToRightM=$width;CenterToDownM=$height;
        AxisDotNormalized=($dot / ($width * $height));
        NamesUnique=($set.Id -in @('LEFT','RIGHT'));NativeBindingValidated=$false;SourceModelChanged=$false}
}
$controls = foreach ($name in @('PTR-ARM-LAND-GEAR-084','PNT_912','PNT_1843','PNT_1844')) {
    $found = @($inventory.connectors | Where-Object { $_.name -ceq $name })
    if ($found.Count -ne 1) { throw 'Ambiguous REV07 control connector.' }
    $animations = foreach ($ancestor in $found[0].ancestry) {
        foreach ($channel in @('pos_data','rot_data','scale_data')) {
            if ($ancestor.node.PSObject.Properties[$channel]) {
                foreach ($track in $ancestor.node.$channel) {
                    [pscustomobject]@{Node=$ancestor.index;Name=$ancestor.node.name;Channel=$channel;
                        Argument=$track[0];KeyTimes=@($track[1] | ForEach-Object {$_.frame})}
                }
            }
        }
    }
    [pscustomobject]@{Connector=$name;Parent=$found[0].parent;AnimationTracks=@($animations);
        PositionEvaluated=$false;SemanticRoleValidated=$false;NativeInputValidated=$false}
}
if ((Get-IntegrationHash $modelPath) -ne $inventory.sha256 -or (Get-IntegrationHash $inventoryFile) -ne $inventoryHash) {
    throw 'Measurement input changed during inspection.'
}
$report = [ordered]@{Schema='AMXDENIS_REV07_DISPLAY_ANCHORS_1';ModelPath=$configuration.InternalModel.Path;
    ModelSHA256=$inventory.sha256;InventorySHA256=$inventoryHash;State='REVALIDAR';
    Evidence='Static connector records only; dimensions are center-to-anchor distances, not native display acceptance';
    NativeValidated=$false;RuntimeBindingsGenerated=$false;OriginalModelModified=$false;
    DisplaySets=@($measurements);ControlAnimationRecords=@($controls);
    Limitations=@('The lower and upper PTR-HUD triples remain name-ambiguous.',
        'ICP screen geometry, visual masks, pilot view and control semantics need REV07-specific validation.',
        'Animation channel numbers do not approve physical controls or effects on the flight model.')}
Write-IntegrationJson $ReportPath $report
Write-Output "AMXDENIS_REV07_ANCHORS_MEASURED|sets=$(@($measurements).Count)|controls=$(@($controls).Count)|native=false|$ReportPath"