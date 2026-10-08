@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Stop-SuiteProcesses.ps1" -SuiteRoot "%~dp0."
if errorlevel 1 (
    echo Stop failed. See the message above.
    pause
    exit /b 1
)
exit /b 0
