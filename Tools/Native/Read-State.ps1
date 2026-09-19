[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [string]$ReportPath,
    [double]$Since=[double]::NaN,
    [ValidateRange(65536,8388608)][int]$TailBytes=2097152
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Assert-NativeSampleIdentity($State,$Record) {
    $control=if($State.PSObject.Properties['ControlAircraft']){$State.ControlAircraft}else{'none'}
    if($control -notin @('none','OriginalAMXT_M','Su-25T')){throw 'Unsupported native control identity.'}
    if($control -ne 'none' -and (-not $State.PSObject.Properties['OperationalTest'] -or -not $State.OperationalTest)){
        throw 'Control sample requires operational opt-in.'
    }
    $expected=if($control -eq 'Su-25T'){'Su-25T'}else{'AMXT_M'}
    if($Record.aircraft -cne $expected -or $null -eq $Record.model_time -or $Record.model_time -is [string] -or
        [double]::IsNaN($Record.model_time) -or [double]::IsInfinity($Record.model_time)){
        throw 'Unexpected native sample identity.'
    }
}
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AMXDENISIntegration.psm1') -Force
$run=Assert-IntegrationPath $RunRoot
$runs=Assert-IntegrationPath (Join-Path $env:LOCALAPPDATA 'AMXDENIS-Integration/Runs')
if((Split-Path -Parent $run) -ne $runs -or (Split-Path -Leaf $run) -notmatch '^Native-REV07-[A-Za-z0-9_-]+$'){throw 'An owned native run is required.'}
$state=Get-Content -LiteralPath (Join-Path $run 'run.json') -Raw | ConvertFrom-Json -DateKind String
$expectedProfile=Join-Path (Join-Path $env:USERPROFILE 'Saved Games') $state.ProfileName
if($state.Schema -ne 'AMXDENIS_NATIVE_RUN_1' -or $state.RunRoot -ne $run -or
    $state.Profile -ne $expectedProfile -or $state.ProfileName -notmatch '^DCS\.AMXDENIS-[A-Za-z0-9_-]+$'){throw 'Native run/profile identity differs.'}
$log=Join-Path $state.Profile 'Logs/AMXDENIS-native.jsonl'
$ancestor=$log
while($ancestor){
    if((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked observation path refused.'}
    $ancestor=Split-Path -Parent $ancestor
}
$stream=[IO.FileStream]::new($log,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
$offset=[Math]::Max(0,$stream.Length-$TailBytes)
[void]$stream.Seek($offset,[IO.SeekOrigin]::Begin)
$reader=[IO.StreamReader]::new($stream)
try {if($offset -gt 0){[void]$reader.ReadLine()};$text=$reader.ReadToEnd()} finally {$reader.Dispose()}
$lines=$text.Split("`n")
$latest=$null
$batch=[Collections.Generic.List[object]]::new()
for($index=0;$index -lt $lines.Count-1;$index++){
    if(-not $lines[$index].Trim()){continue}
    $record=ConvertFrom-Json -InputObject $lines[$index] -Depth 40 -DateKind String
    if($record.kind -eq 'ERROR'){throw ('Native observer error: '+$record.message)}
    if($record.kind -eq 'STATE'){
        Assert-NativeSampleIdentity $state $record
        $latest=$record
        if(-not [double]::IsNaN($Since) -and $record.model_time -gt $Since){$batch.Add($record)}
    }
}
if(-not [double]::IsNaN($Since)){return $batch.ToArray()}
if($null -eq $latest){throw 'No complete native STATE record in the selected tail.'}
if($ReportPath){
    $report=Assert-IntegrationPath $ReportPath
    if(-not $report.StartsWith($run+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'State snapshot must remain inside its native run.'}
    Write-IntegrationJson $report ([ordered]@{Schema='AMXDENIS_NATIVE_STATE_SNAPSHOT_1';Run=$state.ProfileName;BuildId=$state.BuildId;
        Observed=$latest;RecordedUtc=[DateTime]::UtcNow.ToString('o');ObserverLogLength=(Get-Item -LiteralPath $log).Length;
        IncompleteFinalLineIgnored=($lines[-1].Length -gt 0);NativeAcceptanceGranted=$false})
}
return $latest