
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SuiteRoot,

    [string[]] $WorkerNames = @(
        'movement', 'gunspam', 'emote', 'socd', 'triggerbot', 'camlock', 'aimlock', 'wallhop', 'keyrepeat', 'recoil', 'fov', 'cameraturn', 'weapondetection'
    ),

    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NormalisedRoot {
    param([string] $Path)
    
    $full = [System.IO.Path]::GetFullPath($Path)
    return $full.TrimEnd('\', '/')
}

function Get-WorkerPattern {
    param([string[]] $Names, [string] $NormalisedRoot)
    $escaped = $Names | ForEach-Object { [Regex]::Escape($_) }
    
    return [Regex]::Escape($NormalisedRoot) + '\\workers\\(' + ($escaped -join '|') + ')\.ahk'
}

function Test-SuiteCommandLine {
    
    param(
        [string] $CommandLine,
        [string] $NormalisedRoot,
        [string] $WorkerPattern
    )
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $false }

    
    
    $shape = '^\s*(?:"(?<exe>[^"]+)"|(?<exe>[^\s"]+))\s+(?:/(?:restart|force|ErrorStdOut(?:=[^\s"]+)?|script)\s+)*(?:"(?<script>[^"]+)"|(?<script>[^\s"]+))(?:\s|$)'
    $match = [Regex]::Match($CommandLine, $shape, 'IgnoreCase')
    if (-not $match.Success) { return $false }
    $exe = $match.Groups['exe'].Value.Replace('/', '\')
    if ([System.IO.Path]::GetFileName($exe) -notmatch '^AutoHotkey(?:32|64)?\.exe$') { return $false }
    $script = $match.Groups['script'].Value.Replace('/', '\')
    $ignoreCase = [System.StringComparison]::OrdinalIgnoreCase
    if ($script.Equals($NormalisedRoot + '\DaHoodSuite.ahk', $ignoreCase)) { return $true }
    if ($script.Equals($NormalisedRoot + '\tools\SuiteGuardian.ahk', $ignoreCase)) { return $true }
    return [Regex]::IsMatch($script, '\A(?:' + $WorkerPattern + ')\z', 'IgnoreCase')
}

$root = Get-NormalisedRoot -Path $SuiteRoot
$pattern = Get-WorkerPattern -Names $WorkerNames -NormalisedRoot $root

$candidates = Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" |
    Where-Object { $_.Name -match '^AutoHotkey.*\.exe$' -and $_.CommandLine }

$matched = @()
foreach ($candidate in $candidates) {
    if (Test-SuiteCommandLine -CommandLine $candidate.CommandLine `
            -NormalisedRoot $root -WorkerPattern $pattern) {
        $matched += $candidate
    }
}

if ($matched.Count -eq 0) {
    Write-Output "scope=$root matched=0"
    if ($DryRun) { Write-Output 'dry-run: nothing to stop' }
    exit 0
}





$script:SuiteStopFailed = $false

function Test-OriginalSuiteProcess {
    param([object] $Original)
    $pidValue = [int] $Original.ProcessId
    $running = Get-CimInstance Win32_Process -Filter "ProcessId = $pidValue" -ErrorAction Stop
    if ($null -eq $running) { return $false }
    if ($running.CreationDate -ne $Original.CreationDate) { return $false }
    if ([string]::IsNullOrWhiteSpace($running.CommandLine)) { return $true }
    return Test-SuiteCommandLine -CommandLine $running.CommandLine `
        -NormalisedRoot $root -WorkerPattern $pattern
}

function Wait-SuiteProcessExit {
    param([object] $Original, [int] $Milliseconds = 3000)
    $deadline = [DateTime]::UtcNow.AddMilliseconds($Milliseconds)
    do {
        if (-not (Test-OriginalSuiteProcess -Original $Original)) { return $true }
        Start-Sleep -Milliseconds 200
    } while ([DateTime]::UtcNow -lt $deadline)
    return (-not (Test-OriginalSuiteProcess -Original $Original))
}

function Stop-MatchedSuiteProcesses {
    param([object[]] $Processes, [switch] $DryRun)
    foreach ($process in $Processes) {
        $label = "$($process.ProcessId) $($process.Name)"
        if ($DryRun) {
            Write-Output "dry-run would stop: $label"
            continue
        }
        try {
            if (-not (Test-OriginalSuiteProcess -Original $process)) {
                Write-Output "already stopped: $label"
                continue
            }
            Write-Output "stopping: $label"
            $initialFailure = ''
            try { Stop-Process -Id ([int]$process.ProcessId) -Force -ErrorAction Stop }
            catch { $initialFailure = $_.Exception.Message }
            if (Wait-SuiteProcessExit -Original $process -Milliseconds 2400) { continue }

            if (Test-OriginalSuiteProcess -Original $process) {
                Write-Output "retrying termination: $label"
                $taskkillOutput = ''
                try { $taskkillOutput = (& taskkill.exe /PID ([int]$process.ProcessId) /F 2>&1 | Out-String).Trim() }
                catch { $taskkillOutput = $_.Exception.Message }
                if (Wait-SuiteProcessExit -Original $process -Milliseconds 3500) { continue }
            }

            if (Test-OriginalSuiteProcess -Original $process) {
                $cimResult = Invoke-CimMethod -InputObject $process -MethodName Terminate -Arguments @{Reason = 1} -ErrorAction Stop
                if (Wait-SuiteProcessExit -Original $process -Milliseconds 2500) { continue }
                $reason = "Windows still reports the original process after Stop-Process, taskkill, and CIM."
                if ($initialFailure) { $reason += " Stop-Process: $initialFailure." }
                if ($taskkillOutput) { $reason += " taskkill: $taskkillOutput." }
                if ($null -ne $cimResult) { $reason += " CIM status: $($cimResult.ReturnValue)." }
                throw "$reason Close the running suite or retry Start.cmd as administrator if that session was elevated."
            }
        } catch {
            $script:SuiteStopFailed = $true
            Write-Error "stop failed: $label - $($_.Exception.Message). If this process is elevated, close it manually or run Start.cmd with matching permissions." -ErrorAction Continue
        }
    }
}

$ordered = @($matched | Sort-Object @{ Expression = { if ($_.CommandLine -match 'SuiteGuardian\.ahk') { 0 } else { 1 } } }, ProcessId)
Stop-MatchedSuiteProcesses -Processes $ordered -DryRun:$DryRun

Write-Output "scope=$root matched=$($matched.Count) failed=$script:SuiteStopFailed"
if ($script:SuiteStopFailed) { exit 1 }
exit 0
