#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#NoTrayIcon
#Include %A_ScriptDir%\..\lib\TargetingCore.ahk
#Include %A_ScriptDir%\..\lib\MacroRuntime.ahk
#Include %A_ScriptDir%\..\lib\FovGuideCore.ahk
#Include %A_ScriptDir%\..\lib\FovViewport.ahk
#Include %A_ScriptDir%\..\lib\TargetOrigin.ahk
#Include %A_ScriptDir%\..\lib\CapturePolicy.ahk
#Include %A_ScriptDir%\..\lib\WorkerRuntime.ahk
Persistent

ConfigPath := A_ScriptDir "\..\config\settings.ini"
RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"
FullscreenHintKnown := false
FullscreenHint := false
LastFullscreenToggleTick := 0
CurrentViewportMode := ""
ViewportWindow := 0
FovGui := 0
FovLastFrame := ""
FovLastRegion := ""
FovLastStyle := ""
FovSettings := Map()
FovTargets := []
FovLastRefresh := -10000
FovTimerPrecision := DllCall("winmm\timeBeginPeriod", "UInt", 1, "UInt") = 0

EnablePhysicalPixelCoordinates()
SetWinDelay(-1)
OnExit(Shutdown)
HotIfWinActive(RobloxWindow)
Hotkey("~*!Enter", FullscreenAltEnter)
HotIfWinActive()
WorkerRuntimeInit("fov")
RefreshGuideConfig()
if !WorkerSignalReady()
    ExitApp()

Loop {
    if !MacroFocused() {
        HideGuide()
        Sleep(WorkerPollDelay(16, true, true))
        continue
    }
    frameStarted := MonotonicMs()
    try UpdateGuide()
    catch as err {
        HideGuide()
        WorkerSignalIssue("overlay-unavailable", err.Message)
    }
    remaining := Max(1, Ceil(WorkerPollDelay(4, false, true)-(MonotonicMs()-frameStarted)))
    DllCall("kernel32\Sleep", "UInt", remaining)
    Sleep(-1)
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
    if !FullscreenHintKnown {
        FullscreenHint := !WindowLooksFullscreen(hwnd)
        FullscreenHintKnown := true
    } else FullscreenHint := !FullscreenHint
    HideGuide()
}

RefreshGuideConfig() {
    global FovSettings, FovTargets, FovLastRefresh, ConfigPath
    source := MacroChoice("FOV", "Source", "auto", ["auto", "camlock", "aimlock", "triggerbot"])
    selected := "Aimlock"
    if source = "auto" {
        for section in ["Aimlock", "Camlock", "Triggerbot"] {
            if MacroNumber("Modules", section, 0, 0, 1) {
                selected := section
                break
            }
        }
    } else selected := source = "camlock" ? "Camlock" : source = "triggerbot" ? "Triggerbot" : "Aimlock"
    preferred := MacroRead("FOV", "Color", "0x89B4FA")
    if !RegExMatch(preferred, "i)^0x[0-9a-f]{6}$")
        preferred := "0x89B4FA"
    FovSettings := Map("Source", selected, "Shape", MacroChoice("FOV", "Shape", "circle", ["circle", "ellipse", "rectangle", "triangle", "diamond", "pentagon", "hexagon", "heptagon", "octagon", "decagon", "star", "heart", "cross", "shield"]),
        "Origin", MacroChoice("FOV", "Origin", "cursor", ["cursor", "camera pov", "camera"]),
        "Color", preferred+0, "Opacity", MacroNumber("FOV", "Opacity", 220, 128, 255),
        "Thickness", MacroNumber("FOV", "Thickness", 2, 1, 8),
        "Outline", MacroChoice("FOV", "OutlineStyle", "solid", ["solid", "dashed", "dotted", "segmented", "corners"]),
        "Mode", selected = "Triggerbot" ? "pixels" : MacroChoice(selected, "FovMode", "pixels", ["pixels", "degrees"]),
        "X", MacroNumber(selected, "FovX", 50, 0.1, 1000, false),
        "Y", MacroNumber(selected, "FovY", 40, 0.1, 1000, false),
        "Camera", MacroNumber(selected, "CameraFov", 80, 1, 120, false),
        "Scale", MacroChoice(selected, "ScaleMode", "auto", ["auto", "raw"]),
        "RefW", MacroNumber(selected, "ReferenceWidth", 1920, 320, 10000),
        "RefH", MacroNumber(selected, "ReferenceHeight", 1080, 240, 10000))
    FovTargets := OverlayTargetColors(ConfigPath, A_ScriptDir "\..\state")
    FovLastRefresh := MonotonicMs()
}

