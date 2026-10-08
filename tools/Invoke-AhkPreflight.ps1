function Invoke-AhkPreflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Ahk,
        [Parameter(Mandatory=$true)][string]$Arguments,
        [Parameter(Mandatory=$true)][string]$Stage,
        [ValidateRange(1, 2147483647)][int]$TimeoutMs = 20000,
        [switch]$PassThru,
        [switch]$FailOnWarning
    )

    $process = New-Object System.Diagnostics.Process
    $started = $false
    try {
        $process.StartInfo.FileName = $Ahk
        $process.StartInfo.Arguments = $Arguments
        $process.StartInfo.WorkingDirectory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Ahk))
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
        $process.StartInfo.StandardErrorEncoding = [Text.Encoding]::UTF8
        $started = $process.Start()
        if (-not $started) { throw 'The validation process did not start.' }
        $null = $process.Handle

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutMs)) {
            throw "Timed out after $TimeoutMs ms."
        }
        $readTasks = [Threading.Tasks.Task[]]@($stdoutTask, $stderrTask)
        if (-not [Threading.Tasks.Task]::WaitAll($readTasks, 2000)) {
            throw 'The validation process exited, but its output streams did not close.'
        }
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result

        $exitCode = $process.ExitCode
        if ($null -eq $exitCode -or $exitCode -isnot [int]) {
            throw 'Unable to read a valid process exit code.'
        }
        if (-not $PassThru -or $exitCode -ne 0) {
            if ($stdout.Trim()) { Write-Host $stdout.TrimEnd() }
            if ($stderr.Trim()) { Write-Host $stderr.TrimEnd() }
        }
        if ($exitCode -ne 0) { throw "Process returned exit $exitCode." }
        if ($FailOnWarning -and (($stdout + "`n" + $stderr) -match '(?i)\bWarning:')) {
            throw 'AutoHotkey emitted a warning during validation.'
        }
        if ($PassThru) {
            [pscustomobject]@{
                ExitCode = $exitCode
                StandardOutput = $stdout
                StandardError = $stderr
            }
        }
    } catch {
        throw "$Stage failed: $($_.Exception.Message) The existing session was left running."
    } finally {
        if ($started) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                    $null = $process.WaitForExit(2000)
                }
            } catch {}
        }
        $process.Dispose()
    }
}
