global CapturePolicyCache := Map()

CaptureExclusionSupported() {
    static supported := -1
    if supported >= 0
        return supported
    version := Buffer(284, 0)
    NumPut("UInt", 284, version)
    supported := DllCall("ntdll\RtlGetVersion", "Ptr", version, "Int") = 0
        && (NumGet(version, 4, "UInt") > 10 ||
            (NumGet(version, 4, "UInt") = 10 && NumGet(version, 12, "UInt") >= 19041))
    return supported
}

CaptureApply(hwnd, enabled, force := false) {
    global CapturePolicyCache
    if !hwnd || !DllCall("user32\IsWindow", "Ptr", hwnd, "Int")
        return false
    if !force && CapturePolicyCache.Has(hwnd) && CapturePolicyCache[hwnd][1] = enabled
        return CapturePolicyCache[hwnd][2]
    success := !enabled || CaptureExclusionSupported()
    if success
        success := !!DllCall("user32\SetWindowDisplayAffinity", "Ptr", hwnd, "UInt", enabled ? 0x11 : 0, "Int")
    CapturePolicyCache[hwnd] := [enabled, success]
    return success
}

CaptureForgetMissing(present) {
    global CapturePolicyCache
    obsolete := []
    for hwnd, _ in CapturePolicyCache
        if !present.Has(hwnd)
            obsolete.Push(hwnd)
    for hwnd in obsolete
        CapturePolicyCache.Delete(hwnd)
}
