#Requires AutoHotkey v2.0.18+
#SingleInstance Force
Persistent
#Include lib\ConfigStore.ahk
#Include lib\SettingsSchema.ahk
#Include lib\ControllerConfig.ahk
#Include lib\Presets.ahk
#Include lib\ConfigLibrary.ahk
#Include lib\AdvancedDialogs.ahk
#Include lib\IvoryUI.ahk
#Include lib\IvoryPages.ahk
#Include lib\IvoryShell.ahk
#Include lib\IvoryKeybind.ahk
#Include lib\IvoryAppBar.ahk
#Include lib\IvoryKeyRegistry.ahk
#Include lib\CapturePolicy.ahk
#Include lib\IvoryRuntime.ahk
#Include lib\UserProfile.ahk
#Include lib\IvoryProfile.ahk

SetWinDelay(-1)
ProcessSetPriority("Normal")
ListLines(false)
KeyHistory(0)
DetectHiddenWindows(true)

APP_NAME := "Da Larp"
APP_VERSION := "13.6"
A_IconTip := APP_NAME
BASE_DIR := A_ScriptDir
CONFIG_DIR := BASE_DIR "\config"
CONFIG_PATH := CONFIG_DIR "\settings.ini"
EXAMPLE_PATH := CONFIG_DIR "\settings.example.ini"
WORKER_DIR := BASE_DIR "\workers"
PROFILE_DIR := BASE_DIR "\profiles"
BACKUP_DIR := BASE_DIR "\backups"
LOG_DIR := BASE_DIR "\logs"
LOG_PATH := LOG_DIR "\suite.log"
STATE_DIR := BASE_DIR "\state"
CUSTOM_PRESET_DIR := BASE_DIR "\presets\modules"
SUPPORT_DIR := BASE_DIR "\support"
LAST_GOOD_PATH := BACKUP_DIR "\last-known-good.ini"
ROBLOX_WINDOW := "ahk_exe RobloxPlayerBeta.exe"

COLORS := Map(
    "Bg", "1E1E1E",
    "Header", "1E1E1E",
    "Panel", "141414",
    "Panel2", "141414",
    "Row", "141414",
    "RowHover", "1D1D21",
    "Line", "323232",
    "Text", "FFFFFF",
    "Muted", "A6A6AA",
    "Dim", "737378",
    "Accent", "FFFFFF",
    "Accent2", "AAAAAA",
    "Green", "8FD7AE",
    "Yellow", "DCC37B",
    "Red", "E98995"
)

WORKERS := Map(
    "Movement", Map("file", "movement.ahk", "pid", 0),
    "GunSpam", Map("file", "gunspam.ahk", "pid", 0),
    "Emote", Map("file", "emote.ahk", "pid", 0),
    "SOCD", Map("file", "socd.ahk", "pid", 0),
    "Triggerbot", Map("file", "triggerbot.ahk", "pid", 0),
    "Camlock", Map("file", "camlock.ahk", "pid", 0),
    "Aimlock", Map("file", "aimlock.ahk", "pid", 0),
    "WallHop", Map("file", "wallhop.ahk", "pid", 0),
    "KeyRepeat", Map("file", "keyrepeat.ahk", "pid", 0),
    "Recoil", Map("file", "recoil.ahk", "pid", 0),
    "FOV", Map("file", "fov.ahk", "pid", 0),
    "CameraTurn", Map("file", "cameraturn.ahk", "pid", 0),
    "WeaponDetection", Map("file", "weapondetection.ahk", "pid", 0)
)

MODULE_TO_PAGE := Map(
    "Movement", "macro",
    "GunSpam", "gun",
    "Emote", "emote",
    "SOCD", "socd",
    "Triggerbot", "trigger",
    "Camlock", "camlock",
    "Aimlock", "aimlock", "WallHop", "extras", "KeyRepeat", "extras", "Recoil", "extras", "FOV", "visuals", "CameraTurn", "turns", "WeaponDetection", "weapons"
)

SECTION_TO_MODULE := Map(
    "Movement", "Movement",
    "GunSpam", "GunSpam",
    "Emote", "Emote",
    "SOCD", "SOCD",
    "Triggerbot", "Triggerbot",
    "Camlock", "Camlock",
    "Aimlock", "Aimlock", "WallHop", "WallHop", "KeyRepeat", "KeyRepeat", "Recoil", "Recoil", "FOV", "FOV", "CameraTurn", "CameraTurn", "WeaponDetection", "WeaponDetection"
)

MainGui := 0
ACTIVE_PAGE := "macro"
PAGE_CONTROLS := Map()
NAV_CONTROLS := Map()
NAV_UNDERLINES := Map()
VALUE_CONTROLS := Map()
MODULE_PILLS := Map()
PRESET_LABELS := Map()
ConfigCatalog := []
ConfigDropdown := 0
ConfigDescription := 0
ConfigCount := 0
ConfigSelection := 0
ConfigMenu := 0
ConfigStartupLabel := 0
UI := Map()
Exiting := false
Maintenance := false
RecoveryBlocked := false
PENDING_CONFIG := Map()
PENDING_RESTARTS := Map()
UNDO_STACK := []
ADVANCED_CONTROLS := Map()
DIRTY_LABELS := Map()
PREVIEW_CONTROLS := Map()
SESSION_BACKUP := ""
SESSION_MODE_ACTIVE := false
LAST_GOOD_CLEAN_TICKS := 0

EnsureLayout()
EnsureConfig()
ApplyStartupConfig()
IniWrite(0, CONFIG_PATH, "App", "TypingMode")
SyncTypingFlag()
OnExit(ControllerExit)
BackupConfig("startup")
if CfgBool("App", "SessionMode", false) {
    SESSION_BACKUP := BackupConfig("session-start")
    if SESSION_BACKUP = ""
        IniWrite(0, CONFIG_PATH, "App", "SessionMode")
}
BuildGui()
IvorySetTheme(Cfg("App", "InterfaceTheme", "Ivory"))
IvoryEnsureProfile()
RegisterTypingHotkey()
SetTimer(IvoryCaptureTick, 250)
BuildTray()
ReleaseStrayInputs()
ReconcileAllWorkers()
SetTimer(StatusTick, 1000)
SetTimer(RecoveryTick, 2000)
ShowInitialGui()

#HotIf !IvoryKeyCaptureActive()
F10::ToggleGui()
#HotIf
^+F12::PanicStop()

EnsureLayout() {
    global CONFIG_DIR, PROFILE_DIR, BACKUP_DIR, LOG_DIR, STATE_DIR, CUSTOM_PRESET_DIR, SUPPORT_DIR
    for dir in [CONFIG_DIR, PROFILE_DIR, BACKUP_DIR, LOG_DIR, STATE_DIR, CUSTOM_PRESET_DIR, SUPPORT_DIR] {
        if !DirExist(dir)
            DirCreate(dir)
    }
}

EnsureConfig() {
    global CONFIG_PATH, EXAMPLE_PATH, APP_VERSION
    if !FileExist(EXAMPLE_PATH)
        throw Error("Missing settings.example.ini")

    oldSchema := ""
    if !FileExist(CONFIG_PATH)
        FileCopy(EXAMPLE_PATH, CONFIG_PATH, true)
    ConvertLegacyIniEncoding(CONFIG_PATH)

    oldSchema := IniRead(CONFIG_PATH, "Meta", "SchemaVersion", "")
    if oldSchema != "17"
        BackupConfig("pre-migration-v" (oldSchema = "" ? "unknown" : oldSchema))

    RepairMissingConfigKeys()
    schemaNum := IsNumber(oldSchema) ? oldSchema + 0 : 0
    if schemaNum < 10
        MigrateV10(oldSchema)
    if schemaNum < 11
        MigrateV11(oldSchema)
    if schemaNum < 12
        MigrateV12(oldSchema)
    if schemaNum < 13
        MigrateV13(oldSchema)
    if schemaNum < 14
        MigrateV14(oldSchema)
    if schemaNum < 15
        MigrateV15(oldSchema)

    if schemaNum < 16
        MigrateV16(oldSchema)

    EnforceTargetingExclusivity()
    RepairTargetHotkeyCollisions()
    IniWrite(17, CONFIG_PATH, "Meta", "SchemaVersion")
    IniWrite(APP_VERSION, CONFIG_PATH, "Meta", "AppVersion")
    SyncTypingFlag()
    NormalizeInitialTargetColors()
}

