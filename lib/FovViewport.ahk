#Include %A_LineFile%\..\ViewportPolicy.ahk
GetClientRect(&x, &y, &w, &h) {
    global RobloxWindow, FullscreenHintKnown, FullscreenHint, CurrentViewportMode
    global ViewportWindow, LastFullscreenToggleTick

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
