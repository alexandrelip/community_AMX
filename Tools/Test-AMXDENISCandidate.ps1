[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CandidateRoot,
    [Parameter(Mandatory)][string]$ReportRoot,
    [string]$Lua = 'D:\Program Files\DCS World\bin\luae.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$repo = Split-Path -Parent $PSScriptRoot
$candidate = Assert-IntegrationPath $CandidateRoot
$report = Assert-IntegrationPath $ReportRoot
$archive = Assert-IntegrationPath (Join-Path $env:LOCALAPPDATA 'AMXDENIS-Integration')
if ((Split-Path -Parent $candidate) -ne (Join-Path $archive 'Candidates') -or
    -not $report.StartsWith((Join-Path $archive 'Runs') + '\',[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Bench candidates and reports must remain in their dedicated local archive areas.'
}
foreach ($protectedRoot in @($repo,$candidate)) {
    if ($report -eq $protectedRoot -or $report.StartsWith($protectedRoot + '\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Bench reports must remain outside source and candidate.'
    }
}
if (Test-Path -LiteralPath $report) { throw 'Use a new bench report directory.' }
$manifestPath = Join-Path $candidate 'candidate-manifest.json'
$manifestHash = Get-IntegrationHash $manifestPath
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
if ($manifest.Schema -ne 'AMXDENIS_CANDIDATE_1' -or $manifest.AircraftType -ne 'AMXT_M' -or
    $manifest.PilotSeat -ne 1 -or $manifest.NativeValidated -ne $false -or
    $manifest.ExternalResourcesChanged -ne $false -or $manifest.FlightModelChanged -ne $false -or
    $manifest.DesktopCandidateOnly -ne $true -or $manifest.Files.Count -eq 0 -or
    $manifest.BuildId -notmatch '^[A-F0-9]{64}$' -or $manifest.InputSetSHA256 -notmatch '^[A-F0-9]{64}$') { throw 'Unexpected candidate identity.' }
$luaHash = (Get-FileHash -LiteralPath $Lua -Algorithm SHA256).Hash
if ($luaHash -ne $manifest.LuaExecutableSHA256) { throw 'Bench Lua differs from the recorded build toolchain.' }
$runnerHash = Get-IntegrationHash $PSCommandPath
foreach ($inputFile in $manifest.Inputs) {
    if ((Get-IntegrationHash (Resolve-IntegrationFile $repo $inputFile.Path)) -ne $inputFile.SHA256) {
        throw "Repository input changed since assembly: $($inputFile.Path)"
    }
}
$seen = @{}
foreach ($file in $manifest.Files) {
    if ($seen.ContainsKey($file.Path)) { throw 'Duplicate candidate manifest entry.' }
    $seen[$file.Path]=$true
    $path = Resolve-IntegrationFile $candidate $file.Path
    if ((Get-IntegrationHash $path) -ne $file.SHA256 -or (Get-Item -LiteralPath $path).Length -ne $file.Bytes) {
        throw "Candidate changed since assembly: $($file.Path)"
    }
}
$allFiles = @(Get-ChildItem -LiteralPath $candidate -Recurse -Force -File)
if ($allFiles.Count -ne $manifest.Files.Count + 1) { throw 'Unexpected files in candidate.' }
if (@($allFiles | Where-Object {$_.Extension -in @('.dll','.exe','.tx')}).Count) { throw 'Unexpected binary or conversion cache in initial candidate.' }
New-Item -ItemType Directory -Path $report | Out-Null
$results = [Collections.Generic.List[object]]::new()
try {
    $luaFiles = @($allFiles | Where-Object Extension -eq '.lua')
    $fileList = Join-Path $report 'syntax-files.txt'
    $luaFiles.FullName | Set-Content -LiteralPath $fileList -Encoding utf8NoBOM
    $code = 'assert(_VERSION=="Lua 5.1"); local n=0; for p in io.lines([[' + $fileList.Replace('\','/') +
        ']]) do assert(loadfile(p)); n=n+1 end; assert(n>0); print("AMXDENIS_SYNTAX_OK files="..n)'
    $syntaxOutput = @(& $Lua -e $code 2>&1)
    $syntaxExit = $LASTEXITCODE
    $syntaxOutput | Set-Content -LiteralPath (Join-Path $report 'syntax.log') -Encoding utf8NoBOM
    $syntaxText = $syntaxOutput -join "`n"
    if ($syntaxExit -ne 0 -or $syntaxText -notmatch ('(?m)^AMXDENIS_SYNTAX_OK files=' + $luaFiles.Count + '\s*$') -or
        $syntaxText -match '\[FAIL\]|stack traceback:') { throw 'Candidate Lua syntax check failed.' }
    $syntaxOutput | Write-Output
    foreach ($test in @(
        @{Name='registration';Marker='AMXDENIS REGISTRATION';Extra=@((Join-Path $repo 'ci\fixtures\original'))},
        @{Name='runtime';Marker='AMXDENIS RUNTIME';Extra=@()},
        @{Name='indicators';Marker='AMXDENIS INDICATORS';Extra=@()}
    )) {
        $testFile = Join-Path $repo ('ci\tests\test_' + $test.Name + '.lua')
        $testHash = Get-IntegrationHash $testFile
        $extraArguments = @($test.Extra)
        $output = @(& $Lua $testFile $candidate @extraArguments 2>&1)
        $exitCode = $LASTEXITCODE
        $output | Set-Content -LiteralPath (Join-Path $report ($test.Name + '.log')) -Encoding utf8NoBOM
        $text = $output -join "`n"
        $positive = [regex]::Match($text, '(?m)^' + [regex]::Escape($test.Marker) + ': (\d+)/(\d+) checks passed')
        if ($exitCode -ne 0 -or -not $positive.Success -or [int]$positive.Groups[1].Value -le 0 -or
            $positive.Groups[1].Value -ne $positive.Groups[2].Value -or $text -match '\[FAIL\]|stack traceback:') {
            $output | Write-Output
            throw "Candidate test $($test.Name) failed (exit=$exitCode)."
        }
        if ((Get-IntegrationHash $testFile) -ne $testHash) { throw 'Test code changed during execution.' }
        $results.Add([pscustomobject]@{Name=$test.Name;Checks=[int]$positive.Groups[1].Value;
            Passed=$true;TestSHA256=$testHash;OutputSHA256=(Get-IntegrationHash (Join-Path $report ($test.Name + '.log')))})
        $output | Write-Output
    }
    foreach ($file in $manifest.Files) {
        if ((Get-IntegrationHash (Resolve-IntegrationFile $candidate $file.Path)) -ne $file.SHA256) { throw 'A bench test modified its candidate.' }
    }
    foreach ($inputFile in $manifest.Inputs) {
        if ((Get-IntegrationHash (Resolve-IntegrationFile $repo $inputFile.Path)) -ne $inputFile.SHA256) { throw 'Repository input changed during bench validation.' }
    }
    if ((Get-IntegrationHash $manifestPath) -ne $manifestHash -or
        @(Get-ChildItem -LiteralPath $candidate -Recurse -Force -File).Count -ne $allFiles.Count -or
        (Get-IntegrationHash $PSCommandPath) -ne $runnerHash -or
        (Get-FileHash -LiteralPath $Lua -Algorithm SHA256).Hash -ne $luaHash) { throw 'Bench artifact or toolchain changed during validation.' }
    Write-IntegrationJson (Join-Path $report 'result.json') ([ordered]@{Schema='AMXDENIS_CANDIDATE_BENCH_1';
        BuildId=$manifest.BuildId;State='BANCADA';Passed=$true;Tests=$results.ToArray();LuaFiles=$luaFiles.Count;
        CandidateManifestSHA256=$manifestHash;InputSetSHA256=$manifest.InputSetSHA256;LuaVersion='5.1';LuaSHA256=$luaHash;
        RunnerSHA256=$runnerHash;CandidateFilesUnchanged=$true;RepositoryInputsUnchanged=$true;
        NativeValidated=$false;NativeMissionStarted=$false;RecordedUtc=[DateTime]::UtcNow.ToString('o')})
    Write-Output "AMXDENIS_CANDIDATE_BENCH_OK|id=$($manifest.BuildId)|native=false|$report"
} catch {
    if (-not (Test-Path -LiteralPath (Join-Path $report 'result.json'))) {
        Write-IntegrationJson (Join-Path $report 'result.json') ([ordered]@{Schema='AMXDENIS_CANDIDATE_BENCH_1';
            BuildId=$manifest.BuildId;State='FALHOU';Passed=$false;Tests=$results.ToArray();Error=$_.Exception.Message;
            NativeValidated=$false;NativeMissionStarted=$false})
    }
    throw
}