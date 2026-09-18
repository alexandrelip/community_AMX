[CmdletBinding()]
param(
    [ValidateSet('Record', 'Preview', 'Apply')][string]$Action = 'Preview',
    [Parameter(Mandatory)][string]$SnapshotRoot,
    [Parameter(Mandatory)][string]$ReceiptPath,
    [string]$TargetRoot = (Split-Path -Parent $PSScriptRoot),
    [string[]]$OwnedPath = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AMXDENISIntegration.psm1') -Force
$snapshot = Read-IntegrationSnapshot $SnapshotRoot $TargetRoot
$receiptFile = Assert-IntegrationPath $ReceiptPath
foreach ($protectedRoot in @($snapshot.Target, $snapshot.Source, $snapshot.Root)) {
    if ($receiptFile -eq $protectedRoot -or $receiptFile.StartsWith($protectedRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Receipts must remain outside both repositories and the immutable snapshot.'
    }
}

if ($Action -eq 'Record') {
    if (-not $OwnedPath.Count -or (Test-Path -LiteralPath $receiptFile)) { throw 'Record requires explicit owned paths and a new receipt.' }
    $paths = @($OwnedPath | ForEach-Object { $_.Replace('\', '/') } | Sort-Object -Unique)
    Assert-IntegrationBaseline $snapshot -Except $paths
    $records = foreach ($relative in $paths) {
        $current = Resolve-IntegrationFile $snapshot.Target $relative
        $before = if ($snapshot.Files.ContainsKey($relative)) { $snapshot.Files[$relative].SHA256 } else { $null }
        $after = Get-IntegrationHash $current
        if ($before -eq $after) { continue }
        if ($before) {
            $saved = Resolve-IntegrationFile (Join-Path $snapshot.Root 'Target') $relative
            if ((Get-IntegrationHash $saved) -ne $before) { throw "Backup changed: $relative" }
        }
        [pscustomobject]@{Path=$relative; BeforeSHA256=$before; AfterSHA256=$after}
    }
    if (@($records).Count -eq 0) { throw 'No owned changes to record.' }
    Write-IntegrationJson $receiptFile ([ordered]@{Schema='AMXDENIS_INTEGRATION_RECEIPT_1';
        SnapshotId=$snapshot.Id; SnapshotSHA256=$snapshot.SHA256; TargetRoot=$snapshot.Target;
        CreatedUtc=[DateTime]::UtcNow.ToString('o'); Files=@($records)})
    Write-Output "INTEGRATION_RECEIPT_CREATED|files=$(@($records).Count)|$receiptFile"
    return
}

$receipt = Get-Content -LiteralPath $receiptFile -Raw | ConvertFrom-Json -DateKind String
if ($receipt.Schema -ne 'AMXDENIS_INTEGRATION_RECEIPT_1' -or $receipt.SnapshotId -ne $snapshot.Id -or
    $receipt.SnapshotSHA256 -ne $snapshot.SHA256 -or
    (Assert-IntegrationPath $receipt.TargetRoot) -ne $snapshot.Target -or -not $receipt.Files.Count) {
    throw 'Receipt does not belong to this verified snapshot and target.'
}
$seen = @{}
$plan = foreach ($record in $receipt.Files) {
    $relative = $record.Path.Replace('\', '/')
    $current = Resolve-IntegrationFile $snapshot.Target $relative
    if ($seen.ContainsKey($relative)) { throw 'Duplicate receipt path.' }
    $seen[$relative] = $true
    $before = if ($snapshot.Files.ContainsKey($relative)) { $snapshot.Files[$relative].SHA256 } else { $null }
    if ($record.BeforeSHA256 -ne $before -or $record.BeforeSHA256 -eq $record.AfterSHA256 -or
        ($null -ne $record.AfterSHA256 -and $record.AfterSHA256 -notmatch '^[A-Fa-f0-9]{64}$')) {
        throw "Receipt disagrees with baseline: $relative"
    }
    if ((Get-IntegrationHash $current) -ne $record.AfterSHA256) {
        throw "Later change detected; nothing restored: $relative"
    }
    $backup = if ($before) { Resolve-IntegrationFile (Join-Path $snapshot.Root 'Target') $relative } else { $null }
    if ($before -and (Get-IntegrationHash $backup) -ne $before) { throw "Backup changed: $relative" }
    [pscustomobject]@{Path=$relative; Current=$current; Backup=$backup;
        BeforeSHA256=$before; AfterSHA256=$record.AfterSHA256;
        Operation=$(if ($before) { 'Restore' } else { 'RemoveOwnedFile' })}
}
if ($Action -eq 'Preview') {
    $plan | Select-Object Path, Operation
    Write-Output "INTEGRATION_RESTORE_PREVIEW_OK|files=$(@($plan).Count)|no_changes=true"
    return
}

$journalRoot = Join-Path (Split-Path -Parent $receiptFile) ('Rollback-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $journalRoot | Out-Null
foreach ($record in $plan) {
    if ((Get-IntegrationHash $record.Current) -ne $record.AfterSHA256) { throw "Concurrent edit; rollback interrupted: $($record.Path)" }
    if ($record.AfterSHA256) {
        $archive = Resolve-IntegrationFile (Join-Path $journalRoot 'BeforeRollback') $record.Path
        New-Item -ItemType Directory -Path (Split-Path -Parent $archive) -Force | Out-Null
        Copy-Item -LiteralPath $record.Current -Destination $archive
        if ((Get-IntegrationHash $archive) -ne $record.AfterSHA256) { throw 'Pre-rollback archive is incomplete.' }
    }
}
Write-IntegrationJson (Join-Path $journalRoot 'plan.json') ([ordered]@{
    Schema='AMXDENIS_ROLLBACK_PLAN_1'; ReceiptSHA256=(Get-IntegrationHash $receiptFile); Files=@($plan)})
foreach ($record in $plan) {
    if ((Get-IntegrationHash $record.Current) -ne $record.AfterSHA256) { throw "Concurrent edit; rollback interrupted: $($record.Path)" }
    if ($record.Backup) {
        if ((Get-IntegrationHash $record.Backup) -ne $record.BeforeSHA256) { throw 'Snapshot changed during rollback.' }
        New-Item -ItemType Directory -Path (Split-Path -Parent $record.Current) -Force | Out-Null
        Copy-Item -LiteralPath $record.Backup -Destination $record.Current
    } else {
        Remove-Item -LiteralPath $record.Current
    }
    if ((Get-IntegrationHash $record.Current) -ne $record.BeforeSHA256) { throw "Rollback verification failed: $($record.Path)" }
}
Write-IntegrationJson (Join-Path $journalRoot 'result.json') ([ordered]@{
    Schema='AMXDENIS_ROLLBACK_RESULT_1'; Files=@($plan).Count; Restored=$true;
    GitChanged=$false; SourceChanged=$false; CompletedUtc=[DateTime]::UtcNow.ToString('o')})
Write-Output "INTEGRATION_RESTORE_OK|files=$(@($plan).Count)|journal=$journalRoot"