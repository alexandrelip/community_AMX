[CmdletBinding()]
param(
    [ValidateSet('Prepare', 'Start', 'Inspect', 'Cleanup')][string]$Action = 'Prepare',
    [Parameter(Mandatory)][string]$RunRoot,
    [string]$SnapshotRoot,
    [string]$DcsRoot = 'D:\Program Files\DCS World',
    [switch]$AllowIncompleteTextures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$target = Split-Path -Parent $PSScriptRoot
$run = Assert-IntegrationPath $RunRoot
if ($run -eq $target -or $run.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Viewer evidence must remain outside the repository.'
}
$savedGames = Join-Path $env:USERPROFILE 'Saved Games'

function Get-ViewerProfilePath {
    param([string]$SavedGamesRoot, [string]$ProfileName)
    if ($ProfileName -cnotmatch '^edModelViewer\.AMXDENIS-REV07-[A-Za-z0-9_-]+$') {
        throw 'Only a dedicated AMXDENIS REV07 viewer profile is allowed.'
    }
    $root = [IO.Path]::GetFullPath($SavedGamesRoot).TrimEnd('\')
    $path = [IO.Path]::GetFullPath((Join-Path $root $ProfileName))
    $current = $path
    while ($current) {
        if ((Test-Path -LiteralPath $current) -and
            ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Viewer profile paths cannot contain links.'
        }
        $current = Split-Path -Parent $current
    }
    if ((Split-Path -Parent $path) -ne $root) { throw 'Viewer profile escaped Saved Games.' }
    return $path
}

function Resolve-ViewerFile {
    param([string]$ProfilePath, [string]$Relative)
    $parts = $Relative.Replace('\', '/').Split('/')
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '[<>:"|?*\x00-\x1f]' -or
        @($parts | Where-Object { -not $_ -or $_ -in @('.', '..', '.git') -or $_ -match '[. ]$' }).Count) {
        throw 'Unsafe viewer-relative file path.'
    }
    $path = [IO.Path]::GetFullPath((Join-Path $ProfilePath $Relative))
    if (-not $path.StartsWith($ProfilePath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Viewer file escaped its profile.'
    }
    $current = $path
    while ($current -and $current.Length -ge $ProfilePath.Length) {
        if ((Test-Path -LiteralPath $current) -and
            ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Viewer files cannot use linked paths.'
        }
        $current = Split-Path -Parent $current
    }
    return $path
}

function Write-NewViewerText {
    param([string]$ProfilePath, [string]$Relative, [string]$Text)
    $path = Resolve-ViewerFile $ProfilePath $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text + "`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally { $stream.Dispose() }
}

function Get-ViewerAutoexec {
    param([string]$ProfileName)
    $null = Get-ViewerProfilePath (Join-Path $env:USERPROFILE 'Saved Games') $ProfileName
    return @'
local lfs = require("lfs")
local logger = require("log")
local directory = lfs.writedir():gsub("\\", "/"):gsub("/+$", "")
local expected = "__PROFILE_NAME__"
assert(directory:match("([^/]+)$"):lower() == expected:lower(), "Unexpected AMXDENIS viewer profile")
local model_root = directory .. "/Model"
local texture_root = model_root .. "/Textures"
assert(lfs.attributes(texture_root, "mode") == "directory", "Local REV07 textures are absent")
mount_vfs_models_path(model_root)
mount_vfs_texture_path(texture_root)
logger.write("AMXDENIS_VIEWER", logger.INFO, "PRIVATE_PROFILE=" .. directory)
logger.write("AMXDENIS_VIEWER", logger.INFO, "TEXTURE_ROOT=" .. texture_root)
logger.write("AMXDENIS_VIEWER", logger.INFO, "MODEL_REQUEST=" .. model_root .. "/AMX_COCKPIT_REV07_184.edm")
LoadModel(model_root .. "/AMX_COCKPIT_REV07_184.edm")
logger.write("AMXDENIS_VIEWER", logger.INFO, "MODEL_LOAD_RETURNED; visual inspection still required; no cockpit runtime loaded")
'@.Replace('__PROFILE_NAME__', $ProfileName)
}

function Get-ViewerArguments {
    param([string]$ProfileName)
    $null = Get-ViewerProfilePath (Join-Path $env:USERPROFILE 'Saved Games') $ProfileName
    # ModelViewer2's embedded Shortcuts help documents -w as its write subdirectory.
    return @('-w', $ProfileName)
}

function Assert-ViewerEnvironment {
    if (@(Get-Process -Name DCS,DCS_updater,ModelViewer,ModelViewer2 -ErrorAction SilentlyContinue).Count) {
        throw 'Another simulator/viewer session is active; no process will be terminated or reused.'
    }
}

function Get-PlainFileHash {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Assert-ViewerPreservation {
    param($State)
    foreach ($file in @($State.Protected) + @($State.SourceFiles)) {
        if ((Get-PlainFileHash $file.Path) -ne $file.SHA256) {
            throw "Protected file changed; preserve the newer state, never restore automatically: $($file.Path)"
        }
    }
}

function Read-ViewerLog {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    $reader = [IO.StreamReader]::new($stream)
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

if ($Action -eq 'Prepare') {
    Assert-ViewerEnvironment
    if (-not $SnapshotRoot) { throw 'A verified original snapshot is required.' }
    $snapshot = Read-IntegrationSnapshot $SnapshotRoot $target
    Assert-IntegrationBaseline $snapshot
    foreach ($root in @($snapshot.Source, $snapshot.Root)) {
        if ($run -eq $root -or $run.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Viewer runs cannot overwrite the source or immutable backups.'
        }
    }
    $statePath = Join-Path $run 'viewer-run.json'
    if (Test-Path -LiteralPath $statePath) { throw 'Viewer run already prepared; use Start or a new run.' }
    $configurationPath = Resolve-IntegrationFile $target 'Config/AMXDENIS_INTEGRATION.json'
    $manifestPath = Resolve-IntegrationFile $target 'Config/AMXDENIS_TEXTURES.json'
    $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json -DateKind String
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
    if ($configuration.InternalModel.Path -cne 'Shapes/AMX_COCKPIT_REV07_184.edm' -or
        $configuration.InternalModel.SHA256 -ne $manifest.ModelSHA256) { throw 'Only the configured unchanged REV07 may be previewed.' }
    if (-not $manifest.Complete -and -not $AllowIncompleteTextures) {
        throw 'Viewer preview has unresolved textures; explicit AllowIncompleteTextures is required. This is not flight approval.'
    }
    $permission = Assert-IntegrationPermission $target $configuration 'REV07 internal model'
    $texturePermission = Assert-IntegrationPermission $target $configuration 'REV07 textures and indicator resources'
    & (Join-Path $PSScriptRoot 'Import-AMXDENISCockpitTextures.ps1') -Action Verify -SnapshotRoot $SnapshotRoot `
        -ReportPath (Join-Path $run 'viewer-textures-verified.json') | Out-Null
    $executable = Join-Path $DcsRoot 'bin\ModelViewer2.exe'
    $lua = Join-Path $DcsRoot 'bin\luae.exe'
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf) -or -not (Test-Path -LiteralPath $lua -PathType Leaf)) {
        throw 'DCS ModelViewer2 and Lua 5.1 are required; installation will not be modified.'
    }
    $profileName = 'edModelViewer.AMXDENIS-REV07-' + [guid]::NewGuid().ToString('N').Substring(0,12)
    $viewerProfile = Get-ViewerProfilePath $savedGames $profileName
    if (Test-Path -LiteralPath $viewerProfile) { throw 'Viewer profile already exists.' }
    $normalViewer = Join-Path $savedGames 'edModelViewerTrunk'
    $normalDcs = Join-Path $savedGames 'DCS'
    $protectedPaths = @((Join-Path $normalDcs 'Config\options.lua'), (Join-Path $normalDcs 'Scripts\Export.lua'),
        (Join-Path $DcsRoot 'Config\ModelViewer\autoexec.lua'), (Join-Path $DcsRoot 'Config\ModelViewer.lua'),
        (Join-Path $DcsRoot 'Config\ModelViewer_main.cfg'))
    foreach ($relative in @('autoexec.lua','Default.mvs','Config\ModelViewer2.json','Config\ModelViewer2.lua',
        'Config\imgui.ini','Config\imgui_toolbox.json')) { $protectedPaths += Join-Path $normalViewer $relative }
    $index = 0
    $protected = foreach ($path in $protectedPaths) {
        $hash = Get-PlainFileHash $path
        $backup = Join-Path $run ('Protected\' + $index++ + '.before')
        if ($hash) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
            [IO.File]::Copy($path, $backup, $false)
            if ((Get-PlainFileHash $backup) -ne $hash -or (Get-PlainFileHash $path) -ne $hash) { throw 'Protected settings changed during snapshot.' }
        }
        [pscustomobject]@{Path=$path; SHA256=$hash; Backup=$(if ($hash) { $backup } else { $null })}
    }
    $sourceFiles = [Collections.Generic.List[object]]::new()
    foreach ($path in @($configurationPath, $manifestPath, (Resolve-IntegrationFile $target $permission.Path),
        (Resolve-IntegrationFile $target 'Shapes/AMX.edm'), (Resolve-IntegrationFile $target 'Shapes/AMX.lods'))) {
        $sourceFiles.Add([pscustomobject]@{Path=$path; SHA256=(Get-IntegrationHash $path)})
    }
    $copies = @([pscustomobject]@{Source=$configuration.InternalModel.Path; Relative='Model/AMX_COCKPIT_REV07_184.edm';
        SHA256=$configuration.InternalModel.SHA256; Bytes=$configuration.InternalModel.Bytes})
    $copies += @($manifest.Files | ForEach-Object {
        [pscustomobject]@{Source=$_.Path; Relative=('Model/Textures/' + [IO.Path]::GetFileName($_.Path)); SHA256=$_.SHA256; Bytes=$_.Bytes}
    })
    foreach ($relative in @('LICENSE', 'Doc/Integration/PERMISSIONS.json', 'Doc/Integration/Notices/F5EM-NOTICE.txt')) {
        $file = Resolve-IntegrationFile $target $relative
        $copies += [pscustomobject]@{Source=$relative; Relative=('Notices/' + [IO.Path]::GetFileName($relative));
            SHA256=(Get-IntegrationHash $file); Bytes=(Get-Item -LiteralPath $file).Length}
    }
    Write-IntegrationJson (Join-Path $run 'viewer-intent.json') ([ordered]@{Schema='AMXDENIS_VIEWER_INTENT_1';
        Profile=$viewerProfile; ProfileName=$profileName; Copies=$copies; Protected=$protected; NativeCockpitValidated=$false})
    New-Item -ItemType Directory -Path $viewerProfile, (Join-Path $viewerProfile 'Config'), (Join-Path $viewerProfile 'Logs') | Out-Null
    foreach ($file in $copies) {
        $source = Resolve-IntegrationFile $target $file.Source
        $destination = Resolve-ViewerFile $viewerProfile $file.Relative
        if ((Get-IntegrationHash $source) -ne $file.SHA256) { throw 'Viewer source changed before copying.' }
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        [IO.File]::Copy($source, $destination, $false)
        if ((Get-PlainFileHash $destination) -ne $file.SHA256 -or (Get-Item -LiteralPath $destination).Length -ne $file.Bytes -or
            (Get-IntegrationHash $source) -ne $file.SHA256) { throw 'Viewer copy differs from its source.' }
        $sourceFiles.Add([pscustomobject]@{Path=$source; SHA256=$file.SHA256})
    }
    Write-NewViewerText $viewerProfile 'autoexec.lua' (Get-ViewerAutoexec $profileName)
    $preferences = [ordered]@{config_version=1;
        AppPrefs=@{saveSession=$true;showDebugConsole=$false;showDebugWidget=$false;desiredFPS=60;useFPSLimiter=$true};
        MainWindow=@{Maximized=$true;xPos=0;yPos=0;xSize=1600;ySize=900};
        SessionPlugin=@{UseDefaultSession=$false};
        FileLoader=@{LastDir=(Join-Path $viewerProfile 'Model').Replace('\','/');RescentFiles=@()};
        RenderWidget=@{msaa=0;shadows=$true;statistics=$false;xRes=1500;yRes=800}}
    Write-NewViewerText $viewerProfile 'Config/ModelViewer2.json' ($preferences | ConvertTo-Json -Depth 5)
    $autoexec = (Join-Path $viewerProfile 'autoexec.lua').Replace('\','/')
    $syntax = @(& $lua -e ('assert(_VERSION == "Lua 5.1"); assert(loadfile([[' + $autoexec + ']])); print("AMXDENIS_VIEWER_LUA_OK")') 2>&1)
    $syntax | Write-Output
    if ($LASTEXITCODE -ne 0 -or ($syntax -join "`n") -notmatch '(?m)^AMXDENIS_VIEWER_LUA_OK\s*$') { throw 'Viewer autoexec syntax check failed.' }
    $assets = @($copies | Select-Object Relative,SHA256,Bytes)
    $assets += [pscustomobject]@{Relative='autoexec.lua';SHA256=(Get-PlainFileHash (Join-Path $viewerProfile 'autoexec.lua'));Bytes=(Get-Item -LiteralPath (Join-Path $viewerProfile 'autoexec.lua')).Length}
    $state = [ordered]@{Schema='AMXDENIS_VIEWER_RUN_1'; RunRoot=$run; ProfileName=$profileName; Profile=$viewerProfile;
        TargetRoot=$target; Executable=$executable; ExecutableSHA256=(Get-PlainFileHash $executable); DcsRoot=$DcsRoot;
        Model='AMX_COCKPIT_REV07_184.edm'; ModelSHA256=$configuration.InternalModel.SHA256;
        Prepared=$true; Textures=$manifest.Files.Count; MissingTextures=@($manifest.MissingTextures);
        TextureSetComplete=[bool]$manifest.Complete; NativeCockpitValidated=$false;
        Permission=$permission; TexturePermission=$texturePermission; Assets=$assets;
        Protected=$protected; SourceFiles=$sourceFiles.ToArray(); SnapshotRoot=$SnapshotRoot;
        PreparedUtc=[DateTime]::UtcNow.ToString('o')}
    Assert-ViewerPreservation $state
    Write-IntegrationJson $statePath $state
    Write-Output "AMXDENIS_VIEWER_PREPARED|profile=$profileName|textures=$($manifest.Files.Count)|missing=$(@($manifest.MissingTextures).Count)|$run"
    return
}

$state = Get-Content -LiteralPath (Join-Path $run 'viewer-run.json') -Raw | ConvertFrom-Json -DateKind String
if ($state.Schema -ne 'AMXDENIS_VIEWER_RUN_1' -or -not $state.Prepared -or
    $state.RunRoot -ne $run -or $state.TargetRoot -ne $target -or
    $state.Profile -ne (Get-ViewerProfilePath $savedGames $state.ProfileName)) { throw 'Invalid viewer run ownership.' }
Assert-ViewerPreservation $state
$activePath = Join-Path $run 'viewer-active.json'

if ($Action -eq 'Start') {
    Assert-ViewerEnvironment
    if (Test-Path -LiteralPath $activePath) { throw 'Viewer run was already started; use a new profile instead of overwriting it.' }
    foreach ($asset in $state.Assets) {
        if ((Get-PlainFileHash (Resolve-ViewerFile $state.Profile $asset.Relative)) -ne $asset.SHA256) { throw 'Prepared viewer assets changed.' }
    }
    if ((Get-PlainFileHash $state.Executable) -ne $state.ExecutableSHA256) { throw 'Viewer executable changed since preparation.' }
    $arguments = Get-ViewerArguments $state.ProfileName
    $requested = [DateTime]::UtcNow
    $process = Start-Process -FilePath $state.Executable -WorkingDirectory $state.DcsRoot -ArgumentList $arguments -PassThru
    Write-IntegrationJson $activePath ([ordered]@{Schema='AMXDENIS_VIEWER_ACTIVE_1';ProcessId=$process.Id;
        StartedUtc=$process.StartTime.ToUniversalTime().ToString('o');RequestedUtc=$requested.ToString('o');
        ProfileName=$state.ProfileName;Arguments=$arguments;UserRequestedOpen=$true;LeaveOpen=$true;AutoCloseAllowed=$false})
    Write-Output "AMXDENIS_VIEWER_STARTED|pid=$($process.Id)|profile=$($state.ProfileName)|awaiting_visual_confirmation=true"
    return
}

$owned = @()
if (Test-Path -LiteralPath $activePath) {
    $active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json -DateKind String
    $owned = @(Get-CimInstance Win32_Process -Filter "ProcessId = $($active.ProcessId)" | Where-Object {
        $_.Name -ieq 'ModelViewer2.exe' -and $_.ExecutablePath -ieq $state.Executable -and
        $_.CommandLine -match ('(?:^|\s)-w\s+"?' + [regex]::Escape($state.ProfileName) + '"?(?:\s|$)') -and
        $_.CreationDate.ToUniversalTime() -eq [DateTimeOffset]::Parse($active.StartedUtc).UtcDateTime
    })
}
if ($Action -eq 'Inspect') {
    $logPath = Resolve-ViewerFile $state.Profile 'Logs/model_viewer2.log'
    $text = Read-ViewerLog $logPath
    $privateMarker = $text.Contains('PRIVATE_PROFILE=' + $state.Profile.Replace('\','/'))
    $returned = $text.Contains('MODEL_LOAD_RETURNED; visual inspection still required')
    $errors = @($text -split "`r?`n" | Where-Object { $_ -match '^\d{4}-\d\d-\d\d \S+\s+(?:ERROR|ERROR_ONCE)\s' })
    $process = if ($owned.Count -eq 1) { Get-Process -Id $owned[0].ProcessId -ErrorAction Stop } else { $null }
    $inspected = [ordered]@{Schema='AMXDENIS_VIEWER_INSPECTION_1';RecordedUtc=[DateTime]::UtcNow.ToString('o');
        OwnedProcessRunning=($owned.Count -eq 1); PrivateProfileConfirmed=$privateMarker; LoadModelReturned=$returned;
        ProcessId=$(if ($process) {$process.Id} else {$null}); WindowTitle=$(if ($process) {$process.MainWindowTitle} else {''});
        TexturesStaged=$state.Textures; MissingLocalTextures=$state.MissingTextures; AllNativeErrors=$errors;
        ProtectedFilesUnchanged=$true; VisualAppearanceValidated=$false; NativeCockpitValidated=$false;
        ViewerLeftOpen=($owned.Count -eq 1); CleanupComplete=$false}
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $report = Join-Path $run ('viewer-inspection-' + $stamp + '.json')
    Write-IntegrationJson $report $inspected
    if ($text) { [IO.File]::Copy($logPath, (Join-Path $run ('model-viewer-' + $stamp + '.log')), $false) }
    Write-Output "AMXDENIS_VIEWER_INSPECTED|owned=$($owned.Count)|private=$privateMarker|load_returned=$returned|errors=$($errors.Count)|$report"
    return
}

if ($owned.Count -or @(Get-CimInstance Win32_Process -Filter "Name = 'ModelViewer2.exe'" | Where-Object {
    $_.CommandLine -match [regex]::Escape($state.ProfileName)
}).Count) { throw 'Close the requested viewer normally before cleanup; this tool never terminates it.' }
if (@(Get-ChildItem -LiteralPath $state.Profile -Recurse -Force | Where-Object {
    $_.Attributes -band [IO.FileAttributes]::ReparsePoint
}).Count) { throw 'Viewer profile contains links; cleanup refused.' }
foreach ($asset in $state.Assets) {
    if ((Get-PlainFileHash (Resolve-ViewerFile $state.Profile $asset.Relative)) -ne $asset.SHA256) {
        throw 'A viewer asset was edited after launch; preserve it and review before cleanup.'
    }
}
$archive = Join-Path $run ('ViewerProfile-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
$archived = foreach ($file in Get-ChildItem -LiteralPath $state.Profile -Recurse -File) {
    $relative = [IO.Path]::GetRelativePath($state.Profile,$file.FullName)
    $destination = Resolve-IntegrationFile $archive $relative
    $hash = Get-PlainFileHash $file.FullName
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    [IO.File]::Copy($file.FullName,$destination,$false)
    if ((Get-PlainFileHash $destination) -ne $hash) { throw 'Viewer archive verification failed; no cleanup.' }
    [pscustomobject]@{Relative=$relative;SHA256=$hash}
}
Write-IntegrationJson (Join-Path $archive 'archive-manifest.json') ([ordered]@{Files=@($archived);Profile=$state.Profile})
Remove-Item -LiteralPath $state.Profile -Recurse
Write-Output "AMXDENIS_VIEWER_CLEANED|profile=$($state.ProfileName)|archive=$archive"