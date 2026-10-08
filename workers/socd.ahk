#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
ConfigPath := A_ScriptDir "\..\config\settings.ini"
Mode := ReadChoice("SOCD", "Mode", "last", ["last", "neutral"])
LeftKey := ReadKey("SOCD", "Left", "a")
RightKey := ReadKey("SOCD", "Right", "d")
UpKey := ReadKey("SOCD", "Up", "w")
DownKey := ReadKey("SOCD", "Down", "s")

if !ValidateDirectionKeys()
    ExitApp()

global Physical := Map(LeftKey, false, RightKey, false, UpKey, false, DownKey, false)
global Sent := Map(LeftKey, false, RightKey, false, UpKey, false, DownKey, false)
global LastPressed := Map("H", "", "V", "")
global HadFocus := false

ValidateDirectionKeys() {
    global LeftKey, RightKey, UpKey, DownKey
    seen := Map()
    for key in [LeftKey, RightKey, UpKey, DownKey] {
        normalized := StrLower(key)
        if normalized = "" || seen.Has(normalized)
            return false
        seen[normalized] := true
    }
    return true
}

SendMode("Event")
SetKeyDelay(-1, -1)
ProcessSetPriority("Normal")
ListLines(false)
KeyHistory(0)
A_HotkeyInterval := 0
OnExit(Shutdown)

RegisterPair(LeftKey, RightKey, "H")
RegisterPair(RightKey, LeftKey, "H")
RegisterPair(UpKey, DownKey, "V")
RegisterPair(DownKey, UpKey, "V")
SetTimer(FocusGuard, 50)
WorkerRuntimeInit("socd")
if !WorkerSignalReady()
    ExitApp()

RegisterPair(key, other, axis) {
    global RobloxWindow
    try {
        HotIf((*) => WinActive(RobloxWindow) && WorkerInputAllowed())
        Hotkey("$*" key, KeyDown.Bind(key, other, axis))
        Hotkey("$*" key " up", KeyUp.Bind(key, other, axis))
        HotIf()
    } catch {
        HotIf()
        ExitApp()
    }
}

KeyDown(key, other, axis, *) {
    global Physical, LastPressed
    if !WorkerInputAllowed() || Physical[key] || !GetKeyState(key, "P")
        return
    Physical[key] := true
    LastPressed[axis] := key
    ReconcileAxis(key, other, axis)
}

KeyUp(key, other, axis, *) {
    global Physical
    Physical[key] := false
    ReconcileAxis(key, other, axis)
}

ReconcileAxis(first, second, axis) {
    global Physical, LastPressed, Mode
    firstHeld := Physical[first]
    secondHeld := Physical[second]
    desired := ""

    if firstHeld && secondHeld {
        if Mode = "last"
            desired := LastPressed[axis]
    } else if firstHeld {
        desired := first
    } else if secondHeld {
        desired := second
    }

    if desired != first
        SetSent(first, false)
    if desired != second
        SetSent(second, false)
    if desired != ""
        SetSent(desired, true)
}

SetSent(key, down) {
    global Sent
    if down {
        if Sent[key]
            return
        Sent[key] := WorkerKeyDown(key)
    } else {
        if !Sent[key]
            return
        Sent[key] := false
        WorkerKeyUp(key)
    }
}

FocusGuard() {
    global RobloxWindow, HadFocus, Physical
    active := WinActive(RobloxWindow) && WorkerInputAllowed() ? true : false
    if HadFocus && !active {
        ReleaseAll()
        for key, _ in Physical
            Physical[key] := false
    }
    HadFocus := active
}

ReleaseAll() {
    global Sent
    for key, _ in Sent
        SetSent(key, false)
}

ReadKey(section, key, fallback) {
    global ConfigPath
    value := Trim(IniRead(ConfigPath, section, key, fallback))
    return value = "" ? fallback : value
}

ReadChoice(section, key, fallback, allowed) {
    global ConfigPath
    value := StrLower(Trim(IniRead(ConfigPath, section, key, fallback)))
    for choice in allowed {
        if value = choice
            return choice
    }
    return fallback
}

Shutdown(*) {
    SetTimer(FocusGuard, 0)
    ReleaseAll()
}
