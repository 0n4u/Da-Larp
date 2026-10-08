#Include %A_ScriptDir%\..\lib\WorkerOptions.ahk

#Include %A_ScriptDir%\..\lib\InputOwnership.ahk

global DHS_WorkerName := ""
global DHS_ReadyPath := ""
global DHS_StatusPath := ""
global DHS_LastIssueTick := 0
global DHS_Viewport := Map()
global DHS_Field := Map()
global DHS_Weapon := Map()
global DHS_LastFieldWrite := -10000
global DHS_FieldPending := false

global DHS_StateDir := A_ScriptDir "\..\state"

WorkerRuntimeInit(name) {
    global DHS_WorkerName, DHS_ReadyPath, DHS_StatusPath, DHS_StateDir
    DHS_WorkerName := StrLower(name)
    if !DirExist(DHS_StateDir)
        DirCreate(DHS_StateDir)
    DHS_ReadyPath := DHS_StateDir "\" DHS_WorkerName ".ready"
    DHS_StatusPath := DHS_StateDir "\" DHS_WorkerName ".status.ini"
    try FileDelete(DHS_ReadyPath)
    try FileDelete(DHS_StatusPath)
    OnExit(WorkerRuntimeExit)
}

WorkerSignalReady(detail := "ready") {
    global DHS_ReadyPath, DHS_WorkerName
    if DHS_ReadyPath = ""
        return false
    pid := DllCall("kernel32\GetCurrentProcessId", "UInt")
    payload := "name=" DHS_WorkerName "`npid=" pid "`nstate=ready`ndetail=" detail "`ntick=" A_TickCount "`n"
    try {
        FileAppend(payload, DHS_ReadyPath, "UTF-8")
        WorkerSignalStatus("ready", detail)
        return true
    } catch {
        return false
    }
}

WorkerSignalStatus(state, detail := "", viewportMode := "", x := "", y := "", w := "", h := "") {
    global DHS_StatusPath, DHS_WorkerName, DHS_Viewport, DHS_Field, DHS_Weapon
    if DHS_StatusPath = ""
        return false
    temp := DHS_StatusPath ".tmp"
    pid := DllCall("kernel32\GetCurrentProcessId", "UInt")
    text := "[Worker]`nName=" DHS_WorkerName "`nPid=" pid "`nState=" state "`nDetail=" SanitizeWorkerStatus(detail) "`nTick=" A_TickCount "`n"
    if viewportMode != "" || w != "" {
        DHS_Viewport := Map("Mode", viewportMode, "X", x, "Y", y, "Width", w, "Height", h)
    }
    for section, values in Map("Viewport", DHS_Viewport, "Field", DHS_Field, "Weapon", DHS_Weapon) {
        if values.Count {
            text .= "`n[" section "]`n"
            for key, value in values
                text .= key "=" value "`n"
        }
    }
    try {
        try FileDelete(temp)
        FileAppend(text, temp, "UTF-16")
        FileMove(temp, DHS_StatusPath, 1)
        return true
    } catch {
        try FileDelete(temp)
        return false
    }
}

WorkerSignalViewport(mode, x, y, w, h, detail := "") {
    return WorkerSignalStatus("ready", detail, mode, x, y, w, h)
}

WorkerSignalField(centerX, centerY, radiusX, radiusY, color := -1, secondary := -1, tolerance := 0, origin := "camera", shape := "rectangle",
    tertiary := -1, secondaryTolerance := -1, tertiaryTolerance := -1) {
    global DHS_Field, DHS_LastFieldWrite, DHS_FieldPending
    sameShape := DHS_Field.Count && DHS_Field["RadiusX"] = radiusX && DHS_Field["RadiusY"] = radiusY
        && DHS_Field["Color"] = color && DHS_Field["Secondary"] = secondary
        && DHS_Field["Tolerance"] = tolerance && DHS_Field["Origin"] = origin && DHS_Field["Shape"] = shape
        && DHS_Field["Tertiary"] = tertiary && DHS_Field["SecondaryTolerance"] = secondaryTolerance
        && DHS_Field["TertiaryTolerance"] = tertiaryTolerance
    if sameShape && DHS_Field["CenterX"] = centerX && DHS_Field["CenterY"] = centerY && !DHS_FieldPending
        return
    DHS_Field := Map("CenterX", centerX, "CenterY", centerY, "RadiusX", radiusX, "RadiusY", radiusY,
        "Color", color, "Secondary", secondary, "Tolerance", tolerance, "Origin", origin, "Shape", shape,
        "Tertiary", tertiary, "SecondaryTolerance", secondaryTolerance, "TertiaryTolerance", tertiaryTolerance)
    DHS_FieldPending := true
    now := DllCall("kernel32\GetTickCount64", "UInt64")
    if sameShape && now-DHS_LastFieldWrite < 100
        return
    if WorkerSignalStatus("ready", "viewport active") {
        DHS_LastFieldWrite := now
        DHS_FieldPending := false
    }
}

WorkerSignalWeapon(allowed, name, hwnd, updated, color1 := -1, color2 := -1, tolerance := 0, state := "ready", detail := "") {
    global DHS_Weapon
    DHS_Weapon := Map("Allowed", allowed ? 1 : 0, "Name", name, "Hwnd", hwnd, "Updated", updated,
        "Color1", color1, "Color2", color2, "Tolerance", tolerance)
    WorkerSignalStatus(state, detail != "" ? detail : "weapon: " name (allowed ? " (allowed)" : " (blocked)"))
}

WorkerSignalIssue(state, detail := "") {
    global DHS_LastIssueTick
    now := A_TickCount
    if DHS_LastIssueTick && now - DHS_LastIssueTick < 750
        return
    DHS_LastIssueTick := now
    WorkerSignalStatus(state, detail)
}

WorkerRuntimeExit(*) {
    global DHS_ReadyPath, DHS_StatusPath
    WorkerReleaseInputs()
    try FileDelete(DHS_ReadyPath)
    try FileDelete(DHS_StatusPath)
}

SanitizeWorkerStatus(value) {
    value := StrReplace(value, "`r", " ")
    value := StrReplace(value, "`n", " ")
    return SubStr(value, 1, 240)
}
