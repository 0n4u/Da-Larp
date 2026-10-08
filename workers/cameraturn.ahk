#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\CameraTurnCore.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
Gate := MacroGate(MacroKey("CameraTurn", "Hotkey", "F8"), "once")
Angle := MacroNumber("CameraTurn", "Angle", 180, 1, 360, false)
Units360 := MacroNumber("CameraTurn", "UnitsPer360", 2000, 1, 100000, false)
ReferenceSensitivity := MacroNumber("CameraTurn", "ReferenceSensitivity", 0.2, 0.001, 10, false)
Sensitivity := MacroNumber("CameraTurn", "Sensitivity", 0.2, 0.001, 10, false)
DpiScaling := MacroNumber("CameraTurn", "DpiScaling", 0, 0, 1)
ReferenceDpi := MacroNumber("CameraTurn", "ReferenceDpi", 1600, 100, 32000)
Dpi := MacroNumber("CameraTurn", "Dpi", 1600, 100, 32000)
Direction := MacroChoice("CameraTurn", "Direction", "right", ["right", "left"])
Duration := MacroNumber("CameraTurn", "DurationMs", 120, 20, 2000)
Curve := MacroChoice("CameraTurn", "Curve", "eased", ["eased", "linear"])
Cooldown := MacroNumber("CameraTurn", "CooldownMs", 250, 20, 3000)
Total := CameraTurnUnits(Angle, Units360, ReferenceSensitivity, Sensitivity, DpiScaling, ReferenceDpi, Dpi)
if Direction = "left"
    Total := -Total
LastRun := -10000
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit(Shutdown)
WorkerRuntimeInit("cameraturn")
if !WorkerSignalReady()
    ExitApp()

Loop {
    if Gate.ConsumePress() && MonotonicMs()-LastRun >= Cooldown {
        LastRun := MonotonicMs()
        RunCameraTurn(Gate, Gate.Epoch, Total, Duration, Curve)
    }
    Sleep(WorkerPollDelay(5))
}

RunCameraTurn(gate, epoch, total, duration, curve) {
    start := MonotonicMs()
    moved := 0
    loop {
        if !gate.Ready(epoch)
            return false
        elapsed := MonotonicMs()-start
        position := CameraTurnPosition(total, elapsed, duration, curve)
        delta := position-moved
        MacroMove(delta, 0)
        moved := position
        if elapsed >= duration
            return true
        if !gate.Wait(Min(WorkerPollDelay(4), Max(1, duration-elapsed)), epoch)
            return false
    }
}

Shutdown(*) {
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