WriteBlackTargetColors(path) {
    for section in ["Aimlock", "Camlock", "Triggerbot"] {
        IniWrite("0x000000", path, section, "TargetColor")
        IniWrite("", path, section, "SecondaryColor")
        IniWrite("", path, section, "TertiaryColor")
    }
}

NormalizeConvertedTargetProfile(path, source := "") {
    WriteBlackTargetColors(path)
    primary := IniRead(source != "" ? source : path, "Meta", "PrimaryModule", "")
    if !InStr("|Aimlock|Camlock|Triggerbot|", "|" primary "|")
        primary := IniRead(path, "Modules", "Aimlock", 0) = 1 ? "Aimlock"
            : IniRead(path, "Modules", "Camlock", 0) = 1 ? "Camlock" : "Triggerbot"
    for section in ["Aimlock", "Camlock", "Triggerbot"] {
        enabled := section = primary
        IniWrite(enabled ? 1 : 0, path, "Modules", section)
        IniWrite(enabled ? "RButton" : "", path, section, "Hotkey")
        IniWrite("hold", path, section, "Mode")
    }
    IniWrite("1", path, "Modules", "FOV")
    IniWrite("0xFFFFFF", path, "FOV", "Color")
    IniWrite("255", path, "FOV", "Opacity")
    IniWrite("1", path, "FOV", "Thickness")
    if IniRead(path,"FOV","Shape","") = ""
        IniWrite("circle", path, "FOV", "Shape")
    IniWrite("camera", path, "FOV", "Origin")
    IniWrite("auto", path, "FOV", "Source")
}

NormalizeInitialTargetColors() {
    global CONFIG_PATH
    if IniRead(CONFIG_PATH, "Meta", "BlackTargetColorsV1341", "0") = "1"
        return
    WriteBlackTargetColors(CONFIG_PATH)
    IniWrite(1, CONFIG_PATH, "Meta", "BlackTargetColorsV1341")
}

ConvertLegacyIniEncoding(path) {
    if !FileExist(path)
        return false
    bytes := FileRead(path, "RAW")
    if bytes.Size < 3 || NumGet(bytes, 0, "UChar") != 0xEF
        || NumGet(bytes, 1, "UChar") != 0xBB || NumGet(bytes, 2, "UChar") != 0xBF
        return false
    temporary := path ".unicode-" A_TickCount ".tmp"
    try {
        text := FileRead(path, "UTF-8")
        if SubStr(text, 1, 1) = Chr(0xFEFF)
            text := SubStr(text, 2)
        FileAppend(text, temporary, "UTF-16")
        backup := path ".legacy-utf8.bak"
        if !FileExist(backup)
            FileCopy(path, backup)
        FileMove(temporary, path, true)
        return true
    } finally {
        try FileDelete(temporary)
    }
}

RepairMissingConfigKeys() {
    global CONFIG_PATH, EXAMPLE_PATH
    sentinel := "__DHS_MISSING_94__"
    sectionsText := IniRead(EXAMPLE_PATH,,, "")
    for section in StrSplit(sectionsText, "`n", "`r") {
        section := Trim(section)
        if section = ""
            continue
        pairs := IniRead(EXAMPLE_PATH, section,, "")
        for line in StrSplit(pairs, "`n", "`r") {
            splitAt := InStr(line, "=")
            if splitAt <= 1
                continue
            key := Trim(SubStr(line, 1, splitAt - 1))
            value := SubStr(line, splitAt + 1)
            if IniRead(CONFIG_PATH, section, key, sentinel) = sentinel
                IniWrite(value, CONFIG_PATH, section, key)
        }
    }
}

MigrateV15(oldSchema) {
    global CONFIG_PATH

    for section in ["WallHop", "KeyRepeat"] {
        current := Cfg(section, "Hotkey", "")
        if GlobalHotkeyConflict(section, "Hotkey", current) = ""
            continue
        for candidate in ["F6", "F7", "F8", "F9", "F11", "F12", "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24"] {
            if GlobalHotkeyConflict(section, "Hotkey", candidate) = "" {
                IniWrite(candidate, CONFIG_PATH, section, "Hotkey")
                break
            }
        }
    }
}

MigrateV10(oldSchema) {
    global CONFIG_PATH

    if IniRead(CONFIG_PATH, "App", "LastPage", "") = "move"
        IniWrite("macro", CONFIG_PATH, "App", "LastPage")

    oldCamFactory := (
        IniRead(CONFIG_PATH, "Camlock", "FovX", "") = "200"
        && IniRead(CONFIG_PATH, "Camlock", "FovY", "") = "200"
        && IniRead(CONFIG_PATH, "Camlock", "StrengthX", "") = "0.18"
        && IniRead(CONFIG_PATH, "Camlock", "StrengthY", "") = "0.18"
    )
    if oldCamFactory {
        WritePairs("Camlock", Map(
            "Preset", "Balanced", "ScaleMode", "auto", "FovMode", "pixels", "FovX", 110, "FovY", 85,
            "Tolerance", 10, "ScanMs", 4, "StrengthX", 0.20, "StrengthY", 0.20,
            "ResponseCurve", "smooth", "PredictionEnabled", 0, "LeadMsX", 14,
            "LeadMsY", 10, "VelocityBlend", 0.45, "MaxLeadPx", 18, "MaxStep", 36,
            "Deadzone", 1, "LockRadius", 42, "LockHoldMs", 70))
    }

    oldAimFactory := (
        IniRead(CONFIG_PATH, "Aimlock", "FovX", "") = "90"
        && IniRead(CONFIG_PATH, "Aimlock", "FovY", "") = "90"
        && IniRead(CONFIG_PATH, "Aimlock", "StrengthX", "") = "0.58"
        && IniRead(CONFIG_PATH, "Aimlock", "StrengthY", "") = "0.58"
    )
    if oldAimFactory {
        WritePairs("Aimlock", Map(
            "Preset", "Balanced", "ScaleMode", "auto", "FovMode", "pixels", "FovX", 70, "FovY", 55,
            "Tolerance", 10, "ScanMs", 3, "StrengthX", 0.46, "StrengthY", 0.44,
            "ResponseCurve", "linear", "PredictionEnabled", 0, "LeadMsX", 8,
            "LeadMsY", 6, "VelocityBlend", 0.55, "MaxLeadPx", 14, "MaxStep", 72,
            "Deadzone", 0.5, "LockRadius", 28, "LockHoldMs", 45))
    }

    oldTriggerFactory := (
        IniRead(CONFIG_PATH, "Triggerbot", "FovX", "") = "4"
        && IniRead(CONFIG_PATH, "Triggerbot", "FovY", "") = "4"
        && IniRead(CONFIG_PATH, "Triggerbot", "Tolerance", "") = "40"
        && IniRead(CONFIG_PATH, "Triggerbot", "ScanMs", "") = "10"
    )
    if oldTriggerFactory {
        WritePairs("Triggerbot", Map(
            "Preset", "Balanced", "ScaleMode", "auto", "FovX", 3, "FovY", 3, "Tolerance", 32,
            "ScanMs", 3, "FireMode", "edge", "ConfirmScans", 2, "RearmMs", 18,
            "PostFireMs", 1, "ClickHoldMs", 8, "CooldownMs", 30))
    }

    for section in ["Camlock", "Aimlock"] {
        for key in ["PredictionX", "PredictionY"] {
            try {
                IniDelete(CONFIG_PATH, section, key)
            } catch {
            }
        }
    }
    try {
        IniDelete(CONFIG_PATH, "Triggerbot", "DelayMs")
    } catch {
    }
}

MigrateV11(oldSchema) {
    global CONFIG_PATH

    for section in ["Triggerbot", "Camlock", "Aimlock"] {
        if IniRead(CONFIG_PATH, section, "ScaleMode", "") = ""
            IniWrite("auto", CONFIG_PATH, section, "ScaleMode")
        if IniRead(CONFIG_PATH, section, "ReferenceWidth", "") = ""
            IniWrite(1920, CONFIG_PATH, section, "ReferenceWidth")
        if IniRead(CONFIG_PATH, section, "ReferenceHeight", "") = ""
            IniWrite(1080, CONFIG_PATH, section, "ReferenceHeight")
    }
}

