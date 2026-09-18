[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Python,
    [string]$CandidateRoot,
    [string]$ReportRoot,
    [string]$Lua = 'D:\Program Files\DCS World\bin\luae.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) { throw 'An explicit Python interpreter is required.' }
if ([bool]$CandidateRoot -ne [bool]$ReportRoot) { throw 'CandidateRoot and ReportRoot must be supplied together.' }
$scripts = @(Get-ChildItem -LiteralPath (Join-Path $root 'Tools'), $PSScriptRoot -Recurse -File |
    Where-Object { $_.Extension -in @('.ps1', '.psm1') })
foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($errors.Message -join "`n") }
}
Write-Output "AMXDENIS POWERSHELL SYNTAX: $($scripts.Count)/$($scripts.Count) files parsed"
$guardOutput = @(& (Join-Path $PSScriptRoot 'tests\test_integration.ps1'))
$guardOutput | Write-Output
$guardResult = [regex]::Match(($guardOutput -join "`n"), 'AMXDENIS INTEGRATION GUARDS: (\d+)/(\d+) checks passed')
if (-not $guardResult.Success -or [int]$guardResult.Groups[1].Value -le 0 -or
    $guardResult.Groups[1].Value -ne $guardResult.Groups[2].Value) { throw 'Integration guard result is missing or failed.' }
$textureOutput = @(& (Join-Path $PSScriptRoot 'tests\test_texture_import.ps1'))
$textureOutput | Write-Output
$textureResult = [regex]::Match(($textureOutput -join "`n"), '(?m)^AMXDENIS TEXTURE GUARDS: (\d+)/(\d+) checks passed\s*$')
if (-not $textureResult.Success -or [int]$textureResult.Groups[1].Value -le 0 -or
    $textureResult.Groups[1].Value -ne $textureResult.Groups[2].Value) { throw 'Texture import guard result is missing or failed.' }
$viewerOutput = @(& (Join-Path $PSScriptRoot 'tests\test_viewer.ps1'))
$viewerOutput | Write-Output
$viewerResult = [regex]::Match(($viewerOutput -join "`n"), '(?m)^AMXDENIS VIEWER GUARDS: (\d+)/(\d+) checks passed\s*$')
if (-not $viewerResult.Success -or [int]$viewerResult.Groups[1].Value -le 0 -or
    $viewerResult.Groups[1].Value -ne $viewerResult.Groups[2].Value) { throw 'Viewer safety guard result is missing or failed.' }
$anchorOutput = @(& (Join-Path $PSScriptRoot 'tests\test_display_anchors.ps1'))
$anchorOutput | Write-Output
$anchorResult = [regex]::Match(($anchorOutput -join "`n"), '(?m)^AMXDENIS ANCHOR GUARDS: (\d+)/(\d+) checks passed\s*$')
if (-not $anchorResult.Success -or [int]$anchorResult.Groups[1].Value -le 0 -or
    $anchorResult.Groups[1].Value -ne $anchorResult.Groups[2].Value) { throw 'Anchor measurement guard result is missing or failed.' }
foreach ($test in @('test_cockpit_inventory.py', 'test_candidate_builder.py')) {
    $pythonOutput = @(& $Python -B (Join-Path $PSScriptRoot ('tests\' + $test)) 2>&1)
    $pythonExit = $LASTEXITCODE
    $pythonOutput | Write-Output
    $text = $pythonOutput -join "`n"
    $pythonResult = [regex]::Match($text, '(?m)^Ran (\d+) tests? in ')
    if ($pythonExit -ne 0 -or -not $pythonResult.Success -or [int]$pythonResult.Groups[1].Value -le 0 -or
        $text -notmatch '(?m)^OK\s*$' -or $text -match 'FAILED|Traceback|skipped=') { throw "Python test $test failed or produced no complete positive result." }
}
Write-Output 'AMXDENIS INFRASTRUCTURE: BANCADA (no cockpit, Lua runtime or native acceptance implied)'
if (-not (Test-Path -LiteralPath $Lua -PathType Leaf)) { throw 'An explicit Lua 5.1 interpreter is required.' }
$observerOutput = @(& $Lua (Join-Path $PSScriptRoot 'tests\test_native_observer.lua') $root 2>&1)
$observerExit = $LASTEXITCODE
$observerOutput | Write-Output
$observerText = $observerOutput -join "`n"
$observerResult = [regex]::Match($observerText, '(?m)^AMXDENIS NATIVE OBSERVER: (\d+)/(\d+) checks passed\s*$')
if ($observerExit -ne 0 -or -not $observerResult.Success -or [int]$observerResult.Groups[1].Value -le 0 -or
    $observerResult.Groups[1].Value -ne $observerResult.Groups[2].Value -or $observerText -match '\[FAIL\]|stack traceback:') {
    throw 'Native observer fixture checks failed; no simulator was launched.'
}
if ($CandidateRoot) {
    & (Join-Path $root 'Tools\Test-AMXDENISCandidate.ps1') -CandidateRoot $CandidateRoot -ReportRoot $ReportRoot -Lua $Lua
}