UpdateGuide() {
    global FovGui, FovLastFrame, FovLastRegion, FovLastStyle, FovSettings, FovTargets, FovLastRefresh, CurrentViewportMode
    if MonotonicMs()-FovLastRefresh >= 250
        RefreshGuideConfig()
    if !GetClientRect(&left, &top, &width, &height) {
        HideGuide()
        return
    }
    settings := FovSettings
    scaleX := settings["Scale"] = "raw" ? 1 : width/settings["RefW"]
    scaleY := settings["Scale"] = "raw" ? 1 : height/settings["RefH"]
    radii := FovGuideRadii(settings["Mode"], settings["X"], settings["Y"], settings["Camera"], width, height, scaleX, scaleY)
    GetTargetOrigin(settings["Origin"], left, top, width, height, &centerX, &centerY)
    status := A_ScriptDir "\..\state\" StrLower(settings["Source"]) ".status.ini"
    field := ReadGuideField(status, left, top, width, height)
    if field.Length {
        radii := [field[3], field[4]]
        GetTargetOrigin(settings["Origin"], left, top, width, height, &centerX, &centerY)
    }
    radii := ShapeFieldRadii(settings["Shape"], radii)
    color := FovSafeColor(settings["Color"], settings["Opacity"], FovTargets)
    if color < 0 {
        HideGuide()
        WorkerSignalIssue("overlay-color-conflict", "no guide color is outside target tolerance")
        return
    }
    thickness := settings["Thickness"]
    guideLeft := Max(left, Floor(centerX-radii[1]-thickness))
    guideTop := Max(top, Floor(centerY-radii[2]-thickness))
    guideRight := Min(left+width, Ceil(centerX+radii[1]+thickness+1))
    guideBottom := Min(top+height, Ceil(centerY+radii[2]+thickness+1))
    guideWidth := Max(1, guideRight-guideLeft)
    guideHeight := Max(1, guideBottom-guideTop)
    localCenterX := centerX-guideLeft
    localCenterY := centerY-guideTop
    regionSignature := (localCenterX "," localCenterY "," radii[1] "," radii[2] "," guideWidth "," guideHeight
        . "," thickness "," settings["Shape"] "," settings["Outline"])
    styleSignature := color "," settings["Opacity"]
    frameSignature := guideLeft "," guideTop "," guideWidth "," guideHeight "," regionSignature "," styleSignature
    if !IsObject(FovGui) {
        FovGui := Gui("-Owner -Caption -Border -DPIScale +AlwaysOnTop +ToolWindow +E0x08080020", "Da Larp FOV")
        FovGui.MarginX := 0
        FovGui.MarginY := 0
        FovLastRegion := ""
        FovLastStyle := ""
    }
    options := WorkerOptions()
    if !CaptureApply(FovGui.Hwnd, options["CaptureExcluded"]) && options["CaptureExcluded"]
        WorkerSignalIssue("capture-exclusion-unavailable", "FOV capture exclusion could not be applied")
    if styleSignature != FovLastStyle {
        FovGui.BackColor := Format("{:06X}", color)
        if !DllCall("user32\SetLayeredWindowAttributes", "Ptr", FovGui.Hwnd, "UInt", 0, "UChar", settings["Opacity"], "UInt", 2, "Int")
            throw OSError()
        FovLastStyle := styleSignature
    }
    if regionSignature != FovLastRegion {
        ApplyGuideStyledRegion(FovGui.Hwnd, localCenterX, localCenterY, radii[1], radii[2],
            guideWidth, guideHeight, thickness, settings["Shape"], settings["Outline"])
        FovLastRegion := regionSignature
    }
    if frameSignature = FovLastFrame
        return
    if !MacroFocused() {
        HideGuide()
        return
    }
    if !DllCall("user32\SetWindowPos", "Ptr", FovGui.Hwnd, "Ptr", -1,
        "Int", guideLeft, "Int", guideTop, "Int", guideWidth, "Int", guideHeight, "UInt", 0x50, "Int")
        throw OSError()
    FovLastFrame := frameSignature
    static lastViewport := ""
    viewport := left "," top "," width "," height "," CurrentViewportMode "," settings["Source"] "," settings["Origin"]
    if viewport != lastViewport {
        WorkerSignalViewport(CurrentViewportMode, left, top, width, height, "FOV guide: " settings["Source"] " / " settings["Origin"])
        lastViewport := viewport
    }
}

