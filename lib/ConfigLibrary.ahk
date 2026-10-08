#Include %A_LineFile%\..\ConfigIdentity.ahk

IvoryConfigRefreshDropdown(preferred := "") {
    global CONFIG_DIR, ConfigCatalog, ConfigSelection, ConfigDropdown, ConfigCount, ConfigMenu
    if !IsObject(ConfigDropdown)
        return
    previousPath := ""
    if preferred != "" {
        for _, preset in ConfigCatalog {
            if preset.label = preferred || preset.path = preferred {
                previousPath := preset.path
                break
            }
        }
        if previousPath = "" && FileExist(preferred)
            previousPath := preferred
    } else if ConfigSelection >= 1 && ConfigSelection <= ConfigCatalog.Length
        previousPath := ConfigCatalog[ConfigSelection].path
    if IsObject(ConfigMenu)
        IvoryUI.ClosePopup()
    ConfigMenu := 0
    items := []
    usedLabels := Map()
    Loop Files, CONFIG_DIR "\*.ini", "F" {
        fileName := StrLower(A_LoopFileName)
        if fileName = "settings.ini" || fileName = "settings.example.ini"
            continue
        path := A_LoopFileFullPath
        if !ValidateProfileFile(path)
            continue
        label := IniRead(path, "General", "Profile", "")
        if label = ""
            label := RegExReplace(A_LoopFileName, "i)\.ini$")
        label := StrReplace(StrReplace(Trim(label), "`r", " "), "`n", " ")
        sourceLabel := IniRead(path, "Meta", "SourcePath", "")
        if InStr(StrLower(label " " sourceLabel " " A_LoopFileName), "silent")
            continue
        if StrLen(label) > 83
            label := SubStr(label, 1, 83)
        if fileName = "default.ini"
            label := "Default (all disabled)"
        else if IniRead(path, "Meta", "Kind", "") = "converted" {
            label .= "  [converted]"
        }
        label := ConfigUniqueLabel(label, usedLabels)
        items.Push({label: label, path: path})
    }
    sorted := []
    for _, item in items {
        at := sorted.Length+1
        while at > 1 && StrCompare(item.label, sorted[at-1].label, false) < 0
            at--
        sorted.InsertAt(at, item)
    }
    ConfigCatalog := sorted
    chosen := 0
    defaultIndex := 0
    for index, item in ConfigCatalog {
        if item.path = previousPath || (preferred != "" && item.label = preferred)
            chosen := index
        SplitPath(item.path, &candidate)
        if StrLower(candidate) = "default.ini"
            defaultIndex := index
    }
    if chosen = 0 && ConfigCatalog.Length
        chosen := defaultIndex ? defaultIndex : 1
    ConfigSelection := chosen
    ConfigCount.Text := ConfigCatalog.Length " saved configs"
    IvoryUI.Redraw(ConfigCount)
    IvoryConfigSelectionChanged()
}

IvoryConfigSelectionChanged(*) {
    global ConfigCatalog, ConfigSelection, ConfigDropdown, ConfigDescription, ConfigStartupLabel
    if !IsObject(ConfigDropdown) || !IsObject(ConfigDescription)
        return
    if ConfigSelection < 1 || ConfigSelection > ConfigCatalog.Length {
        ConfigDropdown.Text := "No compatible configs - open the config folder"
        ConfigDescription.Text := "No configs found - refresh"
    } else {
        item := ConfigCatalog[ConfigSelection]
        ConfigDropdown.Text := item.label
        kind := IniRead(item.path, "Meta", "Kind", "native")
        amount := IniRead(item.path, "Meta", "MappedFields", "")
        if StrLower(kind) = "converted" {
            moduleName := IniRead(item.path, "Meta", "PrimaryModule", "Targeting")
            intensity := IniRead(item.path, "Meta", "Intensity", "Custom")
            detail := moduleName " / " intensity " / " (amount != "" ? amount " imported fields" : "converted")
            detail .= " / approximate translation; runtime differs"
        } else
            detail := "Native config"
        detail .= (IniRead(item.path, "General", "Master", "0") = "1" ? " / master ON" : " / master OFF")
        ConfigDescription.Text := detail
    }
    IvoryUI.Redraw(ConfigDropdown)
    IvoryUI.Redraw(ConfigDescription)
    if IsObject(ConfigStartupLabel) {
        startupFile := Cfg("App", "StartupConfig", "Default.ini")
        startupEnabled := CfgBool("App", "AutoLoadConfig", false)
        ConfigStartupLabel.Text := startupEnabled ? "Startup: " RegExReplace(startupFile, "i)\.ini$") : "Startup: disabled"
        IvoryUI.Redraw(ConfigStartupLabel)
    }
}