MigrateV12(oldSchema) {
    global CONFIG_PATH

    for section in ["Camlock", "Aimlock"] {
        if IniRead(CONFIG_PATH, section, "ResponseMs", "") = ""
            IniWrite(4, CONFIG_PATH, section, "ResponseMs")
    }
    if IniRead(CONFIG_PATH, "Triggerbot", "ConfirmMs", "") = ""
        IniWrite(12, CONFIG_PATH, "Triggerbot", "ConfirmMs")

    camFactory := (
        StrLower(IniRead(CONFIG_PATH, "Camlock", "Preset", "")) = "balanced"
        && IniRead(CONFIG_PATH, "Camlock", "FovX", "") = "110"
        && IniRead(CONFIG_PATH, "Camlock", "FovY", "") = "85"
    )
    aimFactory := (
        StrLower(IniRead(CONFIG_PATH, "Aimlock", "Preset", "")) = "balanced"
        && IniRead(CONFIG_PATH, "Aimlock", "FovX", "") = "70"
        && IniRead(CONFIG_PATH, "Aimlock", "FovY", "") = "55"
    )
    if camFactory
        IniWrite(0, CONFIG_PATH, "Camlock", "PredictionEnabled")
    if aimFactory
        IniWrite(0, CONFIG_PATH, "Aimlock", "PredictionEnabled")
}

MigrateV13(oldSchema) {
    global CONFIG_PATH
    defaults := Map(
        "AdvancedUI", 0, "DeferRestarts", 1, "SessionMode", 0,
        "AutoLastKnownGood", 1, "UiScale", 100, "Density", "compact",
        "AccentTheme", "matcha", "InstallMode", "portable", "RecentColors", ""
    )
    for key, value in defaults {
        if IniRead(CONFIG_PATH, "App", key, "__missing__") = "__missing__"
            IniWrite(value, CONFIG_PATH, "App", key)
    }
    for section in ["Triggerbot", "Camlock", "Aimlock"] {
        if IniRead(CONFIG_PATH, section, "AspectPreset", "") = ""
            IniWrite("auto", CONFIG_PATH, section, "AspectPreset")
    }
}

MigrateV14(oldSchema) {
    global CONFIG_PATH
    profile := IniRead(CONFIG_PATH, "General", "Profile", "")
    if profile = "Stable"
        IniWrite("Legit", CONFIG_PATH, "General", "Profile")
    else if profile = "Balanced"
        IniWrite("Semi Rage", CONFIG_PATH, "General", "Profile")
    else if profile = "Responsive"
        IniWrite("Rage", CONFIG_PATH, "General", "Profile")

    NormalizePresetLabel("Movement", Map("Reliable", "Legit", "Balanced", "Semi Rage", "Quick", "Rage"))
    NormalizePresetLabel("GunSpam", Map("Reliable", "Legit", "Balanced", "Semi Rage", "Rapid", "Rage"))
    NormalizePresetLabel("Emote", Map("Reliable", "Legit", "Balanced", "Semi Rage", "Quick", "Rage"))
    NormalizePresetLabel("SOCD", Map("WASD Neutral", "Legit", "WASD Last", "Semi Rage"))
    NormalizePresetLabel("Triggerbot", Map("Precision", "Legit", "Balanced", "Semi Rage", "Rapid", "Rage", "Legacy", "Rage"))
    NormalizePresetLabel("Camlock", Map("Smooth", "Legit", "Balanced", "Semi Rage", "Responsive", "Semi Rage", "Kairu Legacy", "Semi Rage"))
    NormalizePresetLabel("Aimlock", Map("Precision", "Legit", "Balanced", "Semi Rage", "Aggressive", "Rage"))
}

NormalizePresetLabel(section, aliases) {
    global CONFIG_PATH
    current := IniRead(CONFIG_PATH, section, "Preset", "")
    if aliases.Has(current)
        IniWrite(aliases[current], CONFIG_PATH, section, "Preset")
}

EnforceTargetingExclusivity() {
    global CONFIG_PATH
    if !CfgBool("Modules", "Camlock", false) || !CfgBool("Modules", "Aimlock", false)
        return

    lastPage := StrLower(Cfg("App", "LastPage", "camlock"))
    if lastPage = "aimlock" {
        IniWrite(0, CONFIG_PATH, "Modules", "Camlock")
        Log("targeting conflict repaired: kept Aimlock, disabled Camlock")
    } else {
        IniWrite(0, CONFIG_PATH, "Modules", "Aimlock")
        Log("targeting conflict repaired: kept Camlock, disabled Aimlock")
    }
}

RepairTargetHotkeyCollisions() {
    global CONFIG_PATH
    for section in ["Aimlock", "Camlock", "Triggerbot"] {
        if CfgBool("Modules", section, false)
            continue
        key := Trim(IniRead(CONFIG_PATH, section, "Hotkey", ""))
        if IvoryKeyIdentity(key) = "rbutton" {
            for other in ["Aimlock", "Camlock", "Triggerbot"] {
                if other != section && CfgBool("Modules", other, false)
                    && IvoryKeyIdentity(Cfg(other, "Hotkey", "")) = "rbutton" {
                    IniWrite("", CONFIG_PATH, section, "Hotkey")
                    break
                }
            }
        }
    }
}

HotkeyBindingActive(section) {
    return section = "App" || CfgBool("Modules", section, false)
}

Cfg(section, key, fallback := "") {
    global CONFIG_PATH
    return IniRead(CONFIG_PATH, section, key, fallback)
}

CfgBool(section, key, fallback := false) {
    value := StrLower(Trim(Cfg(section, key, fallback ? "1" : "0")))
    return value = "1" || value = "true" || value = "yes" || value = "on"
}

CfgInt(section, key, fallback, minV, maxV) {
    value := Cfg(section, key, fallback)
    if !IsNumber(value)
        return fallback
    return Min(maxV, Max(minV, Round(value + 0)))
}

CfgFloat(section, key, fallback, minV, maxV) {
    value := Cfg(section, key, fallback)
    if !IsNumber(value)
        return fallback
    return Min(maxV, Max(minV, value + 0.0))
}

SampleTargetColor(section, key, *) {
    if !RegExMatch(section, "i)^(Aimlock|Camlock|Triggerbot)$")
        return
    if key != "TargetColor" && key != "SecondaryColor" && key != "TertiaryColor"
        return
    SetStatus("place cursor on target color; sampling in 3 seconds", "normal")
    SetTimer((*) => FinishTargetColorSample(section, key), -3000)
}

FinishTargetColorSample(section, key) {
    global ROBLOX_WINDOW
    if !WinActive(ROBLOX_WINDOW) {
        SetStatus("color sample canceled: Roblox must be active", "normal")
        return
    }
    try {
        CoordMode("Mouse", "Screen")
        CoordMode("Pixel", "Screen")
        MouseGetPos(&px, &py)
        value := Format("0x{:06X}", PixelGetColor(px, py, "RGB") & 0xFFFFFF)
        if SetCfg(section, key, value)
            SetStatus(StrLower(section) " " StrLower(key) " sampled: " value, "ok")
    } catch as caught {
        Log("color sampling failed: " caught.Message)
        SetStatus("couldn't read color at cursor", "error")
    }
}


BackupConfig(reason := "manual") {
    global CONFIG_PATH, BACKUP_DIR
    if !FileExist(CONFIG_PATH)
        return ""
    stamp := FormatTime(, "yyyyMMdd-HHmmss") "-" A_TickCount "-" Random(1000,9999)
    path := BACKUP_DIR "\settings-" stamp "-" SanitizeFilename(reason) ".ini"
    try {
        FileCopy(CONFIG_PATH, path, true)
        PruneConfigBackups()
    } catch {
        return ""
    }
    return path
}

PruneConfigBackups() {
    global BACKUP_DIR
    limit := CfgInt("App", "HistoryLimit", 20, 3, 200)
    items := []
    Loop Files BACKUP_DIR "\settings-*.ini", "F" {
        if IsProtectedBackup(A_LoopFileFullPath)
            continue
        items.Push(Map("path", A_LoopFileFullPath, "time", FileGetTime(A_LoopFileFullPath, "M")))
    }
    while items.Length > limit {
        oldest := 1
        Loop items.Length {
            if items[A_Index]["time"] < items[oldest]["time"]
                oldest := A_Index
        }
        try {
            FileDelete(items[oldest]["path"])
        } catch {
            break
        }
        items.RemoveAt(oldest)
    }
}

