[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tokens = $null
$errors = $null
$scriptPath = Join-Path $root 'Tools\Open-AMXDENISCockpit.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors.Message -join "`n") }
foreach ($name in @('Get-ViewerProfilePath','Resolve-ViewerFile','Write-NewViewerText','Get-ViewerAutoexec',
    'Get-ViewerArguments','Get-PlainFileHash','Assert-ViewerPreservation')) {
    $definition = $ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name}, $true)
    if (-not $definition) { throw "Viewer helper missing: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('AMXDENIS-Viewer-Guards-' + [guid]::NewGuid().ToString('N'))
$checks = 0
function Check {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Rejected {
    param([scriptblock]$Operation, [string]$Pattern)
    $message = $null
    try { & $Operation | Out-Null } catch { $message = $_.Exception.Message }
    Check ($null -ne $message -and $message -match $Pattern) "Expected $Pattern; received $message"
}
try {
    $savedGames = Join-Path $fixture 'Saved Games'
    New-Item -ItemType Directory -Path $savedGames | Out-Null
    $name = 'edModelViewer.AMXDENIS-REV07-fixture'
    $profilePath = Get-ViewerProfilePath $savedGames $name
    Check ($profilePath -eq (Join-Path $savedGames $name)) 'Private viewer path was not rooted correctly.'
    foreach ($invalid in @('DCS','edModelViewerTrunk','edModelViewer.Other','../DCS',
        'edModelViewer.AMXDENIS-REV07-..','edModelViewer.AMXDENIS-REV07-x\DCS')) {
        Rejected { Get-ViewerProfilePath $savedGames $invalid } 'dedicated'
    }
    $arguments = @(Get-ViewerArguments $name)
    Check ($arguments.Count -eq 2 -and $arguments[0] -ceq '-w' -and $arguments[1] -ceq $name) 'Viewer invocation lost the explicit write directory.'
    Check (-not (Test-Path -LiteralPath $profilePath)) 'Path validation unexpectedly created a profile.'
    foreach ($invalid in @('../outside','C:\outside','Config/../other','file:stream','file.','a//b','.git/config')) {
        Rejected { Resolve-ViewerFile $profilePath $invalid } 'Unsafe'
    }
    New-Item -ItemType Directory -Path $profilePath | Out-Null
    $outside = Join-Path $fixture 'outside'
    New-Item -ItemType Directory -Path $outside | Out-Null
    New-Item -ItemType Junction -Path (Join-Path $profilePath 'linked') -Target $outside | Out-Null
    Rejected { Resolve-ViewerFile $profilePath 'linked/unsafe' } 'linked'
    Remove-Item -LiteralPath (Join-Path $profilePath 'linked')
    $autoexec = Get-ViewerAutoexec $name
    Check ($autoexec.Contains($name) -and $autoexec.Contains('Unexpected AMXDENIS viewer profile')) 'Autoexec lost its own profile guard.'
    Check ($autoexec.Contains('mount_vfs_texture_path(texture_root)') -and $autoexec.Contains('directory .. "/Model"')) 'Autoexec is not using private model and texture copies.'
    Check ($autoexec.Contains('AMX_COCKPIT_REV07_184.edm') -and -not $autoexec.Contains('Cockpit_AJET')) 'Autoexec selected the old cockpit.'
    Check ($autoexec -notmatch 'SetArgument|AMX-A1M-DEV|manual amx|set_aircraft_draw_argument_value') 'Autoexec changes model pose or consults old workspaces.'
    Write-NewViewerText $profilePath 'autoexec.lua' $autoexec
    $file = Join-Path $profilePath 'autoexec.lua'
    $hash = Get-PlainFileHash $file
    Rejected { Write-NewViewerText $profilePath 'autoexec.lua' 'overwrite' } 'exist'
    Check ((Get-PlainFileHash $file) -eq $hash) 'Existing viewer file was overwritten.'
    $state = @{Protected=@(@{Path=$file;SHA256=$hash});SourceFiles=@(@{Path=(Join-Path $outside 'absent');SHA256=$null})}
    Assert-ViewerPreservation $state
    Check ($true) 'Unchanged inputs rejected.'
    [IO.File]::WriteAllText($file, 'later edit')
    Rejected { Assert-ViewerPreservation $state } 'Protected file changed'
    Check ((Get-Content -LiteralPath $file -Raw) -eq 'later edit') 'Preservation check restored over later work.'
    Check (@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -eq 'Stop-Process'}, $true)).Count -eq 0) 'Viewer helper can terminate a user process.'
    Write-Output "AMXDENIS VIEWER GUARDS: $checks/$checks checks passed"
} finally {
    if (Test-Path -LiteralPath (Join-Path $fixture 'Saved Games\edModelViewer.AMXDENIS-REV07-fixture\linked')) {
        Remove-Item -LiteralPath (Join-Path $fixture 'Saved Games\edModelViewer.AMXDENIS-REV07-fixture\linked')
    }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}