IvoryConfigOpenDropdown(*) {
    global ConfigDropdown, ConfigCatalog, ConfigSelection, ConfigMenu, MainGui
    if !ConfigCatalog.Length {
        SetStatus("no compatible configs in the config folder", "error")
        return
    }
    if IsObject(ConfigMenu) {
        IvoryUI.ClosePopup()
        return
    }
    IvoryUI.ClosePopup()
    popup := Gui("+Owner" MainGui.Hwnd " -Caption +ToolWindow", "Da Larp configurations")
    popup.BackColor := "141414"
    popup.SetFont("s9 cFFFFFF", "Tahoma")
    visibleCount := Min(10, ConfigCatalog.Length)
    popupW := 456, popupH := 65+visibleCount*25
    handles := []
    ctrl := IvoryUI.Add(popup, "panel", 0, 0, popupW, popupH)
    handles.Push(ctrl.Hwnd)
    ctrl := IvoryUI.Add(popup, "label", 10, 6, 330, 18, "CHOOSE A CONFIGURATION")
    handles.Push(ctrl.Hwnd)
    info := IvoryUI.Add(popup, "label", 10, popupH-29, 326, 20, "")
    IvoryUI.Items[info.Hwnd].color := 0xA6A6AA
    handles.Push(info.Hwnd)
    list := IvoryUI.Add(popup, "config-menu-list", 8, 27,
        popupW-35, visibleCount*25, "", "", IvoryConfigChooseAtPoint)
    handles.Push(list.Hwnd)
    bar := IvoryUI.Add(popup, "config-menu-scroll", popupW-20, 29,
        11, visibleCount*25-4, "", "", IvoryConfigScrollbarClick)
    handles.Push(bar.Hwnd)
    prev := IvoryUI.Add(popup, "button", popupW-89, popupH-31, 38, 24, "^", "", IvoryConfigPage.Bind(-1))
    next := IvoryUI.Add(popup, "button", popupW-47, popupH-31, 38, 24, "v", "", IvoryConfigPage.Bind(1))
    handles.Push(prev.Hwnd)
    handles.Push(next.Hwnd)
    scrollPx := Max(0, Min(ConfigCatalog.Length-visibleCount,
        ConfigSelection-Floor(visibleCount/2)-1))*25
    ConfigMenu := {gui:popup, list:list, info:info, scrollbar:bar,
        scrollPx:scrollPx, targetPx:scrollPx, count:visibleCount,
        lastTick:A_TickCount, rowHeight:25}
    IvoryUI.Popup := popup
    IvoryUI.PopupSource := ConfigDropdown
    IvoryUI.PopupHandles := handles
    popup.OnEvent("Escape", (*) => IvoryUI.ClosePopup())
    popup.OnEvent("Close", (*) => IvoryUI.ClosePopup())
    rect := Buffer(16)
    DllCall("user32\GetWindowRect", "Ptr", ConfigDropdown.Hwnd, "Ptr", rect)
    px := NumGet(rect, 0, "Int")
    py := NumGet(rect, 12, "Int")
    scale := IvoryUI.ControlScale(ConfigDropdown)
    realW := Round(popupW*scale), realH := Round(popupH*scale)
    screen := MonitorFromPoint(px, py)
    MonitorGetWorkArea(screen, &ml, &mt, &mr, &mb)
    px := Max(ml, Min(px, mr-realW))
    if py+realH > mb
        py := Max(mt, NumGet(rect, 4, "Int")-realH)
    IvoryConfigRenderMenu()
    popup.Show("x" px " y" py " w" realW " h" realH)
}

