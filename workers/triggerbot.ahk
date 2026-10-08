#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\TargetOrigin.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
#Include %A_ScriptDir%\..\lib\FovGuideCore.ahk
#Include %A_ScriptDir%\..\lib\TargetSnapshot.ahk
#Include %A_ScriptDir%\..\lib\TargetEngine.ahk
#Include %A_ScriptDir%\..\lib\ViewportPolicy.ahk
#Include %A_ScriptDir%\..\lib\TargetingPreflight.ahk
Persistent

RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
ConfigPath := A_ScriptDir "\..\config\settings.ini"

HotkeyName := ReadKey("Triggerbot", "Hotkey", "XButton1")
Mode := ReadChoice("Triggerbot", "Mode", "hold", ["hold", "toggle", "always"])
Origin := ReadChoice("Triggerbot", "Origin", "camera", ["camera", "cursor"])
ScaleMode := ReadChoice("Triggerbot", "ScaleMode", "auto", ["auto", "raw"])
ReferenceWidth := ReadInt("Triggerbot", "ReferenceWidth", 1920, 320, 10000)
ReferenceHeight := ReadInt("Triggerbot", "ReferenceHeight", 1080, 240, 10000)
FovX := ReadInt("Triggerbot", "FovX", 2, 1, 300)
FovY := ReadInt("Triggerbot", "FovY", 2, 1, 300)
TargetColor := ReadColor("Triggerbot", "TargetColor", 0x000000)
SecondaryColor := ReadOptionalColor("Triggerbot", "SecondaryColor")
Tolerance := ReadInt("Triggerbot", "Tolerance", 18, 0, 255)
TertiaryColor := ReadOptionalColor("Triggerbot", "TertiaryColor")
SecondaryTolerance := ReadInt("Triggerbot", "SecondaryTolerance", -1, -1, 255)
TertiaryTolerance := ReadInt("Triggerbot", "TertiaryTolerance", -1, -1, 255)
ScanColors := [TargetColor, SecondaryColor, TertiaryColor]
ScanTolerances := [Tolerance, SecondaryTolerance < 0 ? Tolerance : SecondaryTolerance, TertiaryTolerance < 0 ? Tolerance : TertiaryTolerance]
MinPixels := ReadInt("Triggerbot", "MinPixels", 1, 1, 9)
ConfirmRadius := ReadInt("Triggerbot", "ConfirmRadius", 8, 1, 100)
VerifyBeforeFire := ReadBool("Triggerbot", "VerifyBeforeFire", true)
global FoundColor := 0
global ConfirmationScaleX := 1
global ConfirmationScaleY := 1
global TriggerSampleTick := 0
global HitX := 0
global HitY := 0
global HitColor := -1
global LastHitTick := -1
global SyntheticLeftDown := false
ScanMs := ReadInt("Triggerbot", "ScanMs", 4, 1, 100)
FireMode := ReadChoice("Triggerbot", "FireMode", "edge", ["edge", "repeat"])
ConfirmScans := ReadInt("Triggerbot", "ConfirmScans", 3, 1, 8)
ConfirmMs := ReadInt("Triggerbot", "ConfirmMs", 14, 0, 250)
RearmMs := ReadInt("Triggerbot", "RearmMs", 30, 0, 500)
PostFireMs := ReadInt("Triggerbot", "PostFireMs", 1, 0, 250)
ClickHoldMs := ReadInt("Triggerbot", "ClickHoldMs", 9, 0, 100)
CooldownMs := ReadInt("Triggerbot", "CooldownMs", 50, 0, 1000)
IgnoreHeldClick := ReadBool("Triggerbot", "IgnoreHeldClick", true)
RequireStationary := ReadBool("Triggerbot", "RequireStationary", false)

global Held := false
global ToggleState := false
global KeyLatch := false
global ActivationBlocked := false
global LastFire := 0
global HitStreak := 0
global HitSince := -1
global Armed := true
global MissingSince := -1
global LastViewportX := ""
global LastViewportY := ""
global LastViewportW := 0
global LastViewportH := 0
global FullscreenHintKnown := false
global FullscreenHint := false
global LastFullscreenToggleTick := 0
global CurrentViewportMode := ""
global ViewportWindow := 0