SanitizeFilename(name) {
    name := Trim(name)
    name := RegExReplace(name, "[\\/:*?\x22<>|]", "_")
    if name = ""
        name := "profile"
    return SubStr(name, 1, 64)
}

Log(message) {
    global LOG_PATH
    try {
        FileAppend("[" FormatTime(, "yyyy-MM-dd HH:mm:ss") "] " message "`n", LOG_PATH, "UTF-8")
    } catch {
    }
}

ModuleEnabled(module) {
    return CfgBool("Modules", module, false)
}

MasterEnabled() {
    return UserProfile.Ready && CfgBool("General", "Master", false)
}

WorkerSignalPath(module, kind := "ready") {
    global STATE_DIR
    return STATE_DIR "\" StrLower(module) "." kind
}

ClearWorkerSignals(module) {
    for kind in ["ready", "status.ini"] {
        path := WorkerSignalPath(module, kind)
        try FileDelete(path)
    }
}

ReadWorkerStatus(module) {
    path := WorkerSignalPath(module, "status.ini")
    if !FileExist(path)
        return Map("state", "", "detail", "", "mode", "", "width", 0, "height", 0)
    return Map(
        "state", IniRead(path, "Worker", "State", ""),
        "detail", IniRead(path, "Worker", "Detail", ""),
        "mode", IniRead(path, "Viewport", "Mode", ""),
        "width", IniRead(path, "Viewport", "Width", 0) + 0,
        "height", IniRead(path, "Viewport", "Height", 0) + 0
    )
}

WaitWorkerReady(module, pid, timeoutMs := 1800) {
    path := WorkerSignalPath(module, "ready")
    deadline := A_TickCount + timeoutMs
    while A_TickCount < deadline {
        if !ProcessExist(pid)
            return false
        if FileExist(path) {
            text := ""
            try text := FileRead(path, "UTF-8")
            if InStr(text, "state=ready")
                return true
        }
        Sleep(25)
    }
    return false
}

WorkerRunning(module) {
    global WORKERS, Exiting
    if !WORKERS.Has(module)
        return false
    worker := WORKERS[module]
    pid := worker["pid"]
    if !pid
        return false
    if ProcessExist(pid) {
        started := worker.Has("lastStart") ? worker["lastStart"] : 0
        if started && A_TickCount - started >= 15000 {
            worker["crashCount"] := 0
            worker["crashWindowStart"] := 0
        }
        return true
    }
    worker["pid"] := 0
    worker["state"] := "error"
    if !Exiting {
        try Log("unexpected worker exit: " module " / PID " pid)
        RecordWorkerFailure(module)
        try PublishGuardianRoster()
        if !CfgBool("App", "AutoRecover", true)
            ExitApp(1)
    }
    return false
}

RecordWorkerFailure(module) {
    global WORKERS
    worker := WORKERS[module]
    now := A_TickCount
    windowStart := worker.Has("crashWindowStart") ? worker["crashWindowStart"] : 0
    if !windowStart || now - windowStart > 15000 {
        worker["crashWindowStart"] := now
        worker["crashCount"] := 1
    } else {
        worker["crashCount"] := (worker.Has("crashCount") ? worker["crashCount"] : 0) + 1
    }
    return worker["crashCount"]
}

ResetWorkerFailures(module) {
    global WORKERS
    if !WORKERS.Has(module)
        return
    WORKERS[module]["crashCount"] := 0
    WORKERS[module]["crashWindowStart"] := 0
}

GuardianRosterPath() {
    global STATE_DIR
    ready := STATE_DIR "\guardian.ready"
    if !FileExist(ready)
        return ""
    try {
        guardianPid := Integer(IniRead(ready, "Guardian", "Pid", "0"))
        if guardianPid && ProcessExist(guardianPid)
            return STATE_DIR "\guardian." guardianPid ".roster"
    }
    return ""
}

PublishGuardianRoster() {
    global WORKERS
    path := GuardianRosterPath()
    if path = ""
        return
    text := "controller=" DllCall("kernel32\GetCurrentProcessId", "UInt") "`n"
    text .= "recover=" (CfgBool("App", "AutoRecover", true) ? 1 : 0) "`n"
    for _, worker in WORKERS {
        if worker["pid"] > 0
            text .= "worker=" worker["pid"] "`n"
    }
    temp := path ".tmp"
    try {
        try FileDelete(temp)
        FileAppend(text, temp, "UTF-8")
        FileMove(temp, path, true)
    } finally {
        try FileDelete(temp)
    }
}

StartWorker(module, verifyStart := true, recordFailure := true) {
    global WORKERS, WORKER_DIR, BASE_DIR
    if !WORKERS.Has(module)
        return false
    if TypingInputPaused(module)
        return true
    if WorkerRunning(module)
        return true

    path := WORKER_DIR "\" WORKERS[module]["file"]
    if !FileExist(path) {
        WORKERS[module]["state"] := "error"
        WORKERS[module]["detail"] := "missing worker"
        Log("missing worker: " path)
        SetStatus("missing " module " worker", "error")
        if recordFailure
            RecordWorkerFailure(module)
        return false
    }

    ClearWorkerSignals(module)
    WORKERS[module]["state"] := "starting"
    WORKERS[module]["detail"] := ""
    UpdateModulePills()
    cmd := Quote(A_AhkPath) " " Quote(path)
    try {
        Run(cmd, BASE_DIR, "Hide", &pid)
        WORKERS[module]["pid"] := pid
        WORKERS[module]["lastStart"] := A_TickCount
        if verifyStart && !WaitWorkerReady(module, pid, 1800) {
            alive := ProcessExist(pid)
            if alive {
                try ProcessClose(pid)
                try ProcessWaitClose(pid, 0.5)
            }
            WORKERS[module]["pid"] := 0
            WORKERS[module]["state"] := "error"
            WORKERS[module]["detail"] := alive ? "initialization timeout" : "exited during initialization"
            failures := recordFailure ? RecordWorkerFailure(module) : (WORKERS[module].Has("crashCount") ? WORKERS[module]["crashCount"] : 0)
            Log("worker failed readiness handshake: " module " (failure " failures ")")
            SetStatus(module " worker didn't become ready", "error")
            return false
        }
        WORKERS[module]["state"] := "ready"
        WORKERS[module]["detail"] := ""
        PublishGuardianRoster()
        return true
    } catch as err {
        abandonedPid := WORKERS[module]["pid"]
        if abandonedPid && ProcessExist(abandonedPid)
            try ProcessClose(abandonedPid)
        WORKERS[module]["pid"] := 0
        WORKERS[module]["state"] := "error"
        WORKERS[module]["detail"] := err.Message
        failures := recordFailure ? RecordWorkerFailure(module) : (WORKERS[module].Has("crashCount") ? WORKERS[module]["crashCount"] : 0)
        Log("failed to start " module ": " err.Message " (failure " failures ")")
        SetStatus("couldn't start " module, "error")
        return false
    }
}

StopWorker(module, resetFailures := true) {
    global WORKERS
    if !WORKERS.Has(module)
        return
    pid := WORKERS[module]["pid"]
    if pid {
        WORKERS[module]["pid"] := 0
        try PublishGuardianRoster()
        catch as rosterWriteError {
            WORKERS[module]["pid"] := pid
            throw rosterWriteError
        }
    }
    if pid && ProcessExist(pid) {
        try WinClose("ahk_pid " pid)
        try ProcessWaitClose(pid, 0.4)
        if ProcessExist(pid) {
            try ProcessClose(pid)
            try ProcessWaitClose(pid, 0.4)
        }
    }
    if pid && ProcessExist(pid) {
        WORKERS[module]["pid"] := pid
        PublishGuardianRoster()
        WORKERS[module]["state"] := "error"
        WORKERS[module]["detail"] := "stop not confirmed"
        throw Error("couldn't confirm worker exit: " module)
    }
    WORKERS[module]["pid"] := 0
    WORKERS[module]["state"] := "off"
    WORKERS[module]["detail"] := ""
    ClearWorkerSignals(module)
    if resetFailures
        ResetWorkerFailures(module)
}

