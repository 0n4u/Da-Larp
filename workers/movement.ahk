#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
Gate := MacroGate(MacroKey("Movement", "Hotkey", "x"), MacroChoice("Movement", "Mode", "hold", ["hold", "toggle"]))
StepDelay := MacroNumber("Movement", "StepMs", 12, 1, 100)
StepMode := MacroChoice("Movement", "StepMode", "cycle", ["cycle", "actions"])
MiddleTaps := MacroNumber("Movement", "MiddleTaps", 2, 0, 8)
WheelUp := MacroNumber("Movement", "WheelUp", 1, 0, 1)
WheelDown := MacroNumber("Movement", "WheelDown", 1, 0, 1)

SendMode("Event")
SetKeyDelay(-1, -1)
SetMouseDelay(-1)
ProcessSetPriority("Normal")
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit(Shutdown)
WorkerRuntimeInit("movement")
if !WorkerSignalReady()
    ExitApp()

Loop {
    if Gate.Ready() {
        RunMovementCycle(Gate, Gate.Epoch, MiddleTaps, WheelUp, WheelDown, StepDelay, StepMode)
    } else Sleep(WorkerPollDelay(10, true))
}

RunMovementCycle(gate, epoch, middleTaps, wheelUp, wheelDown, delayMs, placement) {
    actions := []
    Loop middleTaps
        actions.Push("MButton")
    if wheelUp
        actions.Push("WheelUp")
    if wheelDown
        actions.Push("WheelDown")
    for action in actions {
        if !gate.Ready(epoch)
            return false
        if action = "MButton" {
            if !MacroTap(action, 0, gate, epoch)
                return false
        } else SendEvent("{Blind}{" action "}")
        if placement = "actions" && !gate.Wait(delayMs, epoch)
            return false
    }

    return placement = "cycle" || actions.Length = 0 ? gate.Wait(delayMs, epoch) : true
}

Shutdown(*) {
    global Gate
    if Gate.OutputHeld != ""
        WorkerKeyUp(Gate.OutputHeld)
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