if WorkerTargetingProbeRequested() {
    try WorkerTargetingProbe("Triggerbot", ScanColors, ScanTolerances, MinPixels)
    catch as err {
        FileAppend("Triggerbot startup preflight failed: " err.Message "`n","**")
        ExitApp(1)
    }
    ExitApp(0)
}

SendMode("Event")
SetMouseDelay(-1)
ProcessSetPriority("Normal")
ListLines(false)
KeyHistory(0)
A_HotkeyInterval := 0
EnablePhysicalPixelCoordinates()
CoordMode("Pixel", "Screen")
DllCall("winmm\timeBeginPeriod", "UInt", 1)
OnExit(Shutdown)
RegisterFullscreenObserver()

if Mode != "always" && !RegisterActivationHotkeys()
    ExitApp()

ActivationBlocked := GetKeyState(HotkeyName, "P")
WorkerRuntimeInit("triggerbot")
TargetSnapshot.Init()
if !WorkerSignalReady()
    ExitApp()

RegisterFullscreenObserver() {
    global RobloxWindow
    try {
        HotIfWinActive(RobloxWindow)

        Hotkey("~*!Enter", FullscreenAltEnter)
        HotIfWinActive()
        return true
    } catch {
        HotIfWinActive()
        return false
    }
}

FullscreenAltEnter(*) {
    global FullscreenHintKnown, FullscreenHint, LastFullscreenToggleTick, RobloxWindow
    global ViewportWindow
    hwnd := WinActive(RobloxWindow)
    if !hwnd
        return
    if ViewportWindow != hwnd {
        ViewportWindow := hwnd
        FullscreenHintKnown := false
        FullscreenHint := false
        LastFullscreenToggleTick := 0
    }

    if LastFullscreenToggleTick && A_TickCount - LastFullscreenToggleTick < 450
        return
    LastFullscreenToggleTick := A_TickCount

    if !FullscreenHintKnown {
        hwnd := WinExist(RobloxWindow)
        currentlyFullscreen := hwnd ? WindowLooksFullscreen(hwnd) : false
        FullscreenHint := !currentlyFullscreen
        FullscreenHintKnown := true
    } else {
        FullscreenHint := !FullscreenHint
    }

    ResetDetector()
}

RegisterActivationHotkeys() {
    global RobloxWindow, HotkeyName
    try {
        HotIfWinActive(RobloxWindow)
        Hotkey("~$*" HotkeyName, ActivationDown)
        Hotkey("~$*" HotkeyName " up", ActivationUp)
        HotIfWinActive()
        return true
    } catch {
        HotIfWinActive()
        return false
    }
}

Loop {
    engaged := IsEngaged()
    if engaged {
        ScanOnce()
        PreciseSleep(WorkerPollDelay(ScanMs))
    } else {
        ResetDetector()
        PreciseSleep(WorkerPollDelay(12, true))
    }
}

ActivationDown(*) {
    global Mode, Held, ToggleState, KeyLatch, HotkeyName, ActivationBlocked
    if !WorkerInputAllowed() || ActivationBlocked || KeyLatch || !GetKeyState(HotkeyName, "P")
        return
    KeyLatch := true
    if Mode = "hold"
        Held := true
    else if Mode = "toggle"
        ToggleState := !ToggleState
}

ActivationUp(*) {
    global Mode, Held, KeyLatch, ActivationBlocked
    ActivationBlocked := false
    KeyLatch := false
    if Mode = "hold"
        Held := false
}

IsEngaged() {
    global Mode, Held, ToggleState, KeyLatch, HotkeyName, RobloxWindow, ActivationBlocked
    if !WinActive(RobloxWindow) || !WorkerInputAllowed() {
        ActivationBlocked := GetKeyState(HotkeyName, "P")
        Held := false
        ToggleState := false
        KeyLatch := false
        return false
    }
    if Mode = "always"
        return true
    if !GetKeyState(HotkeyName, "P")
        ActivationBlocked := false
    if ActivationBlocked
        return false
    if Mode = "toggle"
        return ToggleState
    return GetKeyState(HotkeyName, "P")
}

