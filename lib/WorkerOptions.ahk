WorkerOptions() {
    static options := Map(), lastRead := -10000
    now := DllCall("kernel32\GetTickCount64", "UInt64")
    if options.Count && now-lastRead < 250
        return options
    path := A_ScriptDir "\..\config\settings.ini"
    fresh := Map()
    for name in ["CPUFriendly", "CaptureExcluded", "TypingMode"]
        fresh[name] := IniRead(path, "App", name, 0) = 1
    fresh["WeaponDetection"] := IniRead(path, "Modules", "WeaponDetection", 0) = 1
    fresh["FOVEnabled"] := IniRead(path, "Modules", "FOV", 0) = 1
    origin := StrLower(IniRead(path, "FOV", "Origin", "cursor"))
    fresh["FOVOrigin"] := origin = "cursor" ? "cursor" : "camera"
    shape := StrLower(IniRead(path, "FOV", "Shape", "circle"))
    fresh["FOVShape"] := InStr("|circle|ellipse|rectangle|triangle|diamond|pentagon|hexagon|heptagon|octagon|decagon|star|heart|cross|shield|", "|" shape "|") ? shape : "circle"
    fresh["BackgroundReject"] := IniRead(path, "Detection", "BackgroundReject", 1) = 1
    value := IniRead(path, "Detection", "BackgroundFillLimit", 68)
    fresh["BackgroundFillLimit"] := IsNumber(value) ? Max(40,Min(95,Round(value+0))) : 68
    rejectModeName := StrLower(Trim(IniRead(path, "Detection", "BackgroundMode", "balanced")))
    fresh["BackgroundMode"] := rejectModeName = "strict" ? "strict" : "balanced"
    fresh["AdaptiveScan"] := IniRead(path, "Detection", "AdaptiveScan", 1) = 1
    interval := IniRead(path, "WeaponDetection", "ScanMs", 100)
    fresh["WeaponScanMs"] := IsNumber(interval) ? Min(1000, Max(50, interval+0)) : 100
    options := fresh
    lastRead := now
    return options
}

PollDelay(ms, cpuFriendly, idle := false, visual := false) {
    return cpuFriendly ? Max(ms, visual ? 33 : idle ? 25 : 8) : ms
}

WorkerPollDelay(ms, idle := false, visual := false) {
    return PollDelay(ms, WorkerOptions()["CPUFriendly"], idle, visual)
}

WorkerInputAllowed() {
    return !FileExist(A_ScriptDir "\..\state\typing.pause") && !WorkerOptions()["TypingMode"]
}

WorkerCameraCalibration() {
    static values := Map(), lastRead := -10000
    now := DllCall("kernel32\GetTickCount64", "UInt64")
    if values.Count && now-lastRead < 250
        return values
    path := A_ScriptDir "\..\config\settings.ini"
    values := Map()
    for spec in [["UnitsPer360",2000,1,1000000],["ReferenceSensitivity",0.2,0.001,10],
        ["Sensitivity",0.2,0.001,10],["ReferenceDpi",1600,50,100000],["Dpi",1600,50,100000]] {
        value := IniRead(path, "CameraTurn", spec[1], spec[2])
        values[spec[1]] := IsNumber(value) ? Min(spec[4], Max(spec[3], value+0)) : spec[2]
    }
    values["DpiScaling"] := IniRead(path, "CameraTurn", "DpiScaling", 0) = 1
    lastRead := now
    return values
}

WeaponSnapshot(text) {
    snapshot := Map()
    if !RegExMatch(text, "m)^Pid=(\d+)", &pid)
        return Map()
    snapshot["Pid"] := pid[1]
    if !RegExMatch(text, "ms)^\[Weapon\]\r?\n(.*?)(?=^\[|\z)", &section)
        return Map()
    for name in ["Allowed", "Updated", "Hwnd", "Name"] {
        if !RegExMatch(section[1], "m)^" name "=([^\r\n]*)", &match)
            return Map()
        snapshot[name] := match[1]
    }
    for name in ["Pid", "Allowed", "Updated", "Hwnd"]
        if !IsNumber(snapshot[name])
            return Map()
    return snapshot
}

WeaponSnapshotAllows(snapshot, now, maxAge, foreground, live) {
    return snapshot.Count && live && snapshot["Pid"] > 0 && snapshot["Allowed"] = 1
        && snapshot["Hwnd"] = foreground && foreground != 0
        && now >= snapshot["Updated"] && now-snapshot["Updated"] <= maxAge
}

WorkerAllowsFire() {
    static lastRead := -10000, snapshot := Map()
    options := WorkerOptions()
    if !options["WeaponDetection"]
        return true
    now := DllCall("kernel32\GetTickCount64", "UInt64")
    if now-lastRead >= 20 {
        snapshot := Map()
        try snapshot := WeaponSnapshot(FileRead(A_ScriptDir "\..\state\weapondetection.status.ini", "UTF-16"))
        lastRead := now
    }
    if !snapshot.Count
        return false
    live := snapshot["Pid"] > 0 && !!ProcessExist(snapshot["Pid"])
    return WeaponSnapshotAllows(snapshot, now, Max(500, options["WeaponScanMs"]*3),
        WinActive("ahk_exe RobloxPlayerBeta.exe"), live)
}
