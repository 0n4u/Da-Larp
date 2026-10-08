#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
Gate := MacroGate(MacroKey("KeyRepeat", "Hotkey", "F7"), MacroChoice("KeyRepeat", "Mode", "hold", ["hold", "toggle"]))
OutputKey := MacroKey("KeyRepeat", "OutputKey", "e")
HoldMs := MacroNumber("KeyRepeat", "HoldMs", 8, 0, 100)
IntervalMs := MacroNumber("KeyRepeat", "IntervalMs", 100, 10, 1000)

SendMode("Event")
SetKeyDelay(-1, -1)
SetMouseDelay(-1)
ProcessSetPriority("Normal")
OnExit(Shutdown)
WorkerRuntimeInit("keyrepeat")
if !WorkerSignalReady()
    ExitApp()

Loop {
    if Gate.Ready() {
        epoch := Gate.Epoch
        if MacroTap(OutputKey, HoldMs, Gate, epoch)
            Gate.Wait(IntervalMs, epoch)
        else Sleep(WorkerPollDelay(10, true))
    } else Sleep(WorkerPollDelay(10, true))
}

Shutdown(*) {
    global Gate
    if Gate.OutputHeld != ""
        WorkerKeyUp(Gate.OutputHeld)
}