RestartWorker(module, guarded := false) {
    global Maintenance
    if Maintenance && !guarded {
        SetStatus("restart blocked; operation failed", "error")
        return false
    }
    try {
        StopWorker(module)
        if WorkerShouldRun(module) && !StartWorker(module)
            throw Error("worker startup failed")
        UpdateModulePills()
        return true
    } catch as err {
        Log("couldn't restart " module ": " err.Message)
        SetStatus("couldn't restart " module, "error")
        return false
    }
}

RestartIfEnabled(module, guarded := false) {
    if WorkerShouldRun(module)
        return RestartWorker(module, guarded)
    return true
}

ReconcileAllWorkers() {
    global WORKERS
    EnforceTargetingExclusivity()
    failure := false
    for module, _ in WORKERS {
        try {
            shouldRun := WorkerShouldRun(module)
            if shouldRun {
                if !StartWorker(module)
                    failure := true
            } else {
                StopWorker(module)
            }
        } catch {
            failure := true
        }
    }
    UpdateModulePills()
    if failure
        SetStatus("couldn't reconcile all workers", "error")
    return !failure
}

StopAllWorkers() {
    global WORKERS
    failure := 0
    try {
        for module, _ in WORKERS {
            try {
                StopWorker(module)
            } catch as err {
                if !failure
                    failure := err
            }
        }
    } finally {
        ReleaseStrayInputs()
    }
    if failure
        throw failure
}

StopWorkersAfterFailure(label) {
    try {
        StopAllWorkers()
        Log(label " cleanup confirmed")
    } catch as err {
        Log(label " cleanup could not be confirmed: " err.Message)
    }
}

ResetInputEngine(*) {
    global Maintenance
    if Maintenance {
        SetStatus("restart blocked; resolve the failed configuration transition first", "error")
        return
    }
    Maintenance := true
    completed := false
    try {
        StopAllWorkers()
        Sleep(120)
        ReleaseStrayInputs()
        if !ReconcileAllWorkers()
            throw Error("worker reconciliation failed")
        SetStatus("input engine restarted", "ok")
        completed := true
    } catch as err {
        try {
            StopAllWorkers()
        } catch as cleanupErr {
            Log("input engine cleanup could not be confirmed: " cleanupErr.Message)
        }
        Log("couldn't restart input engine: " err.Message)
        SetStatus("couldn't restart input engine; operation failed", "error")
    } finally {
        Maintenance := false
    }
}

ReleaseStrayInputs() {
    failure := 0
    try {
        SendEvent("{Blind}{LButton up}{RButton up}{MButton up}{Space up}{LShift up}{LCtrl up}{RCtrl up}{w up}{a up}{s up}{d up}{q up}{e up}{Left up}{Right up}{Up up}{Down up}")
    } catch as err {
        failure := err
    }
    seen := Map()
    for key in ["LButton", "RButton", "MButton", "Space", "LShift", "LCtrl", "RCtrl", "w", "a", "s", "d", "q", "e", "Left", "Right", "Up", "Down"]
        seen[Format("{:02X}:{:03X}", GetKeyVK(key), GetKeySC(key))] := true
    for binding in [["SOCD", "Left", "a"], ["SOCD", "Right", "d"], ["SOCD", "Up", "w"], ["SOCD", "Down", "s"], ["KeyRepeat", "OutputKey", "e"]] {
        try {
            key := Cfg(binding[1], binding[2], binding[3])
        } catch as err {
            if !failure
                failure := err
            continue
        }
        try {
            vk := GetKeyVK(key)
            sc := GetKeySC(key)
        } catch {
            continue
        }
        if !vk && !sc
            continue
        identity := Format("{:02X}:{:03X}", vk, sc)
        if seen.Has(identity)
            continue
        seen[identity] := true
        try {
            if !GetKeyState(key, "P")
                SendEvent("{Blind}{vk" Format("{:02X}", vk) "sc" Format("{:03X}", sc) " up}")
        } catch as err {
            if !failure
                failure := err
        }
    }
    if failure
        throw failure
}

Quote(text) {
    return Chr(34) text Chr(34)
}

ToggleModule(module, *) {
    enabled := !ModuleEnabled(module)
    SetModuleEnabled(module, enabled)
}

SetModuleEnabled(module, enabled) {
    global CONFIG_PATH, Maintenance
    if Maintenance {
        SetStatus("module change already in progress", "error")
        return false
    }
    previous := ModuleEnabled(module)
    if enabled && InStr("|Aimlock|Camlock|Triggerbot|", "|" module "|") {
        hotkeyName := Trim(Cfg(module, "Hotkey", ""))
        if hotkeyName = "" || !IsValidKeyName(hotkeyName) {
            SetStatus("assign an activation key before enabling " module, "error")
            return false
        }
        bindingConflict := ""
        for binding in IvoryHotkeyBindings() {
            if binding[1] = module || !HotkeyBindingActive(binding[1])
                continue
            if (module = "Aimlock" && binding[1] = "Camlock")
                || (module = "Camlock" && binding[1] = "Aimlock")
                continue
            if IvoryKeysOverlap(IvoryKeyIdentity(hotkeyName), IvoryKeyIdentity(Cfg(binding[1], binding[2], ""))) {
                bindingConflict := binding[3]
                break
            }
        }
        if bindingConflict != "" {
            SetStatus("hotkey conflicts with " bindingConflict, "error")
            return false
        }
    }
    conflict := module = "Camlock" ? "Aimlock" : (module = "Aimlock" ? "Camlock" : "")
    conflictPrevious := conflict != "" ? ModuleEnabled(conflict) : false
    batch := [Map("section","Modules","key",module,"value",enabled ? 1 : 0)]
    if enabled && conflict != "" && conflictPrevious
        batch.Push(Map("section","Modules","key",conflict,"value",0))
    if !ApplySettingsTransaction(batch,"module-" module)
        return false
    UpdateModulePills()
    SetStatus(module " " (enabled ? "enabled" : "disabled"),enabled ? "ok" : "normal")
    return true
}

ToggleMaster(*) {
    newState := !MasterEnabled()
    if !SetCfg("General", "Master", newState ? 1 : 0, false)
        return false
    RefreshSystemValues()
    SetStatus(newState ? "suite enabled" : "suite paused", newState ? "ok" : "normal")
    return true
}

PanicStop(*) {
    global CONFIG_PATH, Maintenance, RecoveryBlocked
    RecoveryBlocked := true
    Maintenance := true
    saved := false
    stopped := false
    try {
        try {
            IniWrite(0, CONFIG_PATH, "General", "Master")
            saved := true
        }
        try {
            StopAllWorkers()
            stopped := true
        }
    } finally {
        RecoveryBlocked := !(saved && stopped)
        Maintenance := false
    }
    RefreshSystemValues()
    UpdateModulePills()
    message := !saved ? "panic stop - couldn't save master state" : (!stopped ? "panic stop - some workers needed forced cleanup" : "panic stop - suite paused")
    SetStatus(message, saved && stopped ? "normal" : "error")
}

EditSetting(section, key, kind, minV, maxV, choices, module, ctrl, *) {
    current := Cfg(section, key, "")
    newValue := current

    if kind = "bool" {
        newValue := CfgBool(section, key, false) ? 0 : 1
    } else if kind = "choice" {
        if !IsObject(choices)
            return
        index := 0
        for i, item in choices {
            if StrLower(item) = StrLower(current) {
                index := i
                break
            }
        }
        nextIndex := index + 1
        if nextIndex > choices.Length
            nextIndex := 1
        newValue := choices[nextIndex]
    } else {
        prompt := labelForSetting(section, key)
        result := kind = "key" ? IvoryKeyPrompt(ctrl) : kind = "color" ? IvoryColorPrompt(prompt, current, key = "SecondaryColor" || key = "TertiaryColor" || key = "Color2") : IvoryPrompt(prompt, current, kind)
        if result.Result != "OK"
            return
        newValue := Trim(result.Value)

        if kind = "int" {
            if !IsNumber(newValue) {
                SetStatus("enter a number", "error")
                return
            }
            newValue := Round(newValue + 0)
            if minV != ""
                newValue := Max(minV, newValue)
            if maxV != ""
                newValue := Min(maxV, newValue)
        } else if kind = "float" {
            if !IsNumber(newValue) {
                SetStatus("enter a number", "error")
                return
            }
            newValue := newValue + 0.0
            if minV != ""
                newValue := Max(minV, newValue)
            if maxV != ""
                newValue := Min(maxV, newValue)
        } else if kind = "color" {
            if newValue != "" && !RegExMatch(newValue, "i)^0x[0-9a-f]{6}$") {
                SetStatus("couldn't set that color", "error")
                return
            }
        } else if kind = "key" {
            if newValue != "" && !IsValidKeyName(newValue) {
                SetStatus("unknown key name", "error")
                return
            }
            conflict := GlobalHotkeyConflict(section, key, newValue)
            if conflict != "" {
                SetStatus("hotkey already used by " conflict, "error")
                return
            }
        }
    }

    restart := module != ""
    if kind = "key" && key = "Hotkey" && newValue = "" && ModuleEnabled(section) {
        if !SetModuleEnabled(section, false)
            return
    }
    if SetCfg(section, key, newValue, restart) {
        if section = "App" {
            RefreshSystemValues()
            if key = "AdvancedUI"
                ApplyAdvancedVisibility()
        }
        SetStatus(labelForSetting(section, key) " updated", "ok")
    }
}

