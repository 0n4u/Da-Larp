#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\FovViewport.ahk
#Include %A_ScriptDir%\..\lib\WeaponCore.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
FullscreenHintKnown := false
FullscreenHint := false
LastFullscreenToggleTick := 0
CurrentViewportMode := ""
ViewportWindow := 0
LastGeometry := ""
Method := MacroChoice("WeaponDetection", "Method", "image", ["image", "color", "both"])
Action := MacroChoice("WeaponDetection", "Action", "block matched", ["block matched", "allow matched"])
Confirm := MacroNumber("WeaponDetection", "ConfirmScans", 2, 1, 8)
Detector := WeaponGate(Action, Confirm)
Template1 := MacroRead("WeaponDetection", "Template1", "assets/weapons/knife.png")
Template2 := MacroRead("WeaponDetection", "Template2", "assets/weapons/uzi.png")
Color1 := Method = "image" ? -1 : DetectionColor("Color1", "0x5A8EE9")
Color2 := Method = "image" ? -1 : DetectionColor("Color2", "")
Tolerance := MacroNumber("WeaponDetection", "Tolerance", 20, 0, 255)
ScanMs := MacroNumber("WeaponDetection", "ScanMs", 100, 50, 1000)
RegionX := MacroNumber("WeaponDetection", "RegionX", 0, 0, 99.9, false)
RegionY := MacroNumber("WeaponDetection", "RegionY", 70, 0, 99.9, false)
RegionW := MacroNumber("WeaponDetection", "RegionW", 100, 0.1, 100, false)
RegionH := MacroNumber("WeaponDetection", "RegionH", 30, 0.1, 100, false)
ScaleTemplates := MacroNumber("WeaponDetection", "ScaleTemplates", 1, 0, 1)
ReferenceWidth := MacroNumber("WeaponDetection", "ReferenceWidth", 1920, 320, 10000)
ReferenceHeight := MacroNumber("WeaponDetection", "ReferenceHeight", 1080, 240, 10000)
EnablePhysicalPixelCoordinates()
CoordMode("Pixel", "Screen")
HotIfWinActive(RobloxWindow)
Hotkey("~*!Enter", FullscreenAltEnter)
HotIfWinActive()
WorkerRuntimeInit("weapondetection")
WorkerSignalWeapon(false, "unknown", 0, MonotonicMs(), Color1, Color2, Tolerance)
if !WorkerSignalReady()
    ExitApp()

Loop {
    ScanWeapon()
    Sleep(WorkerPollDelay(ScanMs))
}

DetectionColor(key, fallback) {
    value := Trim(MacroRead("WeaponDetection", key, fallback))
    if value = ""
        return -1
    if !RegExMatch(value, "i)^0x[0-9a-f]{6}$")
        throw Error("Invalid weapon detection color")
    return value+0
}

FullscreenAltEnter(*) {
    global FullscreenHintKnown, FullscreenHint, LastFullscreenToggleTick, ViewportWindow, RobloxWindow
    hwnd := WinActive(RobloxWindow)
    if !hwnd
        return
    if ViewportWindow != hwnd {
        ViewportWindow := hwnd
        FullscreenHintKnown := false
        FullscreenHint := false
        LastFullscreenToggleTick := 0
    }
    if LastFullscreenToggleTick && A_TickCount-LastFullscreenToggleTick < 450
        return
    LastFullscreenToggleTick := A_TickCount
    FullscreenHint := FullscreenHintKnown ? !FullscreenHint : !WindowLooksFullscreen(hwnd)
    FullscreenHintKnown := true
}

ScanWeapon() {
    global Detector, Action, Confirm, LastGeometry, RobloxWindow
    global RegionX, RegionY, RegionW, RegionH, Color1, Color2, Tolerance
    hwnd := WinActive(RobloxWindow)
    if !hwnd {
        Detector := WeaponGate(Action, Confirm)
        LastGeometry := ""
        WorkerSignalWeapon(false, "unfocused", 0, MonotonicMs(), Color1, Color2, Tolerance)
        return
    }
    try {
        if !GetClientRect(&left, &top, &width, &height)
            throw Error("Cannot read Roblox viewport")
        geometry := hwnd ":" left "," top "," width "," height
        if geometry != LastGeometry {
            Detector := WeaponGate(Action, Confirm)
            LastGeometry := geometry
        }
        roi := WeaponRegion(left, top, width, height, RegionX, RegionY, RegionW, RegionH)
        matched := FindWeaponMatch(roi, width, height, &name)
        if WinActive(RobloxWindow) != hwnd
            throw Error("Roblox focus changed during scan")
        allowed := Detector.Observe(matched, false, name)
        WorkerSignalWeapon(allowed, name, hwnd, MonotonicMs(), Color1, Color2, Tolerance)
    } catch as err {
        Detector.Observe(false, true, "error")
        WorkerSignalWeapon(false, "error", hwnd, MonotonicMs(), Color1, Color2, Tolerance,
            "weapon-unavailable", err.Message)
    }
}

FindWeaponMatch(roi, width, height, &name) {
    global Method, Template1, Template2, ScaleTemplates, ReferenceWidth, ReferenceHeight
    global Color1, Color2, Tolerance
    name := "no match"
    if Method != "color" {
        usable := 0
        for index, relative in [Template1, Template2] {
            if relative = ""
                continue
            path := WeaponAssetPath(relative)
            size := WeaponImageSize(path)
            w := Max(1, Round(size[1]*(ScaleTemplates ? width/ReferenceWidth : 1)))
            h := Max(1, Round(size[2]*(ScaleTemplates ? height/ReferenceHeight : 1)))
            if w > roi[3]-roi[1]+1 || h > roi[4]-roi[2]+1
                continue
            usable += 1
            if ImageSearch(&x, &y, roi[1], roi[2], roi[3], roi[4],
                "*" Tolerance " *w" w " *h" h " " path) {
                name := "template " index
                return true
            }
        }
        if !usable
            throw Error("No usable template fits the weapon region")
    }
    if Method != "image" {
        if Color1 < 0 && Color2 < 0
            throw Error("Choose a weapon detection color")
        for index, color in [Color1, Color2] {
            if color < 0
                continue
            if PixelSearch(&x, &y, roi[1], roi[2], roi[3], roi[4], color, Tolerance) {
                name := "color " index
                return true
            }
        }
    }
    return false
}
