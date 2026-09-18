Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-IntegrationPath {
    param([Parameter(Mandatory)][string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.StartsWith('\\') -or $full.TrimEnd('\') -eq [IO.Path]::GetPathRoot($full).TrimEnd('\')) {
        throw 'Network paths and drive roots are not integration directories.'
    }
    if ($full -match '^[A-Z]:\\(?:Windows|Program Files(?: \(x86\))?)(?:\\|$)' -or
        $full -match '\\Saved Games(?:\\|$)') {
        throw 'Integration repository/archive operations refuse installations and simulator profiles.'
    }
    $current = $full
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Linked integration path refused: $current"
            }
        }
        $current = Split-Path -Parent $current
    }
    return $full.TrimEnd('\')
}

function Resolve-IntegrationFile {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Relative)
    $rootPath = Assert-IntegrationPath $Root
    $parts = $Relative.Replace('\', '/').Split('/')
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '[<>:"|?*\x00-\x1f]' -or
        @($parts | Where-Object { -not $_ -or $_ -in @('.', '..', '.git') -or $_ -match '[. ]$' }).Count) {
        throw "Invalid integration-relative path: $Relative"
    }
    $full = Assert-IntegrationPath (Join-Path $rootPath $Relative)
    if (-not $full.StartsWith($rootPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Integration path escaped its root.'
    }
    return $full
}

function Get-IntegrationHash {
    param([Parameter(Mandatory)][string]$Path)
    $full = Assert-IntegrationPath $Path
    if (-not (Test-Path -LiteralPath $full)) { return $null }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Expected a file: $full" }
    return (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
}

function Write-IntegrationJson {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Data)
    $full = Assert-IntegrationPath $Path
    $text = $Data | ConvertTo-Json -Depth 12
    New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
    $stream = [IO.File]::Open($full, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($text + "`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally { $stream.Dispose() }
}

function Read-IntegrationSnapshot {
    param([Parameter(Mandatory)][string]$SnapshotRoot, [Parameter(Mandatory)][string]$TargetRoot)
    $snapshotPath = Assert-IntegrationPath $SnapshotRoot
    $targetPath = Assert-IntegrationPath $TargetRoot
    $manifestPath = Join-Path $snapshotPath 'snapshot.json'
    $manifestHash = Get-IntegrationHash $manifestPath
    $proof = Get-Content -LiteralPath (Join-Path $snapshotPath 'verification.json') -Raw | ConvertFrom-Json -DateKind String
    if ($proof.Schema -ne 'AMXDENIS_SNAPSHOT_VERIFICATION_1' -or
        $proof.SourceAndCopyHashesMatch -ne $true -or $proof.SnapshotSHA256 -ne $manifestHash) {
        throw 'Snapshot has no matching verification proof.'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -DateKind String
    if ($manifest.Schema -ne 'AMXDENIS_SNAPSHOT_1' -or $manifest.Id -ne $proof.Id -or
        $proof.Files -ne $manifest.Files.Count -or
        (Assert-IntegrationPath $manifest.Roots.Target) -ne $targetPath -or
        (Assert-IntegrationPath $manifest.Roots.Source) -eq $targetPath -or
        $snapshotPath.StartsWith($targetPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Snapshot identity or ownership is invalid.'
    }
    $files = @{}
    foreach ($record in $manifest.Files | Where-Object { $_.Root -eq 'Target' -and $_.Path -notmatch '^\.git[\\/]' }) {
        $null = Resolve-IntegrationFile $targetPath $record.Path
        if ($files.ContainsKey($record.Path) -or $record.SHA256 -notmatch '^[A-Fa-f0-9]{64}$') {
            throw 'Duplicate or invalid baseline record.'
        }
        $files[$record.Path] = $record
    }
    if ($files.Count -eq 0) { throw 'Empty target baseline.' }
    return [pscustomobject]@{Id=$manifest.Id; Root=$snapshotPath; Target=$targetPath;
        Source=(Assert-IntegrationPath $manifest.Roots.Source); SHA256=$manifestHash; Files=$files}
}

function Assert-IntegrationBaseline {
    param([Parameter(Mandatory)]$Snapshot, [string[]]$Except = @())
    foreach ($record in $Snapshot.Files.Values) {
        if ($record.Path -in $Except) { continue }
        if ((Get-IntegrationHash (Resolve-IntegrationFile $Snapshot.Target $record.Path)) -ne $record.SHA256) {
            throw "Protected baseline changed: $($record.Path)"
        }
    }
}

function Assert-IntegrationPermission {
    param(
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)]$Configuration,
        [Parameter(Mandatory)][string]$Component
    )
    $entries = @($Configuration.Permissions | Where-Object { $_.Component -eq $Component })
    if ($entries.Count -ne 1 -or $entries[0].State -ne 'AUTHORIZED_LOCAL' -or
        [string]::IsNullOrWhiteSpace($entries[0].Evidence)) {
        throw "Local permission is not recorded: $Component"
    }
    $path = Resolve-IntegrationFile $TargetRoot $entries[0].Evidence
    $hash = Get-IntegrationHash $path
    if (-not $hash) { throw "Local permission evidence is absent: $Component" }
    $evidence = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -DateKind String
    if ($evidence.Schema -ne 'AMXDENIS_LOCAL_PERMISSION_1' -or
        $evidence.State -ne 'AUTHORIZED_LOCAL' -or $evidence.Scope -ne 'LOCAL_AMXDENIS_M1' -or
        $evidence.EvidenceType -ne 'EXPLICIT_USER_DECLARATION' -or
        [string]::IsNullOrWhiteSpace($evidence.Statement) -or
        [string]::IsNullOrWhiteSpace($evidence.DeclaredBy) -or
        $Component -cnotin $evidence.Components -or
        $evidence.IdentityChangesAuthorized -ne $false -or
        $evidence.LicenseCheckBypassAuthorized -ne $false -or
        $evidence.OriginalNoticesMustBePreserved -ne $true) {
        throw "Permission evidence does not cover the declared local use: $Component"
    }
    if ((Get-IntegrationHash $path) -ne $hash) { throw 'Permission evidence changed while being read.' }
    return [pscustomobject]@{Component=$Component; Path=$entries[0].Evidence; SHA256=$hash;
        State='AUTHORIZED_LOCAL'; Scope=$evidence.Scope; EvidenceType=$evidence.EvidenceType}
}

Export-ModuleMember -Function Assert-IntegrationPath, Resolve-IntegrationFile, Get-IntegrationHash,
    Write-IntegrationJson, Read-IntegrationSnapshot, Assert-IntegrationBaseline, Assert-IntegrationPermission