IsValidKeyName(value) {
    try {
        name := GetKeyName(value)
        return name != ""
    } catch {
        return false
    }
}

SOCDKeyConflict(changedKey, value) {
    for otherKey in ["Left", "Right", "Up", "Down"] {
        if otherKey = changedKey
            continue
        if IvoryKeysOverlap(Cfg("SOCD", otherKey, ""), value)
            return true
    }
    return false
}

GlobalHotkeyConflict(section, key, value) {
    if section = "Recoil" || (section = "KeyRepeat" && key = "OutputKey")
        return ""
    if !HotkeyBindingActive(section)
        return ""
    value := IvoryKeyIdentity(value)
    if value = ""
        return ""

    bindings := IvoryHotkeyBindings()
    for binding in bindings {
        if binding[1] = section && binding[2] = key
            continue
        if !HotkeyBindingActive(binding[1])
            continue
        other := IvoryKeyIdentity(Cfg(binding[1], binding[2], ""))
        if IvoryKeysOverlap(other, value)
            return binding[3]
    }
    return ""
}

ValidateHotkeyRegistry() {
    seen := []
    conflicts := []
    bindings := IvoryHotkeyBindings()
    for binding in bindings {
        if !HotkeyBindingActive(binding[1])
            continue
        value := IvoryKeyIdentity(Cfg(binding[1], binding[2], ""))
        if value = ""
            continue
        for previous in seen {
            if IvoryKeysOverlap(previous[1], value)
                conflicts.Push(previous[2] " / " binding[3] " = " value)
        }
        seen.Push([value, binding[3]])
    }
    return conflicts
}

labelForSetting(section, key) {
    return StrReplace(StrReplace(key, "Ms", " ms"), "X", " x")
}

DisplayValue(section, key) {
    value := Cfg(section, key, "")
    if key = "Origin" && (section = "Aimlock" || section = "Camlock" || section = "Triggerbot") && ModuleEnabled("FOV")
        return StrLower(Cfg("FOV", "Origin", "cursor")) = "cursor" ? "cursor (FOV)" : "camera (FOV)"
    if key = "AngularMotion" || key = "TargetDot" || key = "VerifyBeforeFire" || key = "CPUFriendly" || key = "CaptureExcluded" || key = "TypingMode" || key = "DpiScaling" || key = "ScaleTemplates" || key = "RequireAim" || key = "RequireStationary" || key = "TopBarReserveSpace"
        return CfgBool(section, key, false) ? "on" : "off"
    if key = "Enabled" || key = "WheelUp" || key = "WheelDown" || key = "BypassCtrl" || key = "BypassAlt" || key = "IgnoreHeldClick" || key = "PredictionEnabled" || key = "Master" || key = "StartWithWindows" || key = "TopBarEnabled" || key = "AutoRecover" || key = "RememberPosition" || key = "DeveloperMode" || key = "AdvancedUI" || key = "DeferRestarts" || key = "SessionMode" || key = "AutoLastKnownGood" || key = "AutoLoadConfig"
        return CfgBool(section, key, false) ? "on" : "off"
    if InStr(key, "Ms")
        return value " ms"
    if key = "StrengthX" || key = "StrengthY" || key = "VelocityBlend" || key = "Deadzone"
        return value
    return value = "" ? "none" : value
}

RefreshBoundValue(section, key) {
    global VALUE_CONTROLS
    mapKey := section "." key
    if VALUE_CONTROLS.Has(mapKey)
        VALUE_CONTROLS[mapKey].Text := DisplayValue(section, key)
}

RefreshAllValues() {
    global VALUE_CONTROLS
    for mapKey, ctrl in VALUE_CONTROLS {
        parts := StrSplit(mapKey, ".")
        if parts.Length >= 2
            ctrl.Text := DisplayValue(parts[1], parts[2])
        IvoryUI.Redraw(ctrl)
    }
    UpdateModulePills()
    UpdatePresetLabels()
    RefreshSystemValues()
    RefreshDebugValues()
    if IsObject(ConfigDescription)
        IvoryConfigSelectionChanged()
}

UpdateModulePills() {
    global MODULE_PILLS, COLORS, WORKERS
    for module, ctrl in MODULE_PILLS {
        enabled := ModuleEnabled(module)
        running := WorkerRunning(module)
        state := WORKERS[module].Has("state") ? WORKERS[module]["state"] : ""
        if enabled && TypingInputPaused(module) {
            ctrl.Text := "typing"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Yellow"]) + 0
            IvoryUI.Redraw(ctrl)
        } else if enabled && MasterEnabled() && running && state = "ready" {
            ctrl.Text := "ready"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Green"]) + 0
            IvoryUI.Redraw(ctrl)
        } else if enabled && MasterEnabled() && state = "error" {
            ctrl.Text := "! error"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Red"]) + 0
            IvoryUI.Redraw(ctrl)
        } else if enabled && MasterEnabled() {
            ctrl.Text := "starting"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Yellow"]) + 0
            IvoryUI.Redraw(ctrl)
        } else if enabled {
            ctrl.Text := "armed"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Yellow"]) + 0
            IvoryUI.Redraw(ctrl)
        } else {
            ctrl.Text := "disabled"
            IvoryUI.Items[ctrl.Hwnd].color := ("0x" COLORS["Muted"]) + 0
            IvoryUI.Redraw(ctrl)
        }
    }
}

UpdatePresetLabels() {
    global PRESET_LABELS
    for section, ctrl in PRESET_LABELS
        ctrl.Text := "preset · " StrLower(Cfg(section, "Preset", "custom"))
}

SetStatus(text, kind := "normal") {
    IvorySetStatus(text, kind)
}

BeginDrag(*) {
    global MainGui
    DllCall("user32\ReleaseCapture")
    DllCall("user32\SendMessageW", "Ptr", MainGui.Hwnd, "UInt", 0xA1, "Ptr", 2, "Ptr", 0)
}

HandleClose(*) {
    global MainGui
    SaveWindowPosition()
    behavior := StrLower(Cfg("App", "CloseBehavior", "tray"))
    if behavior = "exit"
        ExitApp()
    else
        IvoryHide()
}

ToggleGui(*) {
    global MainGui
    if !UserProfile.Ready || IsObject(UserProfile.Dialog) {
        if IsObject(UserProfile.Dialog)
            try WinActivate("ahk_id " UserProfile.Dialog.Hwnd)
        return
    }
    if IsGuiVisible() {
        SaveWindowPosition()
        IvoryHide()
    } else {
        IvoryShow()
        try {
            WinActivate("ahk_id " MainGui.Hwnd)
        } catch {
        }
    }
}

IsGuiVisible() {
    global MainGui
    if !IsObject(MainGui)
        return false
    try {
        return IvoryMenuVisible()
    } catch {
        return false
    }
}

ShowInitialGui() {
    global MainGui
    x := CfgInt("Window", "X", -1, -10000, 10000)
    y := CfgInt("Window", "Y", -1, -10000, 10000)
    if CfgBool("App", "RememberPosition", true) && SavedWindowVisible(x,y)
        IvoryShow("x" x " y" y)
    else {
        MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
        IvoryShow("x" left+8 " y" top+Round(32*IvoryUI.Scale))
    }
}

