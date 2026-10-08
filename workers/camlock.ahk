#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\TargetOrigin.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
#Include %A_ScriptDir%\..\lib\FovGuideCore.ahk
#Include %A_ScriptDir%\..\lib\TargetSnapshot.ahk
#Include %A_ScriptDir%\..\lib\TargetEngine.ahk
#Include %A_ScriptDir%\..\lib\TargetingPreflight.ahk
#Include %A_ScriptDir%\..\lib\TrackingSearch.ahk
#Include %A_ScriptDir%\..\lib\CapturePolicy.ahk
#Include %A_ScriptDir%\..\lib\TargetMarker.ahk
#Include %A_ScriptDir%\..\lib\ViewportPolicy.ahk
Persistent

RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
ConfigPath := A_ScriptDir "\..\config\settings.ini"
Prefix := "Camlock"

HotkeyName := ReadKey(Prefix, "Hotkey", "RButton")
Mode := ReadChoice(Prefix, "Mode", "hold", ["hold", "toggle", "always"])
Origin := ReadChoice(Prefix, "Origin", "camera", ["camera", "cursor"])
ScaleMode := ReadChoice(Prefix, "ScaleMode", "auto", ["auto", "raw"])
ReferenceWidth := ReadInt(Prefix, "ReferenceWidth", 1920, 320, 10000)
ReferenceHeight := ReadInt(Prefix, "ReferenceHeight", 1080, 240, 10000)
FovMode := ReadChoice(Prefix, "FovMode", "pixels", ["pixels", "degrees"])
CameraFov := ReadFloat(Prefix, "CameraFov", 80, 1, 120)
FovX := ReadFloat(Prefix, "FovX", 85, 0.1, 1000)
FovY := ReadFloat(Prefix, "FovY", 65, 0.1, 1000)
TargetColor := ReadColor(Prefix, "TargetColor", 0x000000)
SecondaryColor := ReadOptionalColor(Prefix, "SecondaryColor")
Tolerance := ReadInt(Prefix, "Tolerance", 8, 0, 255)
TertiaryColor := ReadOptionalColor(Prefix, "TertiaryColor")
SecondaryTolerance := ReadInt(Prefix, "SecondaryTolerance", -1, -1, 255)
TertiaryTolerance := ReadInt(Prefix, "TertiaryTolerance", -1, -1, 255)
ScanColors := [TargetColor, SecondaryColor, TertiaryColor]
ScanTolerances := [Tolerance, SecondaryTolerance < 0 ? Tolerance : SecondaryTolerance, TertiaryTolerance < 0 ? Tolerance : TertiaryTolerance]
MinPixels := ReadInt(Prefix, "MinPixels", 1, 1, 9)
AngularMotion := ReadBool(Prefix, "AngularMotion", false)
TertiaryOffsetX := ReadInt(Prefix, "TertiaryOffsetX", 0, -500, 500)
TertiaryOffsetY := ReadInt(Prefix, "TertiaryOffsetY", 0, -500, 500)
global SampleCapturedAt := 0
ScanMs := ReadInt(Prefix, "ScanMs", 5, 1, 100)
ResponseMs := ReadFloat(Prefix, "ResponseMs", 5, 1, 50)
StrengthX := ReadFloat(Prefix, "StrengthX", 0.12, 0.01, 2.0)
StrengthY := ReadFloat(Prefix, "StrengthY", 0.11, 0.01, 2.0)
ResponseCurve := ReadChoice(Prefix, "ResponseCurve", "smooth", ["smooth", "linear", "aggressive"])
PredictionEnabled := ReadBool(Prefix, "PredictionEnabled", false)
LeadMsX := ReadFloat(Prefix, "LeadMsX", 6, 0, 100)
LeadMsY := ReadFloat(Prefix, "LeadMsY", 4, 0, 100)
VelocityBlend := ReadFloat(Prefix, "VelocityBlend", 0.22, 0.05, 1.0)
CurveLowX := ReadFloat(Prefix, "CurveLowX", 0.60, 0, 2.0)
CurveMidX := ReadFloat(Prefix, "CurveMidX", 1.0, 0, 2.0)
CurveHighX := ReadFloat(Prefix, "CurveHighX", 1.15, 0, 2.0)
CurveLowY := ReadFloat(Prefix, "CurveLowY", 0.60, 0, 2.0)
CurveMidY := ReadFloat(Prefix, "CurveMidY", 1.0, 0, 2.0)
CurveHighY := ReadFloat(Prefix, "CurveHighY", 1.15, 0, 2.0)
AccelerationGainX := ReadFloat(Prefix, "AccelerationGainX", 0.15, 0, 1.0)
AccelerationGainY := ReadFloat(Prefix, "AccelerationGainY", 0.12, 0, 1.0)
MaxLeadPx := ReadFloat(Prefix, "MaxLeadPx", 8, 0, 250)
MaxStep := ReadInt(Prefix, "MaxStep", 24, 1, 500)
Deadzone := ReadFloat(Prefix, "Deadzone", 1.5, 0, 50)
LockRadius := ReadInt(Prefix, "LockRadius", 34, 4, 300)
LockHoldMs := ReadInt(Prefix, "LockHoldMs", 85, 0, 500)
SwitchDelayMs := ReadInt(Prefix, "SwitchDelayMs", 90, 0, 400)
OffsetX := ReadInt(Prefix, "OffsetX", 0, -500, 500)
OffsetY := ReadInt(Prefix, "OffsetY", 5, -500, 500)
SecondaryOffsetX := ReadInt(Prefix, "SecondaryOffsetX", 0, -500, 500)
SecondaryOffsetY := ReadInt(Prefix, "SecondaryOffsetY", 0, -500, 500)