IvoryConfigMaxScroll() {
    global ConfigMenu, ConfigCatalog
    if !IsObject(ConfigMenu)
        return 0
    return Max(0, (ConfigCatalog.Length-ConfigMenu.count)*ConfigMenu.rowHeight)
}

IvoryConfigRenderMenu() {
    global ConfigMenu, ConfigCatalog
    if !IsObject(ConfigMenu)
        return
    first := Floor(ConfigMenu.scrollPx/ConfigMenu.rowHeight)+1
    last := Min(ConfigCatalog.Length, Ceil((ConfigMenu.scrollPx+
        ConfigMenu.count*ConfigMenu.rowHeight)/ConfigMenu.rowHeight))
    caption := first "-" last " of " ConfigCatalog.Length "  |  wheel / drag to browse"
    if ConfigMenu.info.Text != caption {
        ConfigMenu.info.Text := caption
        IvoryUI.Redraw(ConfigMenu.info)
    }
    listItem := IvoryUI.Items[ConfigMenu.list.Hwnd]
    listItem.scrollPx := ConfigMenu.scrollPx
    if IvoryUI.Hover = ConfigMenu.list.Hwnd {
        pos := IvoryUI.Point(ConfigMenu.list)
        listItem.hoverRow := pos.y >= 0 && pos.y < ConfigMenu.count*ConfigMenu.rowHeight
            ? Floor((ConfigMenu.scrollPx+pos.y)/ConfigMenu.rowHeight)+1 : 0
    } else
        listItem.hoverRow := 0
    IvoryUI.Redraw(ConfigMenu.list)
    barItem := IvoryUI.Items[ConfigMenu.scrollbar.Hwnd]
    barItem.min := ConfigMenu.scrollPx/Max(1, IvoryConfigMaxScroll())
    barItem.max := Min(1, ConfigMenu.count/ConfigCatalog.Length)
    IvoryUI.Redraw(ConfigMenu.scrollbar)
}

IvoryConfigPaintList(dc, item, w, h, s) {
    global ConfigCatalog, ConfigSelection
    IvoryUI.Fill(dc, 0, 0, w, h, 0x171717)
    offset := item.HasOwnProp("scrollPx") ? item.scrollPx : 0
    hoverRow := item.HasOwnProp("hoverRow") ? item.hoverRow : 0
    first := Max(1, Floor(offset/25)+1)
    last := Min(ConfigCatalog.Length, Floor((offset+h/s)/25)+2)
    Loop Max(0, last-first+1) {
        index := first+A_Index-1
        y := Round(((index-1)*25-offset)*s)
        rowH := Round(25*s)+1
        selected := index = ConfigSelection
        hovering := index = hoverRow
        color := selected ? IvoryUI.MixColor(0x171717, IvoryUI.Accent, 0.17)
            : (hovering ? 0x28282B : 0x171717)
        IvoryUI.Fill(dc, 0, y, w, rowH, color)
        if selected
            IvoryUI.Fill(dc, 0, y, 2*s, rowH, IvoryUI.Accent)
        IvoryUI.Text(dc, ConfigCatalog[index].label, 10*s, y, w-18*s, 25*s,
            selected ? IvoryUI.Accent : 0xEDEDEE)
    }
}

IvoryConfigHoverAt(ctrl) {
    global ConfigMenu
    if !IsObject(ConfigMenu) || ctrl.Hwnd != ConfigMenu.list.Hwnd
        return
    point := IvoryUI.Point(ctrl)
    index := point.y >= 0 && point.y < ConfigMenu.count*ConfigMenu.rowHeight
        ? Floor((ConfigMenu.scrollPx+point.y)/ConfigMenu.rowHeight)+1 : 0
    item := IvoryUI.Items[ctrl.Hwnd]
    if !item.HasOwnProp("hoverRow") || item.hoverRow != index {
        item.hoverRow := index
        IvoryUI.Redraw(ctrl)
    }
}