SaveWindowPosition() {
    global MainGui, CONFIG_PATH
    if !UserProfile.Ready || !CfgBool("App", "RememberPosition", true)
        return
    try {
        MainGui.GetPos(&x, &y)
        IniWrite(x, CONFIG_PATH, "Window", "X")
        IniWrite(y, CONFIG_PATH, "Window", "Y")
    }
}


ApplyGlobalProfileFromGui(name, *) {
    try {
        ApplyGlobalProfile(name)
        return true
    } catch as err {
        SetStatus("couldn't apply profile; operation failed", "error")
        return false
    }
}


WritePairs(section, pairs) {
    global CONFIG_PATH
    for key, value in pairs
        IniWrite(value, CONFIG_PATH, section, key)
}

GameplaySections() {
    return ["General", "Modules", "Movement", "GunSpam", "Emote", "SOCD", "Triggerbot", "Camlock", "Aimlock", "WallHop", "KeyRepeat", "Recoil", "FOV", "CameraTurn", "WeaponDetection", "Detection"]
}

WriteProfileFile(path, profileName := "profile") {
    global CONFIG_PATH, EXAMPLE_PATH, APP_VERSION
    if StrLower(path) = StrLower(CONFIG_PATH) || StrLower(path) = StrLower(EXAMPLE_PATH)
        throw Error("Profile destination cannot overwrite the live or factory config")
    if FileExist(path)
        FileDelete(path)

    IniWrite(17, path, "Meta", "SchemaVersion")
    IniWrite(APP_VERSION, path, "Meta", "AppVersion")
    IniWrite("profile", path, "Meta", "Kind")
    IniWrite(profileName, path, "General", "Profile")

    for section in GameplaySections() {
        pairs := IniRead(CONFIG_PATH, section,, "__DHS_SECTION_MISSING__")
        if pairs != "__DHS_SECTION_MISSING__" && Trim(pairs) != ""
            IniWrite(pairs, path, section)
    }
    IniWrite(profileName, path, "General", "Profile")
}

SaveProfile(*) {
    global PROFILE_DIR, CONFIG_PATH
    result := IvoryPrompt("Profile name", Cfg("General", "Profile", "custom"), "text")
    if result.Result != "OK"
        return
    name := SanitizeFilename(result.Value)
    if name = ""
        return
    path := PROFILE_DIR "\" name ".ini"
    try {
        WriteProfileFile(path, name)
        IniWrite(name, CONFIG_PATH, "General", "Profile")
        SetStatus("profile saved: " name, "ok")
    } catch as err {
        Log("profile save failed: " err.Message)
        SetStatus("couldn't save profile", "error")
    }
}

LoadProfile(*) {
    global PROFILE_DIR
    path := FileSelect(3, PROFILE_DIR, "Load Da Larp profile", "INI profiles (*.ini)")
    if path = ""
        return
    LoadConfigFile(path)
}

ImportProfile(*) {
    global PROFILE_DIR
    path := FileSelect(3, , "Import Da Larp profile", "INI profiles (*.ini)")
    if path = ""
        return
    if !ValidateProfileFile(path) {
        SetStatus("profile file isn't valid", "error")
        return
    }
    SplitPath(path, &name)
    dest := PROFILE_DIR "\" SanitizeFilename(name)
    try {
        if StrLower(path) != StrLower(dest)
            FileCopy(path, dest, true)
    } catch as err {
        Log("profile import failed: " err.Message)
        SetStatus("couldn't import profile", "error")
        return
    }
    LoadConfigFile(dest)
}

