global IvoryTypingRegistered := ""
global IvoryTypingLatch := false

IvoryTypingContext(*) {
    return !IvoryKeyCaptureActive() && !!WinActive("ahk_exe RobloxPlayerBeta.exe")
}

RegisterTypingHotkey() {
    global IvoryTypingRegistered, IvoryTypingLatch
    key := Cfg("App", "TypingKey", "RShift")
    HotIf(IvoryTypingContext)
    try {
        if IvoryTypingRegistered != "" {
            Hotkey("~$*" IvoryTypingRegistered, "Off")
            Hotkey("~$*" IvoryTypingRegistered " up", "Off")
        }
        Hotkey("~$*" key, IvoryTypingDown, "On")
        Hotkey("~$*" key " up", IvoryTypingUp, "On")
        IvoryTypingRegistered := key
        IvoryTypingLatch := GetKeyState(key, "P")
    } finally HotIf()
    SetTimer(IvoryTypingGuard, 50)
}

IvoryTypingGuard() {
    global IvoryTypingLatch, IvoryTypingRegistered
    if IvoryTypingRegistered != "" && !GetKeyState(IvoryTypingRegistered, "P")
        IvoryTypingLatch := false
}

IvoryTypingDown(*) {
    global IvoryTypingLatch, IvoryTypingRegistered
    if IvoryTypingLatch || !GetKeyState(IvoryTypingRegistered, "P")
        return
    IvoryTypingLatch := true
    paused := !CfgBool("App", "TypingMode", false)
    if SetCfg("App", "TypingMode", paused ? 1 : 0, false) {
        RefreshAllValues()
        SetStatus(paused ? "typing mode: input features paused" : "typing mode off", "ok")
    }
}

IvoryTypingUp(*) {
    global IvoryTypingLatch
    IvoryTypingLatch := false
}

TypingInputPaused(module) {
    return CfgBool("App", "TypingMode", false) && module != "FOV" && module != "WeaponDetection"
}

IvoryRuntimeRefresh() {
    if IvoryUI.ToolbarEnabled && IsObject(IvoryUI.Toolbar)
        SetTimer(IvoryToolbarAnimate, CfgBool("App", "CPUFriendly", false) ? 33 : 16)
}

IvoryApplyCapture(hwnd) {
    return CaptureApply(hwnd, CfgBool("App", "CaptureExcluded", false))
}

IvoryCaptureRefresh(force := false) {
    global CapturePolicyCache
    enabled := CfgBool("App", "CaptureExcluded", false)
    oldHidden := A_DetectHiddenWindows
    present := Map()
    success := true
    DetectHiddenWindows(true)
    currentPid := DllCall("GetCurrentProcessId", "UInt")
    try {
        for hwnd in WinGetList("ahk_pid " currentPid) {

            if !CapturePolicyCache.Has(hwnd) && !DllCall("user32\IsWindowVisible", "Ptr", hwnd, "Int")
                continue
            present[hwnd] := true
            if !CaptureApply(hwnd, enabled, force)
                success := false
        }
    } finally DetectHiddenWindows(oldHidden)
    CaptureForgetMissing(present)
    return success
}

IvoryCaptureTick() {
    IvoryCaptureRefresh()
}