IvoryConfigChooseAtPoint(ctrl, *) {
    global ConfigMenu, ConfigSelection, ConfigCatalog
    if !IsObject(ConfigMenu)
        return
    pos := IvoryUI.Point(ctrl)
    if pos.y < 0 || pos.y >= ConfigMenu.count*ConfigMenu.rowHeight
        return
    index := Floor((ConfigMenu.scrollPx+pos.y)/ConfigMenu.rowHeight)+1
    if index < 1 || index > ConfigCatalog.Length
        return
    ConfigSelection := index
    IvoryUI.ClosePopup()
    IvoryConfigSelectionChanged()
}

IvoryConfigScrollTo(pixelOffset, animate := true) {
    global ConfigMenu
    if !IsObject(ConfigMenu)
        return
    ConfigMenu.targetPx := Max(0, Min(IvoryConfigMaxScroll(), pixelOffset))
    if !animate {
        SetTimer(IvoryConfigScrollTick, 0)
        ConfigMenu.scrollPx := ConfigMenu.targetPx
        IvoryConfigRenderMenu()
        return
    }
    ConfigMenu.lastTick := A_TickCount
    SetTimer(IvoryConfigScrollTick, 16)
}

IvoryConfigScrollTick() {
    global ConfigMenu
    if !IsObject(ConfigMenu) {
        SetTimer(IvoryConfigScrollTick, 0)
        return
    }
    now := A_TickCount
    elapsed := Max(8, Min(64, now-ConfigMenu.lastTick))
    ConfigMenu.lastTick := now
    difference := ConfigMenu.targetPx-ConfigMenu.scrollPx
    if Abs(difference) < 0.5 {
        ConfigMenu.scrollPx := ConfigMenu.targetPx
        SetTimer(IvoryConfigScrollTick, 0)
    } else
        ConfigMenu.scrollPx += difference*(1-0.72**(elapsed/16))
    IvoryConfigRenderMenu()
}

IvoryConfigScrollbarStart(ctrl) {
    global ConfigMenu
    if !IsObject(ConfigMenu)
        return
    item := IvoryUI.Items[ctrl.Hwnd]
    height := ConfigMenu.count*ConfigMenu.rowHeight-4
    thumbH := Max(12, height*item.max)
    y := IvoryUI.Point(ctrl).y
    thumbTop := (height-thumbH)*item.min
    item.grabOffset := y >= thumbTop && y <= thumbTop+thumbH
        ? y-thumbTop : thumbH/2
    IvoryConfigScrollbarClick(ctrl)
}

IvoryConfigScrollbarClick(ctrl, *) {
    global ConfigMenu
    if !IsObject(ConfigMenu)
        return
    item := IvoryUI.Items[ctrl.Hwnd]
    height := ConfigMenu.count*ConfigMenu.rowHeight-4
    thumbH := Max(12, height*item.max)
    track := Max(1, height-thumbH)
    grab := item.HasOwnProp("grabOffset") ? item.grabOffset : thumbH/2
    fraction := Max(0, Min(1, (IvoryUI.Point(ctrl).y-grab)/track))
    IvoryConfigScrollTo(fraction*IvoryConfigMaxScroll(), false)
}

IvoryConfigPage(direction, *) {
    global ConfigMenu
    if !IsObject(ConfigMenu)
        return
    IvoryConfigScrollTo(ConfigMenu.targetPx+direction*ConfigMenu.count*ConfigMenu.rowHeight)
}