ScanOnce() {
    global IgnoreHeldClick, LastFire, CooldownMs, PostFireMs, ScanMs
    global FireMode, ConfirmScans, ConfirmMs, RearmMs, HitStreak, HitSince, Armed, MissingSince
    global HitX, HitY, HitColor, LastHitTick, FoundColor, ConfirmRadius, ConfirmationScaleX, ConfirmationScaleY, VerifyBeforeFire, TriggerSampleTick
    if !IsEngaged() || !StationaryAllowed() || !WorkerAllowsFire() {
        ResetDetector()
        return
    }
    previousArmed := Armed
    found := FindTarget(&targetX, &targetY, &captureFailed)
    now := MonotonicMs()
    if !IsEngaged() || !StationaryAllowed() || !WorkerAllowsFire() {
        ResetDetector()
        return
    }
    if captureFailed {
        WorkerSignalIssue("capture-unavailable", "screen pixels unavailable")
        Armed := previousArmed
        ClearTriggerConfirmation()
        MissingSince := -1
        return
    }
    if !found {
        ClearTriggerConfirmation()
        if MissingSince < 0
            MissingSince := now
        if !Armed && now-MissingSince >= RearmMs
            Armed := true
        return
    }
    MissingSince := -1
    radius := ConfirmRadius
    continuous := HitStreak > 0 && LastHitTick >= 0 && now-LastHitTick <= Max(50, ScanMs*4)
        && TriggerSameTarget(targetX, targetY, FoundColor, HitX, HitY, HitColor, radius, ConfirmationScaleX, ConfirmationScaleY)
    if !continuous {
        HitStreak := 0
        HitSince := now
    }
    HitStreak += 1
    HitX := targetX, HitY := targetY, HitColor := FoundColor, LastHitTick := now
    if HitStreak < ConfirmScans || now-HitSince < ConfirmMs
        return
    if IgnoreHeldClick && GetKeyState("LButton", "P")
        return
    if CooldownMs > 0 && now-LastFire < CooldownMs
        return
    if FireMode = "edge" && !Armed
        return
    if VerifyBeforeFire {
        verified := FindTarget(&verifyX, &verifyY, &verifyFailed)
        if !verified || verifyFailed || HitStreak < ConfirmScans
            || !TriggerSameTarget(verifyX, verifyY, FoundColor, HitX, HitY, HitColor, radius, ConfirmationScaleX, ConfirmationScaleY) {
            ClearTriggerConfirmation()
            return
        }
    }
    if MonotonicMs()-TriggerSampleTick > 50 || !ClickOnce()
        return
    LastFire := MonotonicMs()
    if FireMode = "edge"
        Armed := false
    if PostFireMs > 0
        PreciseSleep(PostFireMs)
}

FindTarget(&outX, &outY, &captureFailed := unset) {
    global TargetColor, SecondaryColor, Tolerance, Origin, FovX, FovY
    global ScanColors, ScanTolerances, MinPixels, FoundColor, ConfirmationScaleX, ConfirmationScaleY, TriggerSampleTick
    static previousPolicy := ""
    captureFailed := false
    if !GetClientRect(&left, &top, &width, &height) {
        captureFailed := true
        return false
    }
    HandleViewportChange(left, top, width, height)
    GetResolutionScale(width, height, &scaleX, &scaleY)
    policy := TargetEngineField(Origin, "pixels", FovX, FovY, 80, left, top, width, height,
        scaleX, scaleY, &centerX, &centerY, &field, &bounds)
    signature := policy[1] ":" policy[2]
    if previousPolicy != "" && signature != previousPolicy
        ResetDetector()
    previousPolicy := signature
    WorkerSignalField(centerX, centerY, field[3], field[4], TargetColor, SecondaryColor, Tolerance, policy[1], policy[2],
        ScanColors[3], ScanTolerances[2], ScanTolerances[3])
    ConfirmationScaleX := scaleX
    ConfirmationScaleY := scaleY
    try {
        frame := TargetEngineCapture(bounds,[left,top,width,height])
        TriggerSampleTick := frame.tick
        return TargetEngineFind(frame, field, centerX, centerY, ScanColors, ScanTolerances, MinPixels,
            &outX, &outY, &FoundColor)
    } catch {
        captureFailed := true
        return false
    }
}

HandleViewportChange(left, top, width, height) {
    global LastViewportX, LastViewportY, LastViewportW, LastViewportH
    global CurrentViewportMode
    static lastMode := ""

    changed := LastViewportW > 0 && (
        left != LastViewportX || top != LastViewportY
        || width != LastViewportW || height != LastViewportH
        || CurrentViewportMode != lastMode
    )
    LastViewportX := left
    LastViewportY := top
    LastViewportW := width
    LastViewportH := height
    lastMode := CurrentViewportMode
    if changed
        ResetDetector()
    static signaled := false
    if changed || !signaled {
        WorkerSignalViewport(CurrentViewportMode, left, top, width, height, "viewport active")
        signaled := true
    }
}