global Held := false
global ToggleState := false
global KeyLatch := false
global ActivationBlocked := false
global TrackValid := false
global TrackX := 0.0
global TrackY := 0.0
global LastSampleTick := 0
global LastSeenTick := 0
global VelocityX := 0.0
global VelocityY := 0.0
global AccelerationX := 0.0
global AccelerationY := 0.0
global ResidualX := 0.0
global ResidualY := 0.0
global TrackSamples := 0
global TargetReacquired := true
global TrackSecondary := false
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
    try WorkerTargetingProbe(Prefix, ScanColors, ScanTolerances, MinPixels,
        Map("AngularMotion",AngularMotion,"TertiaryOffsetX",TertiaryOffsetX,
            "TertiaryOffsetY",TertiaryOffsetY,"SampleCapturedAt",SampleCapturedAt))
    catch as err {
        FileAppend(Prefix " startup preflight failed: " err.Message "`n","**")
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
WorkerRuntimeInit("camlock")
TargetSnapshot.Init()
TargetMarker.Init(Prefix)
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

    ResetTracking(true)
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
        TrackOnce()
        PreciseSleep(WorkerPollDelay(ScanMs))
    } else {
        ResetTracking(true)
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

TrackOnce() {
    global TrackValid, TrackX, TrackY, LastSampleTick, LastSeenTick
    global VelocityX, VelocityY, AccelerationX, AccelerationY, ResidualX, ResidualY, TrackSamples
    global StrengthX, StrengthY, ResponseCurve, PredictionEnabled, ResponseMs, ScanMs
    global LeadMsX, LeadMsY, VelocityBlend, MaxLeadPx
    global CurveLowX, CurveMidX, CurveHighX, CurveLowY, CurveMidY, CurveHighY, AccelerationGainX, AccelerationGainY
    global MaxStep, Deadzone, OffsetX, OffsetY, SecondaryOffsetX, SecondaryOffsetY, LockHoldMs, SwitchDelayMs
    global TargetReacquired, TrackSecondary, SampleCapturedAt, TertiaryOffsetX, TertiaryOffsetY

    found := FindTarget(&targetX, &targetY, &secondary, &centerX, &centerY, &scaleX, &scaleY, &captureFailed)
    now := MonotonicMs()
    sampleTick := SampleCapturedAt

    if !IsEngaged() {
        ResetTracking(true)
        return
    }
    if !found {
        TargetMarker.Hide()

        if captureFailed {
            WorkerSignalIssue("capture-unavailable", "screen pixels unavailable")
            return
        }
        if TrackValid && now - LastSeenTick <= Max(LockHoldMs, SwitchDelayMs)
            return
        ResetTracking(true)
        return
    }

    if now-sampleTick > 50 {
        ResetTracking(true)
        return
    }

    gapSinceSeen := TrackValid && LastSeenTick > 0 ? Max(0.0, now - LastSeenTick) : 0.0
    staleThreshold := Max(25.0, Max(ScanMs, ResponseMs) * 4.0)
    staleTrack := TrackValid && (gapSinceSeen > staleThreshold || TargetReacquired || TrackSecondary != secondary)
    sampleDt := TrackValid && LastSampleTick > 0 && !staleTrack ? Max(0.1, Min(100, sampleTick - LastSampleTick)) : ResponseMs
    if TrackValid && LastSampleTick > 0 && !staleTrack {
        instantVX := (targetX - TrackX) / sampleDt
        instantVY := (targetY - TrackY) / sampleDt

        maxVelX := LeadMsX > 0 && MaxLeadPx > 0 ? ((MaxLeadPx * scaleX) / LeadMsX) * 1.5 : 9999.0
        maxVelY := LeadMsY > 0 && MaxLeadPx > 0 ? ((MaxLeadPx * scaleY) / LeadMsY) * 1.5 : 9999.0
        instantVX := Clamp(instantVX, -maxVelX, maxVelX)
        instantVY := Clamp(instantVY, -maxVelY, maxVelY)
        blend := TemporalBlend(VelocityBlend, sampleDt, ScanMs)
        previousVX := VelocityX, previousVY := VelocityY
        VelocityX := VelocityX * (1.0 - blend) + instantVX * blend
        VelocityY := VelocityY * (1.0 - blend) + instantVY * blend
        AccelerationX := AccelerationX*0.7+(VelocityX-previousVX)/sampleDt*0.3
        AccelerationY := AccelerationY*0.7+(VelocityY-previousVY)/sampleDt*0.3
        TrackSamples += 1
    } else {
        VelocityX := 0.0
        VelocityY := 0.0
        AccelerationX := 0.0
        AccelerationY := 0.0
        ResidualX := 0.0
        ResidualY := 0.0
        TrackSamples := 1
    }

    TrackX := targetX
    TrackY := targetY
    TrackSecondary := secondary
    TrackValid := true
    LastSampleTick := sampleTick
    LastSeenTick := now

    scaledOffsets := TrackingScaledOffsets(secondary, scaleX, scaleY, OffsetX, OffsetY,
        SecondaryOffsetX, SecondaryOffsetY, TertiaryOffsetX, TertiaryOffsetY)
    scaledOffsetX := scaledOffsets[1]
    scaledOffsetY := scaledOffsets[2]
    maxLeadX := MaxLeadPx * scaleX
    maxLeadY := MaxLeadPx * scaleY
    predictionReady := PredictionEnabled && TrackSamples >= 3
    leadX := predictionReady ? TrackingAdvancedLead(VelocityX, AccelerationX, LeadMsX, now-sampleTick, maxLeadX,
        TrackSamples, sampleDt, CurveLowX, CurveMidX, CurveHighX, AccelerationGainX) : 0.0
    leadY := predictionReady ? TrackingAdvancedLead(VelocityY, AccelerationY, LeadMsY, now-sampleTick, maxLeadY,
        TrackSamples, sampleDt, CurveLowY, CurveMidY, CurveHighY, AccelerationGainY) : 0.0
    desiredX := targetX + scaledOffsetX + leadX
    desiredY := targetY + scaledOffsetY + leadY
    TargetMarker.Show(desiredX, desiredY)

    dx := desiredX - centerX
    dy := desiredY - centerY
    referenceDx := dx / Max(0.001, scaleX)
    referenceDy := dy / Max(0.001, scaleY)
    distance := Sqrt(referenceDx * referenceDx + referenceDy * referenceDy)
    if distance <= Deadzone {
        ResidualX := 0.0
        ResidualY := 0.0
        return
    }

    response := ResponseMultiplier(distance, ResponseCurve)
    TrackingMotionUnits(desiredX, desiredY, centerX, centerY, scaleX, scaleY, &motionX, &motionY)
    rawX := motionX * TimeGain(StrengthX, response, sampleDt, ResponseMs)
    rawY := motionY * TimeGain(StrengthY, response, sampleDt, ResponseMs)
    LimitMotion(&rawX, &rawY, MaxStep)

    QuantizeMotion(rawX, rawY, MaxStep, &ResidualX, &ResidualY, &moveX, &moveY)

    if moveX != 0 || moveY != 0 {
        if IsEngaged()
            MoveRelative(moveX, moveY)
        else
            ResetTracking(true)
    }
}

FindTarget(&outX, &outY, &secondary, &centerX, &centerY, &scaleX, &scaleY, &captureFailed := unset) {
    return TrackingFindTarget(&outX, &outY, &secondary, &centerX, &centerY, &scaleX, &scaleY, &captureFailed)
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
        ResetTracking(true)
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

DistanceSquared(x1, y1, x2, y2) {
    dx := x1 - x2
    dy := y1 - y2
    return dx * dx + dy * dy
}

ResponseMultiplier(distance, curve) {
    normalized := Min(1.0, distance / 120.0)
    if curve = "smooth"
        return 0.18 + 0.82 * (normalized ** 1.35)
    if curve = "aggressive"
        return 1.02 + 0.48 * normalized
    return 1.0
}

ResetTracking(clearResidual := true) {
    TargetMarker.Hide()
    global TrackValid, LastSampleTick, LastSeenTick, VelocityX, VelocityY, AccelerationX, AccelerationY, ResidualX, ResidualY, TrackSamples
    global TrackSecondary, TargetReacquired
    TrackValid := false
    LastSampleTick := 0
    LastSeenTick := 0
    VelocityX := 0.0
    VelocityY := 0.0
    AccelerationX := 0.0
    AccelerationY := 0.0
    TrackSamples := 0
    TrackSecondary := false
    TargetReacquired := true
    if clearResidual {
        ResidualX := 0.0
        ResidualY := 0.0
    }
}

VerticalToHorizontalFov(verticalFov, width, height) {
    verticalFov := Clamp(verticalFov + 0.0, 1.0, 179.0)
    if width <= 0 || height <= 0
        return verticalFov
    halfVertical := DegToRad(verticalFov) / 2.0
    return RadToDeg(2.0 * ATan(Tan(halfVertical) * (width / height)))
}

DegreesToPixels(degrees, axisFov, dimension) {
    degrees := Clamp(degrees + 0.0, 0.05, 89.0)
    axisFov := Clamp(axisFov + 0.0, 1.0, 179.0)
    ratio := Tan(DegToRad(degrees)) / Tan(DegToRad(axisFov) / 2.0)
    return Max(1, Round((dimension / 2.0) * ratio))
}

DegToRad(degrees) {
    return degrees * 0.017453292519943295
}

RadToDeg(radians) {
    return radians * 57.29577951308232
}

MoveRelative(dx, dy) {
    DllCall("user32\mouse_event", "UInt", 0x0001, "Int", dx, "Int", dy, "UInt", 0, "UPtr", 0)
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

PreciseSleep(ms) {
    if ms > 0
        DllCall("kernel32\Sleep", "UInt", Round(ms))
}

TruncTowardZero(value) {
    return value >= 0 ? Floor(value) : Ceil(value)
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

ReadFloat(section, key, fallback, minV, maxV) {
    global ConfigPath
    value := IniRead(ConfigPath, section, key, fallback)
    if !IsNumber(value)
        return fallback
    return Min(maxV, Max(minV, value + 0.0))
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
    ResetTracking(true)
    DllCall("winmm\timeEndPeriod", "UInt", 1)
}
