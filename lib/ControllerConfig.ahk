SetCfg(section, key, value, restartModule := true) {
    return ApplySettingsTransaction([Map("section",section,"key",key,"value",value)], "setting")
}

ApplySettingsTransaction(changes, label := "settings", recordUndo := true) {
    if !IsObject(changes) || !changes.Length
        return true
    return ApplyConfigMutation((stage) => WriteSettingChanges(stage,changes), label, recordUndo)
}

WriteSettingChanges(path, changes) {
    for change in changes
        IniWrite(change["value"],path,change["section"],change["key"])
}

ApplyConfigMutation(mutate, label, recordUndo := true) {
    global CONFIG_PATH, Maintenance, RecoveryBlocked, UNDO_STACK, SESSION_BACKUP, PENDING_RESTARTS
    if Maintenance {
        SetStatus("another configuration change is in progress", "error")
        return false
    }
    Maintenance := true
    rollback := ""
    previousSession := CfgBool("App","SessionMode",false)
    try {
        rollback := BackupConfig(label)
        if rollback = ""
            throw Error("Cannot change settings without a recovery backup")
        ConfigStore.Apply(CONFIG_PATH,mutate,ValidateCandidateConfig,
            ControllerPrepareConfig,ControllerActivateConfig,ControllerActivateConfig)
        if recordUndo {
            UNDO_STACK.Push(Map("path",rollback,"label",label))
            while UNDO_STACK.Length > 40
                UNDO_STACK.RemoveAt(1)
        }
        if CfgBool("App","SessionMode",false) && !previousSession
            SESSION_BACKUP := rollback
        else if !CfgBool("App","SessionMode",false)
            SESSION_BACKUP := ""
        PENDING_RESTARTS.Clear()
        RecoveryBlocked := false
        RefreshAllValues()
        return true
    } catch as changeError {
        Log("configuration transaction failed: " label ": " changeError.Message)
        try RefreshAllValues()
        SetStatus("couldn't apply " label ": " changeError.Message,"error")
        return false
    } finally {
        Maintenance := false
    }
}

ValidateCandidateConfig(path) {
    if !ValidateProfileFile(path)
        throw Error("Configuration structure is invalid")
    SettingsSchema.ValidateFile(path)
}

ControllerPrepareConfig(*) {
    StopAllWorkers()
}

ControllerActivateConfig(*) {
    SyncTypingFlag()
    RegisterTypingHotkey()
    IvoryRuntimeRefresh()
    if !IvoryCaptureRefresh(true)
        throw Error("Capture setting could not be applied")
    if !ReconcileAllWorkers() {
        try StopAllWorkers()
        throw Error("Worker startup failed")
    }
}

ApplyPreset(section, presetName, changes, *) {
    batch := [Map("section",section,"key","Preset","value",presetName)]
    for key,value in changes
        batch.Push(Map("section",section,"key",key,"value",value))
    if !ApplySettingsTransaction(batch,"preset-" presetName)
        return false
    SetStatus(StrLower(section) " preset: " StrLower(presetName),"ok")
    return true
}

ApplyGlobalProfile(name, *) {
    batch := [Map("section","General","key","Profile","value",name)]
    for section,presetName in GlobalProfilePresets(name) {
        batch.Push(Map("section",section,"key","Preset","value",presetName))
        for key,value in GetPreset(section,presetName)
            batch.Push(Map("section",section,"key",key,"value",value))
    }
    if !ApplySettingsTransaction(batch,"profile-" name)
        throw Error("Profile transaction failed")
    SetStatus("profile applied: " StrLower(name),"ok")
    return true
}

LoadConfigFile(path) {
    global CONFIG_PATH
    if !ValidateProfileFile(path) {
        SetStatus("config file is missing or invalid","error")
        return false
    }
    if !ApplyConfigMutation((stage) => StageGameplayProfile(stage,path),"before-load")
        return false
    SetStatus("config loaded: " Cfg("General","Profile","custom"),"ok")
    return true
}

StageGameplayProfile(stage, source) {
    global EXAMPLE_PATH
    ConfigStore.MergeSections(stage,source,EXAMPLE_PATH,GameplaySections())
    if IniRead(source,"Meta","Kind","") = "converted"
        NormalizeConvertedTargetProfile(stage,source)
    profileName := IniRead(source,"General","Profile","")
    if profileName = "" {
        SplitPath(source,&fileName)
        profileName := RegExReplace(fileName,"i)\.ini$","")
    }
    IniWrite(profileName,stage,"General","Profile")
}

UndoLastChange(*) {
    global UNDO_STACK
    if !UNDO_STACK.Length {
        SetStatus("nothing to undo","normal")
        return
    }
    item := UNDO_STACK[UNDO_STACK.Length]
    if !FileExist(item["path"]) {
        SetStatus("undo snapshot is unavailable","error")
        return
    }
    if ApplyConfigMutation((stage) => FileCopy(item["path"],stage,true),"undo",false) {
        UNDO_STACK.Pop()
        SetStatus("last change restored","ok")
    }
}

RestoreDefaults(*) {
    global EXAMPLE_PATH
    if ApplyConfigMutation((stage) => FileCopy(EXAMPLE_PATH,stage,true),"before-reset") {
        IvoryConfigRefreshDropdown("Default (all disabled)")
        SetStatus("factory defaults restored","ok")
    }
}

RestoreLastKnownGood(*) {
    global LAST_GOOD_PATH
    if !FileExist(LAST_GOOD_PATH) {
        SetStatus("no known-good config yet","normal")
        return
    }
    if ApplyConfigMutation((stage) => FileCopy(LAST_GOOD_PATH,stage,true),"before-known-good")
        SetStatus("last known-good config restored","ok")
}

IsProtectedBackup(path) {
    global SESSION_BACKUP, UNDO_STACK
    if SESSION_BACKUP != "" && ConfigStore.IsSamePath(path,SESSION_BACKUP)
        return true
    for item in UNDO_STACK {
        if item.Has("path") && ConfigStore.IsSamePath(path,item["path"])
            return true
    }
    return false
}

SavedWindowVisible(x,y) {
    if x = -1 && y = -1
        return false
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index,&left,&top,&right,&bottom)
        if x >= left && x < right-30 && y >= top && y < bottom-30
            return true
    }
    return false
}
