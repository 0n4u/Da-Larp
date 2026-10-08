param(
    [Parameter(Mandatory=$true)][string]$SuiteRoot,
    [switch]$PreflightOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    $root = [IO.Path]::GetFullPath($SuiteRoot).TrimEnd('\', '/')
    $preflightHelper = Join-Path $root 'tools\Invoke-AhkPreflight.ps1'
    if (-not (Test-Path -LiteralPath $preflightHelper)) { throw 'The preflight helper is missing. Extract the complete ZIP.' }
    $powerShellFailures = 0
    foreach ($script in (Get-ChildItem -LiteralPath (Join-Path $root 'tools') -Filter '*.ps1' | Sort-Object Name)) {
        $tokens = $null
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
        foreach ($parseError in $parseErrors) {
            $powerShellFailures++
            Write-Host ("PowerShell: {0} ({1}): {2}" -f $script.FullName, $parseError.Extent.StartLineNumber, $parseError.Message)
        }
    }
    if ($powerShellFailures -gt 0) { throw "$powerShellFailures PowerShell parse error(s). The existing session was left running." }
    . $preflightHelper
    $ahk = Join-Path $root 'runtime\AutoHotkey64.exe'
    if (-not (Test-Path -LiteralPath $ahk)) { throw 'The included AutoHotkey runtime is missing. Extract the entire ZIP again.' }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'runtime\TargetScan.dll'))) { throw 'TargetScan.dll is missing. Extract the complete ZIP.' }
    Write-Host 'Da Larp v13.6 preflight validation'
    $scripts = @(Join-Path $root 'DaHoodSuite.ahk')
    $scripts += @(Get-ChildItem -LiteralPath (Join-Path $root 'workers') -Filter '*.ahk' | Sort-Object Name | ForEach-Object FullName)
    $scripts += @(Join-Path $root 'tools\SuiteGuardian.ahk')
    $syntaxFailures = 0
    foreach ($script in $scripts) {
        try {
            Invoke-AhkPreflight -Ahk $ahk -Arguments ('/Validate /ErrorStdOut=UTF-8 "' + $script + '"') -Stage "Validation: $script"
        } catch {
            $syntaxFailures++
            Write-Host $_.Exception.Message
        }
    }
    if ($syntaxFailures -gt 0) { throw "$syntaxFailures of $($scripts.Count) AHK entry points failed validation. The existing session was left running." }
    $runtimeFailures = 0
    foreach ($worker in @('aimlock', 'camlock', 'triggerbot')) {
        $workerScript = Join-Path $root ('workers\' + $worker + '.ahk')
        try {
            Invoke-AhkPreflight -Ahk $ahk -Arguments ('/force /ErrorStdOut=UTF-8 "' + $workerScript + '" --targeting-preflight') -Stage "$worker startup preflight"
        } catch {
            $runtimeFailures++
            Write-Host $_.Exception.Message
        }
    }
    if ($runtimeFailures -gt 0) { throw "$runtimeFailures runtime preflight stage(s) failed. The existing session was left running." }
    Write-Host "PASS: all $($scripts.Count) AHK entry points and three runtime probes."
    if ($PreflightOnly) { exit 0 }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\Stop-SuiteProcesses.ps1') -SuiteRoot $root
    if ($LASTEXITCODE -ne 0) { throw 'Unable to stop the previous session.' }
    $state = Join-Path $root 'state'
    if (-not (Test-Path -LiteralPath $state)) { $null = New-Item -ItemType Directory -Path $state -Force }
    $readyPath = Join-Path $state 'guardian.ready'
    $errorPath = Join-Path $state 'guardian.error'
    Remove-Item -LiteralPath $readyPath, $errorPath -Force -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath $state -Filter 'guardian.*.roster' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $guardianScript = Join-Path $root 'tools\SuiteGuardian.ahk'
    $guardian = Start-Process -FilePath $ahk -ArgumentList ('"' + $guardianScript + '"') -WorkingDirectory $root -WindowStyle Hidden -PassThru
    $started = $false
    for ($attempt = 0; $attempt -lt 55; $attempt++) {
        Start-Sleep -Milliseconds 100
        if (Test-Path -LiteralPath $errorPath) {
            throw ('Guardian failed: ' + ([IO.File]::ReadAllText($errorPath)))
        }
        if (Test-Path -LiteralPath $readyPath) {
            try {
                $guardPid = [int](Get-Content -LiteralPath $readyPath -ErrorAction Stop | Out-String | Select-String -Pattern 'Pid=(\d+)').Matches[0].Groups[1].Value
                $mainPid = [int](Get-Content -LiteralPath $readyPath -ErrorAction Stop | Out-String | Select-String -Pattern 'Main=(\d+)').Matches[0].Groups[1].Value
                if ($guardPid -eq $guardian.Id -and $mainPid -gt 0 -and -not $guardian.HasExited -and (Get-Process -Id $mainPid -ErrorAction SilentlyContinue)) {
                    $started = $true
                    break
                }
            } catch {}
        }
        if ($guardian.HasExited) { break }
    }
    if (-not $started) {
        if (-not $guardian.HasExited) { Stop-Process -Id $guardian.Id -Force -ErrorAction SilentlyContinue }
        throw 'The suite guardian did not report a running controller. No new session was left running.'
    }
    Write-Host 'PASS: guarded Da Larp session started.'
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