GetResolutionScale(width, height, &scaleX, &scaleY) {
    global ScaleMode, ReferenceWidth, ReferenceHeight
    if ScaleMode = "raw" {
        scaleX := 1.0
        scaleY := 1.0
        return
    }
    scaleX := Max(0.001, width / Max(1, ReferenceWidth))
    scaleY := Max(0.001, height / Max(1, ReferenceHeight))
}

StationaryAllowed() {
    global RequireStationary
    if !RequireStationary
        return true
    for key in ["w", "a", "s", "d", "Up", "Down", "Left", "Right"]
        if GetKeyState(key, "P")
            return false
    return true
}

ClearTriggerConfirmation() {
    global HitStreak, HitSince, HitColor, LastHitTick
    HitStreak := 0
    HitSince := -1
    HitColor := -1
    LastHitTick := -1
}

ResetDetector() {
    global Armed, MissingSince
    ClearTriggerConfirmation()
    Armed := true
    MissingSince := -1
}

GetClientRect(&x, &y, &w, &h) {
    global RobloxWindow, FullscreenHintKnown, FullscreenHint, CurrentViewportMode
    global ViewportWindow

    hwnd := WinActive(RobloxWindow)
    if !hwnd
        return false
    if ViewportWindow != hwnd {
        ViewportWindow := hwnd
        FullscreenHintKnown := false
        FullscreenHint := false
    }

    clientOk := GetWin32ClientGeometry(hwnd, &clientX, &clientY, &clientW, &clientH)
    windowOk := GetWindowGeometry(hwnd, &windowX, &windowY, &windowW, &windowH)
    monitorOk := GetMonitorBounds(hwnd, &monitorX, &monitorY, &monitorW, &monitorH)

    geometryFullscreen := false
    if monitorOk {
        if windowOk && RectCoversMonitor(windowX, windowY, windowW, windowH, monitorX, monitorY, monitorW, monitorH)
            geometryFullscreen := true
        else if clientOk && RectCoversMonitor(clientX, clientY, clientW, clientH, monitorX, monitorY, monitorW, monitorH)
            geometryFullscreen := true
    }

    styleFullscreen := !clientOk && monitorOk && windowOk && WindowStyleSuggestsFullscreen(hwnd, windowW, windowH, monitorW, monitorH)

    useMonitor := ViewportPreferMonitor(monitorOk,geometryFullscreen,styleFullscreen,
        FullscreenHintKnown,FullscreenHint,LastFullscreenToggleTick,A_TickCount)

    if useMonitor {
        x := monitorX
        y := monitorY
        w := monitorW
        h := monitorH
        CurrentViewportMode := "monitor"
        return w > 0 && h > 0
    }

    if clientOk {
        x := clientX
        y := clientY
        w := clientW
        h := clientH
        CurrentViewportMode := "client"
        return true
    }

    if windowOk {
        x := windowX
        y := windowY
        w := windowW
        h := windowH
        CurrentViewportMode := "window-fallback"
        return w > 0 && h > 0
    }

    if monitorOk {
        x := monitorX
        y := monitorY
        w := monitorW
        h := monitorH
        CurrentViewportMode := "monitor-fallback"
        return w > 0 && h > 0
    }

    CurrentViewportMode := ""
    return false
}

GetWin32ClientGeometry(hwnd, &x, &y, &w, &h) {
    rect := Buffer(16, 0)
    if !DllCall("user32\GetClientRect", "Ptr", hwnd, "Ptr", rect.Ptr, "Int")
        return false

    w := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")
    h := NumGet(rect, 12, "Int") - NumGet(rect, 4, "Int")
    if w <= 0 || h <= 0
        return false

    point := Buffer(8, 0)
    if !DllCall("user32\ClientToScreen", "Ptr", hwnd, "Ptr", point.Ptr, "Int")
        return false

    x := NumGet(point, 0, "Int")
    y := NumGet(point, 4, "Int")
    return true
}

GetWindowGeometry(hwnd, &x, &y, &w, &h) {
    rect := Buffer(16, 0)
    if !DllCall("user32\GetWindowRect", "Ptr", hwnd, "Ptr", rect.Ptr, "Int")
        return false

    x := NumGet(rect, 0, "Int")
    y := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    w := right - x
    h := bottom - y
    return w > 0 && h > 0
}

