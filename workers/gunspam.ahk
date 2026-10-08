#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
ConfigPath := A_ScriptDir "\..\config\settings.ini"
HotkeyName := ReadKey("GunSpam", "Hotkey", "LButton")
IntervalMs := ReadInt("GunSpam", "IntervalMs", 4, 1, 100)
ClickHoldMs := ReadInt("GunSpam", "ClickHoldMs", 0, 0, 50)
BypassCtrl := ReadBool("GunSpam", "BypassCtrl", true)
BypassAlt := ReadBool("GunSpam", "BypassAlt", true)

global Busy := false
global StartupBlocked := false

SendMode("Event")
SetMouseDelay(-1)
ProcessSetPriority("Normal")
ListLines(false)
KeyHistory(0)
A_HotkeyInterval := 0
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit(Shutdown)

if !RegisterGunHotkey()
    ExitApp()
StartupBlocked := GetKeyState(HotkeyName, "P")
WorkerRuntimeInit("gunspam")
if !WorkerSignalReady()
    ExitApp()

RegisterGunHotkey() {
    global HotkeyName
    try {
        HotIf(IsAllowed)
        Hotkey("$*" HotkeyName, RunSpam)
        HotIf()
        return true
    } catch {
        HotIf()
        return false
    }
}

IsAllowed(*) {
    global RobloxWindow, BypassCtrl, BypassAlt, HotkeyName, StartupBlocked
    if !GetKeyState(HotkeyName, "P")
        StartupBlocked := false
    if StartupBlocked
        return false
    if !WinActive(RobloxWindow) || !WorkerInputAllowed() || !WorkerAllowsFire()
        return false
    if BypassCtrl && GetKeyState("Ctrl", "P")
        return false
    if BypassAlt && GetKeyState("Alt", "P")
        return false
    return true
}

RunSpam(*) {
    global Busy, HotkeyName, RobloxWindow, IntervalMs
    if Busy || !GetKeyState(HotkeyName, "P")
        return

    Busy := true
    try {
        while GetKeyState(HotkeyName, "P") && WinActive(RobloxWindow) && IsAllowed() {
            ClickOnce()
            PreciseSleep(WorkerPollDelay(IntervalMs))
        }
    } finally {
        Busy := false
        try {
            SendEvent("{Blind}{LButton up}")
        } catch {
        }
    }
}

ClickOnce() {
    global ClickHoldMs
    if !IsAllowed()
        return
    SendEvent("{Blind}{LButton down}")
    if ClickHoldMs > 0
        PreciseSleep(ClickHoldMs)
    SendEvent("{Blind}{LButton up}")
}

PreciseSleep(ms) {
    if ms > 0
        DllCall("kernel32\Sleep", "UInt", Round(ms))
}

ReadInt(section, key, fallback, minV, maxV) {
    global ConfigPath
    value := IniRead(ConfigPath, section, key, fallback)
    if !IsNumber(value)
        return fallback
    return Min(maxV, Max(minV, Round(value + 0)))
}

ReadBool(section, key, fallback) {
    global ConfigPath
    value := StrLower(Trim(IniRead(ConfigPath, section, key, fallback ? "1" : "0")))
    return value = "1" || value = "true" || value = "yes" || value = "on"
}

ReadKey(section, key, fallback) {
    global ConfigPath
    value := Trim(IniRead(ConfigPath, section, key, fallback))
    return value = "" ? fallback : value
}

Shutdown(*) {
    try {
        SendEvent("{Blind}{LButton up}")
    } catch {
    }
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