IvoryConfigWheel(wParam, lParam, msg, hwnd) {
    global ConfigMenu
    if !IsObject(ConfigMenu)
        return
    popupHwnd := ConfigMenu.gui.Hwnd
    pos := Buffer(8)
    DllCall("user32\GetCursorPos", "Ptr", pos)
    DllCall("user32\ScreenToClient", "Ptr", popupHwnd, "Ptr", pos)
    mx := NumGet(pos, 0, "Int"), my := NumGet(pos, 4, "Int")
    rect := Buffer(16)
    DllCall("user32\GetClientRect", "Ptr", popupHwnd, "Ptr", rect)
    if mx < 0 || my < 0 || mx >= NumGet(rect, 8, "Int") || my >= NumGet(rect, 12, "Int")
        return
    delta := (wParam >> 16) & 0xFFFF
    if delta >= 0x8000
        delta -= 0x10000
    if delta = 0
        return 1
    lines := 3
    if !DllCall("user32\SystemParametersInfoW", "UInt", 0x68, "UInt", 0, "UInt*", &lines, "UInt", 0, "Int")
        lines := 3
    if lines = 0
        return 1
    distance := lines = 0xFFFFFFFF ? ConfigMenu.count*ConfigMenu.rowHeight : Min(10, lines)*18
    IvoryConfigScrollTo(ConfigMenu.targetPx-delta/120*distance)
    return 1
}

IvoryConfigKeyDown(wParam, lParam, msg, hwnd) {
    global ConfigMenu, ConfigCatalog, ConfigSelection
    if !IsObject(ConfigMenu)
        return
    menuHwnd := ConfigMenu.gui.Hwnd
    if hwnd != menuHwnd && !DllCall("user32\IsChild", "Ptr", menuHwnd, "Ptr", hwnd, "Int")
        return
    if wParam = 0x1B {
        IvoryUI.ClosePopup()
        return 1
    }
    if wParam = 0x0D {
        if ConfigSelection >= 1 && ConfigSelection <= ConfigCatalog.Length {
            IvoryUI.ClosePopup()
            IvoryConfigSelectionChanged()
        }
        return 1
    }
    step := wParam = 0x26 ? -1 : wParam = 0x28 ? 1 : wParam = 0x21 ? -ConfigMenu.count : wParam = 0x22 ? ConfigMenu.count : 0
    if step = 0
        return
    ConfigSelection := Max(1, Min(ConfigCatalog.Length, ConfigSelection+step))
    top := (ConfigSelection-1)*ConfigMenu.rowHeight
    bottom := top+ConfigMenu.rowHeight
    viewport := ConfigMenu.count*ConfigMenu.rowHeight
    if top < ConfigMenu.targetPx
        IvoryConfigScrollTo(top)
    else if bottom > ConfigMenu.targetPx+viewport
        IvoryConfigScrollTo(bottom-viewport)
    IvoryConfigSelectionChanged()
    IvoryConfigRenderMenu()
    return 1
}

IvoryConfigLoadSelected(*) {
    global ConfigSelection, ConfigCatalog, ConfigMenu
    if ConfigSelection < 1 || ConfigSelection > ConfigCatalog.Length {
        SetStatus("select a config to load", "error")
        return
    }
    item := ConfigCatalog[ConfigSelection]
    if !FileExist(item.path) {
        SetStatus("config was removed; refresh the list", "error")
        IvoryConfigRefreshDropdown()
        return
    }
    if IsObject(ConfigMenu) {
        IvoryUI.ClosePopup()
        ConfigMenu := 0
    }
    if LoadConfigFile(item.path)
        IvoryConfigRefreshDropdown(item.path)
}

