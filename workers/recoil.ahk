#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
InstallKeybdHook()
InstallMouseHook()
AimKey := MacroKey("Recoil", "AimKey", "RButton")
FireKey := MacroKey("Recoil", "FireKey", "LButton")
RequireAim := MacroNumber("Recoil", "RequireAim", 1, 0, 1)
PullX := MacroNumber("Recoil", "PullX", 0, -50, 50, false)
PullY := MacroNumber("Recoil", "PullY", 2, -50, 50, false)
IntervalMs := MacroNumber("Recoil", "IntervalMs", 10, 2, 100)
MaxStep := MacroNumber("Recoil", "MaxStep", 12, 1, 50)
ResidualX := 0.0
ResidualY := 0.0
LastTick := 0
Blocked := GetKeyState(FireKey, "P")

ProcessSetPriority("Normal")
WorkerRuntimeInit("recoil")
if !WorkerSignalReady()
    ExitApp()

Loop {
    if !RecoilReady() {
        LastTick := 0
        ResidualX := 0.0
        ResidualY := 0.0
        Sleep(WorkerPollDelay(10, true))
        continue
    }
    now := MonotonicMs()
    pace := WorkerPollDelay(IntervalMs)
    dt := LastTick ? Min(pace*2, Max(0, now-LastTick)) : IntervalMs
    LastTick := now
    dx := PullX*dt/IntervalMs
    dy := PullY*dt/IntervalMs
    LimitMotion(&dx, &dy, MaxStep)
    ResidualX += dx
    ResidualY += dy
    moveX := ResidualX >= 0 ? Floor(ResidualX) : Ceil(ResidualX)
    moveY := ResidualY >= 0 ? Floor(ResidualY) : Ceil(ResidualY)
    ResidualX -= moveX
    ResidualY -= moveY
    if RecoilReady()
        MacroMove(moveX, moveY)
    Sleep(pace)
}

RecoilReady() {
    global FireKey, AimKey, RequireAim, Blocked
    firing := GetKeyState(FireKey, "P")
    if !MacroFocused() || !WorkerAllowsFire() {
        Blocked := firing
        return false
    }
    if !firing
        Blocked := false
    return !Blocked && firing && (!RequireAim || GetKeyState(AimKey, "P"))
}