ReadGuideField(path, left, top, width, height) {
    static lastKey := "", lastRead := -10000, cached := []
    key := path ":" left "," top "," width "," height
    now := MonotonicMs()
    if key = lastKey && now-lastRead < 250
        return cached
    lastKey := key
    lastRead := now
    cached := []
    pid := IniRead(path, "Worker", "Pid", 0)
    if !IsNumber(pid) || pid <= 0 || !ProcessExist(pid)
        return []
    for pair in [["X",left], ["Y",top], ["Width",width], ["Height",height]] {
        value := IniRead(path, "Viewport", pair[1], "")
        if !IsNumber(value) || value+0 != pair[2]
            return []
    }
    field := []
    for key in ["CenterX", "CenterY", "RadiusX", "RadiusY"] {
        value := IniRead(path, "Field", key, "")
        if !IsNumber(value)
            return []
        field.Push(value+0)
    }
    if field[1] < left || field[1] >= left+width || field[2] < top || field[2] >= top+height
        || field[3] <= 0 || field[4] <= 0 || field[3] > 1000000 || field[4] > 1000000
        return []
    origin := IniRead(path, "Field", "Origin", "camera")
    field.Push(origin = "cursor" ? "cursor" : "camera")
    cached := field
    return cached
}

FovPolygonPoints(shape, cx, cy, rx, ry) {
    pts := []
    pi := 4*ATan(1)
    if shape = "cross" {
        for pair in [[-0.27,-1],[0.27,-1],[0.27,-0.27],[1,-0.27],[1,0.27],[0.27,0.27],
            [0.27,1],[-0.27,1],[-0.27,0.27],[-1,0.27],[-1,-0.27],[-0.27,-0.27]]
            pts.Push([Round(cx+rx*pair[1]), Round(cy+ry*pair[2])])
        return pts
    }
    if shape = "shield" {
        for pair in [[0,-1],[0.9,-0.8],[0.8,0.35],[0,1],[-0.8,0.35],[-0.9,-0.8]]
            pts.Push([Round(cx+rx*pair[1]), Round(cy+ry*pair[2])])
        return pts
    }
    if shape = "heart" {
        Loop 96 {
            angle := (A_Index-1)*2*pi/96
            x := 16*Sin(angle)**3/17
            y := -(13*Cos(angle)-5*Cos(2*angle)-2*Cos(3*angle)-Cos(4*angle))/18
            pts.Push([Round(cx+rx*x), Round(cy+ry*y)])
        }
        return pts
    }
    sides := shape = "triangle" ? 3 : shape = "diamond" ? 4 : shape = "pentagon" ? 5
        : shape = "hexagon" ? 6 : shape = "heptagon" ? 7 : shape = "octagon" ? 8
        : shape = "decagon" ? 10 : shape = "star" ? 10 : 32
    Loop sides {
        angle := (A_Index-1)*2*pi/sides-pi/2
        size := shape = "star" && Mod(A_Index,2)=0 ? 0.45 : 1
        pts.Push([Round(cx+rx*Cos(angle)*size), Round(cy+ry*Sin(angle)*size)])
    }
    return pts
}

FovShapeRegion(shape, cx, cy, rx, ry) {
    rx := Max(1, Round(rx)), ry := Max(1, Round(ry))
    if shape = "rectangle"
        return DllCall("gdi32\CreateRectRgn", "Int", cx-rx, "Int", cy-ry,
            "Int", cx+rx+1, "Int", cy+ry+1, "Ptr")
    if shape = "circle" || shape = "ellipse"
        return DllCall("gdi32\CreateEllipticRgn", "Int", cx-rx, "Int", cy-ry,
            "Int", cx+rx+1, "Int", cy+ry+1, "Ptr")
    pts := FovPolygonPoints(shape, cx, cy, rx, ry)
    data := Buffer(pts.Length*8, 0)
    for index, point in pts
        NumPut("Int", point[1], "Int", point[2], data, (index-1)*8)
    return DllCall("gdi32\CreatePolygonRgn", "Ptr", data.Ptr, "Int", pts.Length, "Int", 1, "Ptr")
}

ApplyGuideRegion(hwnd, centerX, centerY, radiusX, radiusY, width, height, thickness, shape) {
    outer := 0
    inner := 0
    clip := 0
    try {
        outer := FovShapeRegion(shape, centerX, centerY, radiusX+thickness, radiusY+thickness)
        inner := FovShapeRegion(shape, centerX, centerY, radiusX, radiusY)
        clip := DllCall("gdi32\CreateRectRgn", "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr")
        if !outer || !inner || !clip
            throw Error("Cannot create FOV regions")
        if !DllCall("gdi32\CombineRgn", "Ptr", outer, "Ptr", outer, "Ptr", inner, "Int", 4, "Int")
            throw Error("Cannot subtract FOV interior")
        if !DllCall("gdi32\CombineRgn", "Ptr", outer, "Ptr", outer, "Ptr", clip, "Int", 1, "Int")
            throw Error("Cannot clip FOV guide")
        if !DllCall("user32\SetWindowRgn", "Ptr", hwnd, "Ptr", outer, "Int", true, "Int")
            throw Error("Cannot apply FOV region")
        outer := 0
    } finally {
        for region in [outer, inner, clip]
            if region
                DllCall("gdi32\DeleteObject", "Ptr", region)
    }
}

