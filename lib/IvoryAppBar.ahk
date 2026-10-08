IvoryAppBarInit() {
    IvoryUI.AppBarMessage := DllCall("user32\RegisterWindowMessageW", "Str", "DaLarp.AppBar.12", "UInt")
    IvoryUI.TaskbarMessage := DllCall("user32\RegisterWindowMessageW", "Str", "TaskbarCreated", "UInt")
    OnMessage(IvoryUI.AppBarMessage, IvoryAppBarNotify)
    OnMessage(IvoryUI.TaskbarMessage, IvoryAppBarExplorerRestarted)
    OnMessage(0x47, IvoryAppBarWindowPositionChanged)
}

IvoryAppBarData() {
    data := Buffer(A_PtrSize = 8 ? 48 : 36, 0)
    NumPut("UInt", data.Size, data, 0)
    NumPut("Ptr", IvoryUI.Toolbar.Hwnd, data, A_PtrSize = 8 ? 8 : 4)
    NumPut("UInt", IvoryUI.AppBarMessage, data, A_PtrSize = 8 ? 16 : 8)
    NumPut("UInt", 1, data, A_PtrSize = 8 ? 20 : 12)
    return data
}

IvoryAppBarPosition(left, top, right, height) {
    fallback := {left: left, top: top, right: right, bottom: top+height}
    if !CfgBool("App", "TopBarReserveSpace", true) {
        IvoryAppBarRemove()
        return fallback
    }
    if !IvoryUI.AppBarRegistered {
        data := IvoryAppBarData()
        if !DllCall("shell32\SHAppBarMessage", "UInt", 0, "Ptr", data, "UPtr") {
            if !IvoryUI.AppBarFailed
                SetStatus("top bar visible · Windows could not reserve space", "error")
            IvoryUI.AppBarFailed := true
            return fallback
        }
        IvoryUI.AppBarRegistered := true
        IvoryUI.AppBarFailed := false
        IvoryUI.AppBarDirty := true
    }
    desired := left "|" top "|" right "|" height
    if !IvoryUI.AppBarDirty && IvoryUI.AppBarDesired = desired && IsObject(IvoryUI.AppBarRect)
        return IvoryUI.AppBarRect
    data := IvoryAppBarData()
    offset := A_PtrSize = 8 ? 24 : 16
    NumPut("Int", left, "Int", top, "Int", right, "Int", top+height, data, offset)
    DllCall("shell32\SHAppBarMessage", "UInt", 2, "Ptr", data, "UPtr")
    adjustedTop := NumGet(data, offset+4, "Int")
    NumPut("Int", adjustedTop+height, data, offset+12)
    proposed := {left: NumGet(data, offset, "Int"), top: adjustedTop,
        right: NumGet(data, offset+8, "Int"), bottom: adjustedTop+height}

    old := IvoryUI.AppBarRect
    if !IsObject(old) || old.left != proposed.left || old.top != proposed.top
        || old.right != proposed.right || old.bottom != proposed.bottom {
        DllCall("shell32\SHAppBarMessage", "UInt", 3, "Ptr", data, "UPtr")
        proposed := {left: NumGet(data, offset, "Int"), top: NumGet(data, offset+4, "Int"),
            right: NumGet(data, offset+8, "Int"), bottom: NumGet(data, offset+12, "Int")}
    }
    if proposed.right <= proposed.left || proposed.bottom <= proposed.top {
        IvoryAppBarRemove()
        return fallback
    }
    IvoryUI.AppBarRect := proposed
    IvoryUI.AppBarDesired := desired
    IvoryUI.AppBarDirty := false
    return proposed
}

IvoryAppBarRemove(*) {
    registered := IvoryUI.AppBarRegistered
    IvoryUI.AppBarRegistered := false
    if registered && IsObject(IvoryUI.Toolbar) {
        data := IvoryAppBarData()
        DllCall("shell32\SHAppBarMessage", "UInt", 1, "Ptr", data, "UPtr")
    }
    IvoryUI.AppBarRect := 0
    IvoryUI.AppBarDesired := ""
    IvoryUI.AppBarDirty := true
    IvoryUI.AppBarFailed := false
}

IvoryAppBarNotify(wParam, lParam, msg, hwnd) {
    if !IvoryUI.AppBarRegistered || hwnd != IvoryUI.Toolbar.Hwnd
        return
    if wParam = 1 {
        IvoryUI.AppBarDirty := true
        if !IvoryUI.ToolbarPositioning
            SetTimer(IvoryPositionToolbar, -1)
    } else if wParam = 2 && !lParam {
        SetTimer(IvoryKeepToolbarTop, -1)
    }
}

IvoryAppBarExplorerRestarted(*) {

    IvoryUI.AppBarRegistered := false
    IvoryUI.AppBarRect := 0
    IvoryUI.AppBarDirty := true
    IvoryUI.AppBarFailed := false
    if IvoryUI.ToolbarEnabled
        SetTimer(IvoryPositionToolbar, -100)
}

IvoryAppBarWindowPositionChanged(wParam, lParam, msg, hwnd) {
    if IvoryUI.AppBarRegistered && hwnd = IvoryUI.Toolbar.Hwnd {
        data := IvoryAppBarData()
        DllCall("shell32\SHAppBarMessage", "UInt", 9, "Ptr", data, "UPtr")
    }
}

IvoryAppBarActivate(hwnd) {
    if IvoryUI.AppBarRegistered && hwnd = IvoryUI.Toolbar.Hwnd {
        data := IvoryAppBarData()
        DllCall("shell32\SHAppBarMessage", "UInt", 6, "Ptr", data, "UPtr")
    }
}

IvoryEnterPhysicalDpi() {
    previous := 0
    try previous := DllCall("user32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    return previous
}

IvoryRestoreDpi(previous) {
    if previous
        DllCall("user32\SetThreadDpiAwarenessContext", "Ptr", previous, "Ptr")
}
