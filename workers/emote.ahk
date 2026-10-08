#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
ConfigPath := A_ScriptDir "\..\config\settings.ini"
HotkeyName := ReadKey("Emote", "Hotkey", "MButton")
MenuKey := ReadKey("Emote", "MenuKey", ".")
SlotKey := ReadKey("Emote", "SlotKey", "1")
PressCount := ReadInt("Emote", "PressCount", 4, 1, 8)
OpenMs := ReadInt("Emote", "OpenMs", 38, 0, 500)
BetweenMs := ReadInt("Emote", "BetweenMs", 72, 0, 500)
FinalMs := ReadInt("Emote", "FinalMs", 165, 0, 1000)

global Busy := false
global StartupBlocked := false

SendMode("Event")
SetKeyDelay(-1, -1)
ProcessSetPriority("Normal")
ListLines(false)
KeyHistory(0)
A_HotkeyInterval := 0
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit(Shutdown)

if !RegisterEmoteHotkey()
    ExitApp()
StartupBlocked := GetKeyState(HotkeyName, "P")
WorkerRuntimeInit("emote")
if !WorkerSignalReady()
    ExitApp()

RegisterEmoteHotkey() {
    global RobloxWindow, HotkeyName
    try {
        HotIf(EmoteAllowed)
        Hotkey("$*" HotkeyName, RunEmote)
        HotIf()
        return true
    } catch {
        HotIf()
        return false
    }
}

RunEmote(*) {
    global Busy, HotkeyName, RobloxWindow, MenuKey, SlotKey, PressCount, OpenMs, BetweenMs, FinalMs
    if !WorkerInputAllowed() || Busy || !GetKeyState(HotkeyName, "P")
        return
    Busy := true
    try {
        TapKey(MenuKey)
        PreciseSleep(OpenMs)
        if !WinActive(RobloxWindow) || !WorkerInputAllowed()
            return

        Loop PressCount {
            TapKey(SlotKey)
            if A_Index < PressCount {
                delay := A_Index = PressCount - 1 ? FinalMs : BetweenMs
                PreciseSleep(delay)
                if !WinActive(RobloxWindow) || !WorkerInputAllowed()
                    return
            }
        }
    } finally {
        Busy := false
    }
}

TapKey(key) {
    SendEvent("{Blind}{" key " down}{" key " up}")
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

ReadKey(section, key, fallback) {
    global ConfigPath
    value := Trim(IniRead(ConfigPath, section, key, fallback))
    return value = "" ? fallback : value
}

Shutdown(*) {
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}

EmoteAllowed(*) {
    global RobloxWindow, HotkeyName, StartupBlocked
    if !GetKeyState(HotkeyName, "P")
        StartupBlocked := false
    return !StartupBlocked && WinActive(RobloxWindow) && WorkerInputAllowed()
}
