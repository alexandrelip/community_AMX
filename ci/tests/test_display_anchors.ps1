[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root 'Tools\Measure-AMXDENISDisplayAnchors.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors.Message -join "`n") }
foreach ($name in @('Get-StaticAnchorPosition','Get-AnchorDistance')) {
    $helper = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name}, $true)
    if (-not $helper) { throw 'Anchor measurement helper missing.' }
    . ([scriptblock]::Create($helper.Extent.Text))
}
$checks = 0
function Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Rejected {
    param([scriptblock]$Operation)
    $rejected = $false
    try { & $Operation | Out-Null } catch { $rejected = $true }
    Check $rejected 'Invalid anchor geometry was accepted.'
}
$matrix = @(1,0,0,0, 0,1,0,0, 0,0,1,0, 0.7,-0.4,0.16,1)
$connector = [pscustomobject]@{parent=97;ancestry=@(
    [pscustomobject]@{index=97;node=[pscustomobject]@{type='TransformNode';parent_idx=0;matrix=$matrix}},
    [pscustomobject]@{index=0;node=[pscustomobject]@{type='Node';parent_idx=-1}})}
$position = @(Get-StaticAnchorPosition $connector)
Check ($position.Count -eq 3 -and $position[0] -eq 0.7 -and $position[1] -eq -0.4 -and $position[2] -eq 0.16) 'Static EDM translation was read from the wrong matrix entries.'
Check ((Get-AnchorDistance @(0,0,0) @(0,3,4)) -eq 5) 'Distance is not Euclidean.'
Rejected { Get-AnchorDistance @(0,0,0) @(0,0,0) }
Rejected { Get-AnchorDistance @(0,0) @(0,3,4) }
Rejected { Get-AnchorDistance @(0,0,0) @([double]::NaN,0,0) }
Rejected { Get-AnchorDistance @(0,0,0) @([double]::PositiveInfinity,0,0) }
$connector.ancestry[0].node.type = 'ArgRotationNode'
Rejected { Get-StaticAnchorPosition $connector }
$connector.ancestry[0].node.type = 'TransformNode'
$connector.ancestry[0].node.parent_idx = 55
Rejected { Get-StaticAnchorPosition $connector }
$connector.ancestry[0].node.parent_idx = 0
$connector.ancestry[1].node.type = 'TransformNode'
Rejected { Get-StaticAnchorPosition $connector }
$connector.ancestry[1].node.type = 'Node'
$connector.ancestry[0].node.matrix[12] = [double]::NaN
Rejected { Get-StaticAnchorPosition $connector }
$connector.ancestry[0].node.matrix[12] = 0.7
$connector.ancestry[0].node.matrix[3] = 0.5
Rejected { Get-StaticAnchorPosition $connector }
$connector.ancestry[0].node.matrix[3] = 0
Check ((Get-StaticAnchorPosition $connector)[2] -eq 0.16) 'Restored valid anchor no longer resolves.'
Write-Output "AMXDENIS ANCHOR GUARDS: $checks/$checks checks passed"