IvoryConfigSaveCurrent(*) {
    global CONFIG_DIR, CONFIG_PATH
    input := IvoryPrompt("Name your config", Cfg("General", "Profile", "New config"), "text")
    if input.Result != "OK"
        return
    name := SanitizeFilename(input.Value)
    if name = "" || StrLower(name) = "settings" || StrLower(name) = "settings.example" || StrLower(name) = "default" {
        SetStatus("choose another config name", "error")
        return
    }
    path := CONFIG_DIR "\" name ".ini"
    if FileExist(path) {
        answer := MsgBox("Replace the existing `"" name "`" config?", "Da Larp", "YesNo Icon!")
        if answer != "Yes"
            return
    }
    temporary := CONFIG_DIR "\.pending-" A_TickCount "-" Random(1000, 9999) ".ini"
    try {
        WriteProfileFile(temporary, name)
        if !ValidateProfileFile(temporary)
            throw Error("New config failed validation")
        FileMove(temporary, path, true)
        IniWrite(name, CONFIG_PATH, "General", "Profile")
        IvoryConfigRefreshDropdown(name)
        SetStatus("config saved: " name, "ok")
    } catch as err {
        Log("config save failed: " err.Message)
        SetStatus("couldn't save config", "error")
    } finally {
        try FileDelete(temporary)
    }
}

IvoryConfigImport(*) {
    global CONFIG_DIR
    path := FileSelect(3, , "Import a Da Larp INI config", "INI configuration (*.ini)")
    if path = ""
        return
    if !ValidateProfileFile(path) {
        SetStatus("not a compatible native INI config", "error")
        return
    }
    SplitPath(path, &filename)
    stem := RegExReplace(filename, "i)\.ini$")
    stem := SanitizeFilename(stem)
    if stem = "" || StrLower(stem) = "settings" || StrLower(stem) = "settings.example" || StrLower(stem) = "default" {
        SetStatus("reserved or invalid config name", "error")
        return
    }
    dest := CONFIG_DIR "\" stem ".ini"
    if FileExist(dest) {
        SetStatus("a config with that name already exists", "error")
        return
    }
    try {
        FileCopy(path, dest)
        IvoryConfigRefreshDropdown(dest)
        SetStatus("config imported: " stem, "ok")
    } catch as err {
        Log("config import failed: " err.Message)
        SetStatus("couldn't import config", "error")
    }
}

IvoryConfigOpenFolder(*) {
    global CONFIG_DIR
    Run('explorer.exe "' CONFIG_DIR '"')
}

IvoryConfigUseSelectedAtStartup(*) {
    global ConfigCatalog, ConfigSelection
    if ConfigSelection < 1 || ConfigSelection > ConfigCatalog.Length {
        SetStatus("select a config first", "error")
        return
    }
    selection := ConfigCatalog[ConfigSelection]
    SplitPath(selection.path, &filename)
    if !ConfigStartupFileValid(filename) || !ValidateProfileFile(selection.path) {
        SetStatus("startup configuration is invalid", "error")
        return
    }
    changes := [Map("section", "App", "key", "StartupConfig", "value", filename),
        Map("section", "App", "key", "AutoLoadConfig", "value", 1)]
    if ApplySettingsTransaction(changes, "startup-config") {
        IvoryConfigSelectionChanged()
        SetStatus("startup config: " selection.label, "ok")
    }
}

ConfigStartupFileValid(filename) {
    if filename = "" || InStr(filename, "\") || InStr(filename, "/") || InStr(filename, ":")
        return false
    if !RegExMatch(filename, "i)^[^<>|?*" Chr(34) "]+\.ini$")
        return false
    lowered := StrLower(filename)
    return lowered != "settings.ini" && lowered != "settings.example.ini"
}

ApplyStartupConfig() {
    global CONFIG_DIR, CONFIG_PATH
    if !CfgBool("App", "AutoLoadConfig", false)
        return false
    filename := Cfg("App", "StartupConfig", "Default.ini")
    if !ConfigStartupFileValid(filename)
        return false
    path := CONFIG_DIR "\" filename
    if !FileExist(path) || !ValidateProfileFile(path)
        return false
    try {
        ConfigStore.Apply(CONFIG_PATH, (stage) => StageGameplayProfile(stage, path), ValidateCandidateConfig)
        return true
    } catch as startupError {
        try FileAppend("Startup config failed: " startupError.Message "`n", A_ScriptDir "\logs\suite.log", "UTF-8")
        return false
    }
}
