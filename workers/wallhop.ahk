#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
Gate := MacroGate(MacroKey("WallHop", "Hotkey", "F6"), "once")
Distance := MacroNumber("WallHop", "DistancePx", 35, 1, 2000)
Direction := MacroChoice("WallHop", "Direction", "right", ["right", "left"])
ReturnMs := MacroNumber("WallHop", "ReturnMs", 4, 0, 250)
CooldownMs := MacroNumber("WallHop", "CooldownMs", 120, 20, 1000)
LastRun := -10000

SetMouseDelay(-1)
ProcessSetPriority("Normal")
WorkerRuntimeInit("wallhop")
if !WorkerSignalReady()
    ExitApp()

Loop {
    if Gate.ConsumePress() && MonotonicMs()-LastRun >= CooldownMs {
        LastRun := MonotonicMs()
        epoch := Gate.Epoch
        RunWallHop(Gate, epoch, Direction = "left" ? -Distance : Distance, ReturnMs)
    }
    Sleep(WorkerPollDelay(5))
}

RunWallHop(gate, epoch, distance, delayMs) {
    if !gate.Ready(epoch)
        return false
    MacroMove(distance, 0)

    if !gate.Wait(delayMs, epoch)
        return false
    MacroMove(-distance, 0)
    return true
}