ExportProfile(*) {
    global PROFILE_DIR
    current := SanitizeFilename(Cfg("General", "Profile", "profile")) ".ini"
    path := FileSelect("S16", PROFILE_DIR "\" current, "Export Da Larp profile", "INI profiles (*.ini)")
    if path = ""
        return
    if !RegExMatch(path, "i)\.ini$")
        path .= ".ini"
    try {
        WriteProfileFile(path, SanitizeFilename(Cfg("General", "Profile", "profile")))
        SetStatus("profile exported", "ok")
    } catch as err {
        Log("profile export failed: " err.Message)
        SetStatus("couldn't export profile", "error")
    }
}


ValidateProfileFile(path) {
    global WORKERS
    if !FileExist(path) || DirExist(path)
        return false
    try {
        if IniRead(path, "Meta", "SchemaVersion", "") != "17"
            return false
        for module, _ in WORKERS {
            value := IniRead(path, "Modules", module, "__missing__")
            if value != "0" && value != "1"
                return false
        }
        if IniRead(path, "Modules", "Aimlock", "0") = "1" && IniRead(path, "Modules", "Camlock", "0") = "1"
            return false
        for section in GameplaySections() {
            if section = "Detection"
                continue
            if IniRead(path, section,, "__missing__") = "__missing__"
                return false
        }
        master := IniRead(path, "General", "Master", "invalid")
        return master = "0" || master = "1"
    } catch {
        return false
    }
}

BackupAndStatus() {
    path := BackupConfig("manual")
    SetStatus(path != "" ? "backup created" : "backup failed", path != "" ? "ok" : "error")
}


RefreshSystemValues() {
    RefreshBoundValue("General", "Master")
    RefreshBoundValue("App", "StartWithWindows")
    RefreshBoundValue("App", "TopBarEnabled")
    RefreshBoundValue("App", "TopBarReserveSpace")
    RefreshBoundValue("App", "AutoRecover")
    RefreshBoundValue("App", "RememberPosition")
    RefreshBoundValue("App", "CloseBehavior")
    RefreshBoundValue("App", "AdvancedUI")
    RefreshBoundValue("App", "DeferRestarts")
    RefreshBoundValue("App", "SessionMode")
    RefreshBoundValue("App", "DeveloperMode")
    UpdateStartupRegistration()
    UpdateDeveloperVisibility()
    IvorySyncToolbar()
}

UpdateStartupRegistration() {
    desired := CfgBool("App", "StartWithWindows", false)
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    name := "DaHoodSuite"
    if desired {
        command := "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "
            . Quote(A_ScriptDir "\tools\Start-Suite.ps1") " -SuiteRoot " Quote(A_ScriptDir)
        try {
            RegWrite(command, "REG_SZ", key, name)
        } catch {
        }
    } else {
        try {
            RegDelete(key, name)
        } catch {
        }
    }
}

RefreshDebugValues() {
    global UI, WORKERS, CONFIG_PATH
    if !CfgBool("App", "DeveloperMode", false)
        return
    for module, data in WORKERS {
        key := "Debug_" module
        if UI.Has(key) {
            pid := data["pid"]
            state := WorkerRunning(module) ? "RUN" : "STOP"
            UI[key].Text := module "  |  " state "  |  pid " (pid ? pid : "-")
        }
    }
    if UI.Has("DebugRoblox")
        UI["DebugRoblox"].Text := "Roblox: " (ProcessExist("RobloxPlayerBeta.exe") ? "running" : "offline")
    if UI.Has("DebugConfig")
        UI["DebugConfig"].Text := "Config:`n" CONFIG_PATH
}

ValidateInstallation(*) {
    global WORKERS, WORKER_DIR, CONFIG_PATH
    missing := []
    if !FileExist(CONFIG_PATH)
        missing.Push("config")
    for module, data in WORKERS {
        if !FileExist(WORKER_DIR "\" data["file"])
            missing.Push(data["file"])
    }
    conflicts := ValidateHotkeyRegistry()
    if missing.Length = 0 && conflicts.Length = 0
        SetStatus("installation check passed", "ok")
    else if missing.Length
        SetStatus("missing: " JoinArray(missing, ", "), "error")
    else
        SetStatus("hotkey conflict: " conflicts[1], "error")
}



CreateSupportBundle(*) {
    global SUPPORT_DIR, CONFIG_PATH, LOG_PATH, APP_VERSION
    stamp := FormatTime(, "yyyyMMdd-HHmmss")
    folder := SUPPORT_DIR "\bundle-" stamp
    zipPath := SUPPORT_DIR "\DaLarp-support-" stamp ".zip"
    try {
        DirCreate(folder)
        FileCopy(CONFIG_PATH, folder "\settings.ini", true)
        if FileExist(LOG_PATH)
            FileCopy(LOG_PATH, folder "\suite.log", true)
        conflicts := ValidateHotkeyRegistry()
        report := "Da Larp " APP_VERSION "`n"
        report .= "Roblox=" (ProcessExist("RobloxPlayerBeta.exe") ? "running" : "offline") "`n"
        report .= "HotkeyConflicts=" (conflicts.Length ? JoinArray(conflicts, "; ") : "none") "`n"
        FileAppend(report, folder "\diagnostics.txt", "UTF-8")
        cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " Quote(A_ScriptDir "\tools\New-SupportBundle.ps1")
            . " -SourceDirectory " Quote(folder) " -Destination " Quote(zipPath)
        RunWait(cmd,, "Hide")
        SetStatus(FileExist(zipPath) ? "support bundle created" : "support bundle failed", FileExist(zipPath) ? "ok" : "error")
    } catch as err {
        Log("support bundle failed: " err.Message)
        SetStatus("support bundle failed", "error")
    }
}

JoinArray(items, separator := ", ") {
    result := ""
    for index, item in items
        result .= (index > 1 ? separator : "") item
    return result
}

StatusTick() {
    global UI, COLORS, PENDING_RESTARTS, LAST_GOOD_CLEAN_TICKS, LAST_GOOD_PATH, CONFIG_PATH, ROBLOX_WINDOW, WORKERS
    online := ProcessExist("RobloxPlayerBeta.exe") ? true : false
    if UI.Has("RobloxStatus") {
        UI["RobloxStatus"].Text := online ? "roblox online" : "roblox offline"
        IvoryUI.Items[UI["RobloxStatus"].Hwnd].color := ("0x" (online ? COLORS["Green"] : COLORS["Muted"])) + 0
        IvoryUI.Redraw(UI["RobloxStatus"])
    }
    UpdateModulePills()
    for module in ["Triggerbot", "Camlock", "Aimlock"] {
        key := "Viewport_" module
        if UI.Has(key) {
            status := ReadWorkerStatus(module)
            if status["width"] > 0
                UI[key].Text := "viewport · " status["width"] "×" status["height"] " · " (status["mode"] = "" ? "client" : status["mode"])
            else
                UI[key].Text := "viewport · waiting"
        }
    }
    if !WinActive(ROBLOX_WINDOW) && PENDING_RESTARTS.Count {
        queued := []
        for module, _ in PENDING_RESTARTS
            queued.Push(module)
        for module in queued {
            if RestartIfEnabled(module)
                PENDING_RESTARTS.Delete(module)
        }
    }
    clean := MasterEnabled()
    if clean {
        for module, _ in WORKERS {
            if WorkerShouldRun(module) && !WorkerRunning(module) {
                clean := false
                break
            }
        }
    }
    if clean && CfgBool("App", "AutoLastKnownGood", true) {
        LAST_GOOD_CLEAN_TICKS += 1
        if LAST_GOOD_CLEAN_TICKS >= 30 {
            try FileCopy(CONFIG_PATH, LAST_GOOD_PATH, true)
            LAST_GOOD_CLEAN_TICKS := 0
        }
    } else
        LAST_GOOD_CLEAN_TICKS := 0
    RefreshDebugValues()
}

RecoveryTick() {
    global WORKERS, Maintenance, Exiting, CONFIG_PATH, RecoveryBlocked
    if Exiting || Maintenance || RecoveryBlocked || !CfgBool("App", "AutoRecover", true) || !MasterEnabled()
        return

    for module, worker in WORKERS {
        if !WorkerShouldRun(module)
            continue
        if WorkerRunning(module)
            continue

        failures := worker.Has("crashCount") ? worker["crashCount"] : 0
        if failures >= 3 {
            IniWrite(0, CONFIG_PATH, "Modules", module)
            Log("disabled crash-looping worker: " module)
            SetStatus(module " disabled after repeated failures", "error")
            UpdateModulePills()
            continue
        }

        if StartWorker(module, true, true)
            Log("auto-recovered worker: " module)
    }
}

BuildTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Open Da Larp", (*) => ToggleGui())
    A_TrayMenu.Add("Restart input engine", ResetInputEngine)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}

ControllerExit(*) {
    global Exiting, SESSION_BACKUP, CONFIG_PATH
    if Exiting
        return
    Exiting := true
    try {
        PublishGuardianRoster()
    } catch {
    }
    try {
        SetTimer(StatusTick, 0)
        SetTimer(RecoveryTick, 0)
        SetTimer(IvoryCaptureTick, 0)
        SetTimer(IvoryTypingGuard, 0)
        SaveWindowPosition()
    } catch as err {
        try Log("window save or timer shutdown failed during exit: " err.Message)
    } finally {
        try {
            StopAllWorkers()
            IniWrite(0, CONFIG_PATH, "App", "TypingMode")
            SyncTypingFlag()
        } catch as err {
            try Log("worker stop failed during exit: " err.Message)
        }
        if SESSION_BACKUP != "" && FileExist(SESSION_BACKUP) {
            try FileCopy(SESSION_BACKUP, CONFIG_PATH, true)
        }
    }
}

MigrateV16(oldSchema) {
    global CONFIG_PATH
    for binding in [["CameraTurn", "Hotkey"], ["App", "TypingKey"]] {
        if GlobalHotkeyConflict(binding[1], binding[2], Cfg(binding[1], binding[2], "")) = ""
            continue
        for candidate in ["F8", "F9", "F11", "F12", "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24"] {
            if GlobalHotkeyConflict(binding[1], binding[2], candidate) = "" {
                IniWrite(candidate, CONFIG_PATH, binding[1], binding[2])
                break
            }
        }
    }
}

SyncTypingFlag() {
    global STATE_DIR
    path := STATE_DIR "\typing.pause"
    if CfgBool("App", "TypingMode", false) {
        if !FileExist(path)
            FileAppend("paused", path, "UTF-8")
    } else if FileExist(path)
        FileDelete(path)
}

WorkerShouldRun(module) {
    return MasterEnabled() && ModuleEnabled(module) && !TypingInputPaused(module)
}

ImportWeaponTemplate(slot, *) {
    global BASE_DIR
    source := FileSelect(1, , "Choose a cropped weapon icon", "Images (*.png; *.bmp; *.jpg; *.jpeg)")
    if source = ""
        return
    target := ""
    copied := false
    try {
        SplitPath(source, , , &extension)
        extension := StrLower(extension)
        if !RegExMatch(extension, "^(png|bmp|jpg|jpeg)$")
            throw Error("Choose PNG, BMP or JPEG")
        kind := 0
        bitmap := LoadPicture(source, "", &kind)
        if !bitmap
            throw Error("Cannot load weapon image")
        if kind != 0 {
            DllCall("user32\DestroyIcon", "Ptr", bitmap)
            throw Error("Choose a bitmap image")
        }
        try {
            info := Buffer(32, 0)
            if !DllCall("gdi32\GetObjectW", "Ptr", bitmap, "Int", info.Size, "Ptr", info, "Int")
                throw Error("Cannot read weapon image")
            if NumGet(info, 4, "Int") <= 0 || NumGet(info, 8, "Int") = 0
                throw Error("Invalid weapon image dimensions")
        } finally DllCall("gdi32\DeleteObject", "Ptr", bitmap)
        relative := "assets/weapons/custom" slot "-" A_TickCount "." extension
        target := BASE_DIR "\" StrReplace(relative, "/", "\")
        FileCopy(source, target, false)
        copied := true
        if !SetCfg("WeaponDetection", "Template" slot, relative, true)
            throw Error("Template setting could not be saved")
        SetStatus("weapon template " slot " imported", "ok")
    } catch as err {
        if copied
            try FileDelete(target)
        SetStatus(err.Message, "error")
    }
}

ShowWeaponStatus(*) {
    global STATE_DIR
    path := STATE_DIR "\weapondetection.status.ini"
    pid := IniRead(path, "Worker", "Pid", 0)
    if !IsNumber(pid) || !pid || !ProcessExist(pid) {
        SetStatus("enable Weapon Detection and the master switch to scan", "normal")
        return
    }
    allowed := IniRead(path, "Weapon", "Allowed", 0) = 1
    name := IniRead(path, "Weapon", "Name", "unknown")
    detail := IniRead(path, "Worker", "Detail", "")
    state := IniRead(path, "Worker", "State", "")
    SetStatus("weapon: " name " / " (allowed ? "automatic fire allowed" : "automatic fire blocked")
        (state = "weapon-unavailable" ? " / " detail : ""), allowed ? "ok" : "normal")
}
