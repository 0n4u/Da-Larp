#Requires AutoHotkey v2.0.18+
#SingleInstance Off
#NoTrayIcon
#Warn All, StdOut
#Include %A_ScriptDir%\..\lib\ConfigStore.ahk
#Include %A_ScriptDir%\..\lib\SettingsSchema.ahk

RegressionAssert(condition, message) {
    if !condition
        throw Error(message)
}

RegressionReject(path) {
    rejected := false
    try SettingsSchema.ValidateFile(path)
    catch
        rejected := true
    return rejected
}

RegressionFail(*) {
    throw Error("Simulated activation failure")
}

RegressionNoOp(*) {
    return true
}

regressionRoot := A_ScriptDir "\.."
regressionExample := regressionRoot "\config\settings.example.ini"
regressionConfigDir := regressionRoot "\config"
RegressionAssert(FileExist(regressionExample), "Factory INI is missing")
RegressionAssert(SettingsSchema.ValidateFile(regressionExample), "Factory schema is invalid")
regressionCount := 0
Loop Files, regressionConfigDir "\*.ini", "F" {
    if StrLower(A_LoopFileName) = "settings.ini" || StrLower(A_LoopFileName) = "settings.example.ini"
        continue
    RegressionAssert(SettingsSchema.ValidateFile(A_LoopFileFullPath), "Invalid preset schema: " A_LoopFileName)
    for module in ["Aimlock", "Camlock", "Triggerbot"] {
        active := IniRead(A_LoopFileFullPath, "Modules", module, "0") = "1"
        if active
            RegressionAssert(IniRead(A_LoopFileFullPath, module, "Hotkey", "") != "", "Active target module missing activation key: " A_LoopFileName)
    }
    regressionCount++
}
RegressionAssert(regressionCount >= 20, "The Da Hood config library is incomplete")
RegressionAssert(IniRead(regressionExample, "App", "AutoLoadConfig", "invalid") = "0", "Fresh install auto-load must be off")
for module in ["Movement", "GunSpam", "Emote", "SOCD", "Triggerbot", "Camlock", "Aimlock", "WallHop", "KeyRepeat", "Recoil", "FOV", "CameraTurn", "WeaponDetection"]
    RegressionAssert(IniRead(regressionExample, "Modules", module, "invalid") = "0", "Factory module must be disabled: " module)

regressionWorkspace := A_Temp "\DaLarp-regression-" DllCall("GetCurrentProcessId", "UInt") "-" A_TickCount
DirCreate(regressionWorkspace)
regressionTarget := regressionWorkspace "\active.ini"
regressionSource := regressionWorkspace "\regressionSource.ini"
try {
    FileCopy(regressionExample, regressionTarget)
    FileCopy(regressionExample, regressionSource)
    ConfigStore.Apply(regressionTarget, (stage) => IniWrite("Regression Test", stage, "General", "Profile"),
        (stage) => SettingsSchema.ValidateFile(stage), RegressionNoOp, RegressionNoOp)
    RegressionAssert(IniRead(regressionTarget, "General", "Profile", "") = "Regression Test", "Transaction commit failed")
    regressionActivationFailed := false
    try ConfigStore.Apply(regressionTarget, (stage) => IniWrite("Unwanted Change", stage, "General", "Profile"),
        (stage) => SettingsSchema.ValidateFile(stage), RegressionNoOp, RegressionFail)
    catch
        regressionActivationFailed := true
    RegressionAssert(regressionActivationFailed, "Activation failure must abort a transaction")
    RegressionAssert(IniRead(regressionTarget, "General", "Profile", "") = "Regression Test", "Transaction rollback failed")
    regressionValidationFailed := false
    try ConfigStore.Apply(regressionTarget, (stage) => IniWrite("3", stage, "Modules", "Camlock"),
        (stage) => SettingsSchema.ValidateFile(stage))
    catch
        regressionValidationFailed := true
    RegressionAssert(regressionValidationFailed, "Schema validation did not block an invalid config")
    RegressionAssert(IniRead(regressionTarget, "Modules", "Camlock", "invalid") = "0", "Invalid transaction changed saved settings")
    ConfigStore.MergeSections(regressionTarget, regressionSource, regressionExample, ["Aimlock"])
    RegressionAssert(IniRead(regressionTarget, "Aimlock", "TargetColor", "invalid") = "0x000000", "Merge corrupted primary color")
    IniWrite("not-a-color", regressionTarget, "Aimlock", "TargetColor")
    RegressionAssert(RegressionReject(regressionTarget), "Invalid target color was accepted")
    IniWrite("0x000000", regressionTarget, "Aimlock", "TargetColor")
    IniWrite("-1", regressionTarget, "Aimlock", "Tolerance")
    RegressionAssert(RegressionReject(regressionTarget), "Invalid targeting tolerance was accepted")
    FileAppend("PASS: v14 config schema, presets, safe default, commit, rollback, invalid writes and merge (" regressionCount " presets)`n", "*")
} finally {
    try DirDelete(regressionWorkspace, true)
}
ExitApp(0)