HideGuide() {
    global FovGui, FovLastFrame
    if IsObject(FovGui)
        FovGui.Hide()
    FovLastFrame := ""
}

Shutdown(*) {
    global FovGui, FovTimerPrecision
    if IsObject(FovGui)
        try FovGui.Hide()
    if FovTimerPrecision
        DllCall("winmm\timeEndPeriod", "UInt", 1)
}

FovGuideSamplePoints(shape,cx,cy,rx,ry) {
    if shape != "circle" && shape != "ellipse" && shape != "rectangle"
        return FovPolygonPoints(shape,cx,cy,rx,ry)
    pts := []
    if shape="rectangle" {
        for pair in [[-1,-1],[1,-1],[1,1],[-1,1]]
            pts.Push([Round(cx+rx*pair[1]),Round(cy+ry*pair[2])])
        return pts
    }
    Loop 160 {
        angle := (A_Index-1)*2*4*ATan(1)/160
        pts.Push([Round(cx+rx*Cos(angle)),Round(cy+ry*Sin(angle))])
    }
    return pts
}

ApplyGuideStyledRegion(hwnd,cx,cy,rx,ry,width,height,thickness,shape,style) {
    if style="solid" {
        ApplyGuideRegion(hwnd,cx,cy,rx,ry,width,height,thickness,shape)
        return
    }
    region := DllCall("gdi32\CreateRectRgn", "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Ptr")
    clip := 0
    if !region
        throw Error("Cannot allocate FOV stroke region")
    pts := FovGuideSamplePoints(shape,cx,cy,rx,ry)
    perimeter := 0.0
    for idx, start in pts {
        finish := pts[idx=pts.Length ? 1 : idx+1]
        perimeter += Sqrt((finish[1]-start[1])**2+(finish[2]-start[2])**2)
    }
    travelled := 0.0
    try {
        for idx, start in pts {
            finish := pts[idx=pts.Length ? 1 : idx+1]
            vx := finish[1]-start[1], vy := finish[2]-start[2]
            span := Sqrt(vx*vx+vy*vy)
            if span < 0.1
                continue
            segments := Max(1,Ceil(span/3))
            Loop segments {
                q := A_Index-1
                progress := travelled+(q+0.5)*span/segments
                shown := style="dotted" ? Mod(Floor(progress/4),2)=0
                    : style="dashed" ? Mod(progress,18)<10
                    : style="segmented" ? Mod(progress,34)<24
                    : shape="circle" || shape="ellipse" ? Mod(progress+perimeter/8,perimeter/4)<perimeter/18
                    : (q/segments<0.18 || q/segments>0.82)
                if !shown
                    continue
                px := Round(start[1]+vx*(q+0.5)/segments)
                py := Round(start[2]+vy*(q+0.5)/segments)
                thick := Max(1,thickness)
                piece := DllCall("gdi32\CreateEllipticRgn", "Int", px-thick,
                    "Int", py-thick, "Int", px+thick+1, "Int", py+thick+1, "Ptr")
                if !piece
                    throw Error("Cannot allocate FOV dash")
                try {
                    if !DllCall("gdi32\CombineRgn", "Ptr", region, "Ptr", region, "Ptr", piece, "Int", 2, "Int")
                        throw Error("Cannot combine FOV dash")
                } finally DllCall("gdi32\DeleteObject", "Ptr", piece)
            }
            travelled += span
        }
        clip := DllCall("gdi32\CreateRectRgn", "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr")
        if !clip || !DllCall("gdi32\CombineRgn", "Ptr", region, "Ptr", region, "Ptr", clip, "Int", 1, "Int")
            throw Error("Cannot clip FOV dash region")
        if !DllCall("user32\SetWindowRgn", "Ptr", hwnd, "Ptr", region, "Int", 1, "Int")
            throw Error("Cannot apply FOV dash region")
        region := 0
    } finally {
        if region
            DllCall("gdi32\DeleteObject", "Ptr", region)
        if clip
            DllCall("gdi32\DeleteObject", "Ptr", clip)
    }
}