GetMonitorBounds(hwnd, &x, &y, &w, &h) {
    monitor := DllCall("user32\MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
    if !monitor
        return false

    info := Buffer(40, 0)
    NumPut("UInt", 40, info, 0)
    if !DllCall("user32\GetMonitorInfoW", "Ptr", monitor, "Ptr", info.Ptr, "Int")
        return false

    x := NumGet(info, 4, "Int")
    y := NumGet(info, 8, "Int")
    right := NumGet(info, 12, "Int")
    bottom := NumGet(info, 16, "Int")
    w := right - x
    h := bottom - y
    return w > 0 && h > 0
}

RectCoversMonitor(x, y, w, h, mx, my, mw, mh) {
    tolerance := 3
    return Abs(x - mx) <= tolerance
        && Abs(y - my) <= tolerance
        && Abs((x + w) - (mx + mw)) <= tolerance
        && Abs((y + h) - (my + mh)) <= tolerance
}

WindowStyleSuggestsFullscreen(hwnd, windowW, windowH, monitorW, monitorH) {
    if monitorW <= 0 || monitorH <= 0
        return false
    try {
        fn := A_PtrSize = 8 ? "user32\GetWindowLongPtrW" : "user32\GetWindowLongW"
        style := DllCall(fn, "Ptr", hwnd, "Int", -16, A_PtrSize = 8 ? "Ptr" : "Int")
    } catch {
        return false
    }
    WS_CAPTION := 0x00C00000
    WS_THICKFRAME := 0x00040000
    WS_POPUP := 0x80000000
    borderless := (style & WS_POPUP) && !(style & WS_CAPTION) && !(style & WS_THICKFRAME)
    largeEnough := windowW >= monitorW * 0.88 && windowH >= monitorH * 0.88
    return borderless && largeEnough
}

WindowLooksFullscreen(hwnd) {
    if !GetMonitorBounds(hwnd, &mx, &my, &mw, &mh)
        return false
    if GetWindowGeometry(hwnd, &wx, &wy, &ww, &wh)
        if RectCoversMonitor(wx, wy, ww, wh, mx, my, mw, mh)
            return true
    if GetWin32ClientGeometry(hwnd, &cx, &cy, &cw, &ch)
        if RectCoversMonitor(cx, cy, cw, ch, mx, my, mw, mh)
            return true
    return false
}

ClickOnce() {
    global ClickHoldMs, IgnoreHeldClick, SyntheticLeftDown
    if !IsEngaged() || !StationaryAllowed() || !WorkerAllowsFire()
        || (IgnoreHeldClick && GetKeyState("LButton", "P"))
        return false
    try {
        SyntheticLeftDown := true
        SendEvent("{Blind}{LButton down}")
        if ClickHoldMs > 0
            PreciseSleep(ClickHoldMs)
        return true
    } finally {
        if SyntheticLeftDown {
            SendEvent("{Blind}{LButton up}")
            SyntheticLeftDown := false
        }
    }
}

PreciseSleep(ms) {
    if ms > 0
        DllCall("kernel32\Sleep", "UInt", Round(ms))
}

Clamp(value, minV, maxV) {
    return Min(maxV, Max(minV, value))
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

ReadChoice(section, key, fallback, allowed) {
    global ConfigPath
    value := StrLower(Trim(IniRead(ConfigPath, section, key, fallback)))
    for choice in allowed {
        if value = choice
            return choice
    }
    return fallback
}

ReadColor(section, key, fallback) {
    global ConfigPath
    return ParseColor(IniRead(ConfigPath, section, key, Format("0x{:06X}", fallback)), fallback)
}

ReadOptionalColor(section, key) {
    global ConfigPath
    value := Trim(IniRead(ConfigPath, section, key, ""))
    if value = ""
        return -1
    return ParseColor(value, -1)
}

ParseColor(value, fallback) {
    value := Trim(value)
    if !RegExMatch(value, "i)^0x[0-9a-f]{6}$")
        return fallback
    try {
        return value + 0
    } catch {
        return fallback
    }
}

Shutdown(*) {
    global SyntheticLeftDown
    if SyntheticLeftDown {
        try SendEvent("{Blind}{LButton up}")
        SyntheticLeftDown := false
    }
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
