IvoryBuildToolbar() {
    global MainGui, UI, APP_VERSION, APP_NAME

    previousDpi := IvoryEnterPhysicalDpi()
    try bar := Gui("-Owner -Caption -Border -DPIScale +ToolWindow +AlwaysOnTop +E0x08000000", APP_NAME " navigation")
    finally IvoryRestoreDpi(previousDpi)
    bar.MarginX := 0
    bar.MarginY := 0
    bar.BackColor := "1E1E1E"
    IvoryUI.Toolbar := bar
    IvoryUI.PixelScales[bar.Hwnd] := IvoryUI.ToolbarBaseScale*Max(96,DllCall("user32\GetDpiForWindow", "Ptr", bar.Hwnd, "UInt"))/96
    IvoryAppBarInit()
    MonitorGet(MonitorGetPrimary(), &left, &top, &right, &bottom)
    dpi := DllCall("user32\GetDpiForWindow", "Ptr", MainGui.Hwnd, "UInt") / 96
    width := (right-left)/dpi/IvoryUI.Scale
    UI["ToolbarBackground"] := IvoryUI.Add(bar, "bar", 0, 0, width, 26)
    UI["ToolbarLocation"] := IvoryUI.Add(bar, "brand", 8, 3, 72, 20, APP_NAME)
    IvoryUI.ToolbarButtons := Map()
    IvoryUI.ToolbarOrder := []
    x := 88
    for spec in [["targeting",72,IvoryToolbarNavigate.Bind("camlock")],
        ["macros",53,IvoryToolbarNavigate.Bind("macro")], ["themes",56,IvoryThemeMenu],
        ["configs",56,IvoryToolbarNavigate.Bind("config")], ["system",52,IvoryToolbarNavigate.Bind("system")],
        ["exit",43,IvoryToolbarExit]] {
        kind := spec[1] = "exit" ? "button" : "tab"
        button := IvoryUI.Add(bar, kind, x, 3, spec[2], 20, spec[1], "", spec[3])
        IvoryUI.ToolbarButtons[spec[1]] := button
        IvoryUI.Items[button.Hwnd].baseW := spec[2]
        IvoryUI.Items[button.Hwnd].animated := true
        IvoryUI.ToolbarOrder.Push(spec[1])
        x += spec[2]+3
    }
    UI["Status"] := IvoryUI.Add(bar, "bar-label", x+8, 3, Max(50,width-x-170), 20)
    UI["RobloxStatus"] := IvoryUI.Add(bar, "bar-label", width-152, 3, 140, 20, "roblox offline")
    UI["ToolbarProfile"] := IvoryUI.Add(bar, "identity", width-384, 3, 224, 20)
    bar.OnEvent("Escape", IvoryHide)
    bar.OnEvent("Close", IvorySetToolbarEnabled.Bind(false))
    MainGui.OnEvent("Size", IvoryMenuSizeChanged)
    OnMessage(0x3, IvoryToolbarMainMoved)
    OnMessage(0x7E, IvoryToolbarDisplayChanged)
    OnMessage(0x2E0, IvoryToolbarDpiChanged)
    IvorySetStatus("ready · v" APP_VERSION)
}

IvoryToolbarAnimate(*) {
    global UI
    if !IvoryUI.ToolbarEnabled || !IsObject(IvoryUI.Toolbar)
        return
    now := DllCall("kernel32\GetTickCount64", "UInt64")
    delta := IvoryUI.AnimationTime ? Max(1, Min(100, now-IvoryUI.AnimationTime)) : 16
    IvoryUI.AnimationTime := now
    amount := 1-Exp(-delta/70)
    focused := DllCall("user32\GetFocus", "Ptr")
    for _, button in IvoryUI.ToolbarButtons {
        item := IvoryUI.Items[button.Hwnd]
        selection := item.selected ? 1 : 0
        hover := (IvoryUI.Hover = button.Hwnd || focused = button.Hwnd) ? 1 : 0
        nextSelection := item.selectionBlend+(selection-item.selectionBlend)*amount
        nextHover := item.hoverBlend+(hover-item.hoverBlend)*amount
        if Abs(nextSelection-selection) < 0.003
            nextSelection := selection
        if Abs(nextHover-hover) < 0.003
            nextHover := hover
        if nextSelection != item.selectionBlend || nextHover != item.hoverBlend {
            item.selectionBlend := nextSelection
            item.hoverBlend := nextHover
            IvoryUI.Redraw(button)
        }
    }

}

IvorySetStatus(text, kind := "normal") {
    global UI, COLORS
    if !UI.Has("Status")
        return
    previousCritical := A_IsCritical
    Critical("On")
    try {
        ctrl := UI["Status"]
        item := IvoryUI.Items[ctrl.Hwnd]
        color := kind = "ok" ? COLORS["Green"] : kind = "error" ? COLORS["Red"] : COLORS["Muted"]
        item.color := ("0x" color) + 0
        item.textAlpha := 255
        ctrl.Text := text
        IvoryUI.StatusMessage := {started: DllCall("kernel32\GetTickCount64", "UInt64"),
            hold: kind = "error" ? 5000 : 2500, fade: 500}
        IvoryUI.Redraw(ctrl)
        SetTimer(IvoryStatusTick, text = "" ? 0 : 30)
        if text = ""
            IvoryUI.StatusMessage := 0
    } finally Critical(previousCritical)
}

IvoryStatusTick(*) {
    global UI

    previousCritical := A_IsCritical
    Critical("On")
    try {
        state := IvoryUI.StatusMessage
        if !IvoryStatusValid(state) || !UI.Has("Status") {
            SetTimer(IvoryStatusTick, 0)
            IvoryUI.StatusMessage := 0
            return
        }
        if !IvoryUI.Items.Has(UI["Status"].Hwnd) {
            SetTimer(IvoryStatusTick, 0)
            IvoryUI.StatusMessage := 0
            return
        }
        elapsed := DllCall("kernel32\GetTickCount64", "UInt64")-state.started
        if elapsed < state.hold
            return
        ctrl := UI["Status"]
        if elapsed >= state.hold+state.fade {
            IvoryClearStatus()
            return
        }
        alpha := Round(255*(1-(elapsed-state.hold)/state.fade))
        item := IvoryUI.Items[ctrl.Hwnd]
        if alpha != item.textAlpha {
            item.textAlpha := alpha
            IvoryUI.Redraw(ctrl)
        }
    } finally Critical(previousCritical)
}

IvoryClearStatus() {
    global UI
    previousCritical := A_IsCritical
    Critical("On")
    try {
        SetTimer(IvoryStatusTick, 0)
        IvoryUI.StatusMessage := 0
        if UI.Has("Status") {
            ctrl := UI["Status"]
            IvoryUI.Items[ctrl.Hwnd].textAlpha := 0
            ctrl.Text := ""
            IvoryUI.Redraw(ctrl)
        }
    } finally Critical(previousCritical)
}

IvoryShow(options := "") {
    global MainGui
    if !UserProfile.Ready
        return
    s := IvoryUI.Scale
    MainGui.Show(options " w" Round(504*s) " h" Round(604*s))
    IvorySyncToolbar()
    IvoryFitMenu()
}

IvorySyncToolbar() {
    if !IsObject(IvoryUI.Toolbar)
        return
    IvoryUI.ToolbarEnabled := UserProfile.Ready && CfgBool("App", "TopBarEnabled", true)
    if !IvoryUI.ToolbarEnabled {
        if IsObject(IvoryUI.Popup) && DllCall("user32\GetWindow", "Ptr", IvoryUI.Popup.Hwnd, "UInt", 4, "Ptr") = IvoryUI.Toolbar.Hwnd
            IvoryUI.ClosePopup()
        IvoryToolbarShutdown()
        IvoryUI.Toolbar.Hide()
    } else {
        IvoryPositionToolbar()
        IvoryToolbarListen()
        IvoryKeepToolbarTop()
        SetTimer(IvoryFitMenu, -1)
    }
    IvoryRefreshToolbar()
}

IvoryPositionToolbar(*) {
    global MainGui, UI
    if !IvoryUI.ToolbarEnabled || !IsObject(IvoryUI.Toolbar) || IvoryUI.ToolbarPositioning
        return
    IvoryUI.ToolbarPositioning := true
    previousDpi := IvoryEnterPhysicalDpi()
    try {
        if !DllCall("user32\IsIconic", "Ptr", MainGui.Hwnd, "Int") {
            MainGui.GetPos(&x, &y)
            IvoryUI.ToolbarMonitor := MonitorFromPoint(x, y)
        }
        monitor := IvoryUI.ToolbarMonitor
        if monitor < 1 || monitor > MonitorGetCount()
            monitor := MonitorGetPrimary()
        IvoryUI.ToolbarMonitor := monitor
        MonitorGet(monitor, &left, &top, &right, &bottom)
        bar := IvoryUI.Toolbar

        point := Buffer(8)
        NumPut("Int", left+1, "Int", top+1, point)
        destination := DllCall("user32\MonitorFromPoint", "Int64", NumGet(point, 0, "Int64"), "UInt", 2, "Ptr")
        if DllCall("user32\MonitorFromWindow", "Ptr", bar.Hwnd, "UInt", 2, "Ptr") != destination
            DllCall("user32\SetWindowPos", "Ptr", bar.Hwnd, "Ptr", -1,
                "Int", left, "Int", top, "Int", 0, "Int", 0, "UInt", 0x11)

        scale := Min(IvoryUI.ToolbarBaseScale * Max(96, DllCall("user32\GetDpiForWindow", "Ptr", bar.Hwnd, "UInt")) / 96,
            (right-left)/320)
        IvoryUI.PixelScales[bar.Hwnd] := scale
        narrow := (right-left)/scale < 1000
        barHeight := narrow ? 46 : 26
        rect := IvoryAppBarPosition(left, top, right, Max(1, Round(barHeight*scale)))
        actual := Buffer(16)
        DllCall("user32\GetWindowRect", "Ptr", bar.Hwnd, "Ptr", actual)
        if !DllCall("user32\IsWindowVisible", "Ptr", bar.Hwnd, "Int")
            || NumGet(actual, 0, "Int") != rect.left || NumGet(actual, 4, "Int") != rect.top
            || NumGet(actual, 8, "Int") != rect.right || NumGet(actual, 12, "Int") != rect.bottom
            bar.Show("NA x" rect.left " y" rect.top " w" rect.right-rect.left " h" rect.bottom-rect.top)
        width := (rect.right-rect.left)/scale
        dense := width < 760
        compact := Map("targeting",["target",46],"macros",["mac",37],"themes",["theme",50],
            "configs",["cfg",30],"system",["sys",32],"exit",["exit",35])
        navWidth := 0
        for name in IvoryUI.ToolbarOrder {
            item := IvoryUI.Items[IvoryUI.ToolbarButtons[name].Hwnd]
            item.w := dense ? compact[name][2] : item.baseW
            navWidth += item.w+3
        }
        labelWidth := Max(0, Min(72, width-navWidth-16))
        UI["ToolbarBackground"].Move(0, 0, rect.right-rect.left, rect.bottom-rect.top)
        UI["ToolbarLocation"].Move(Round(8*scale), Round(3*scale), Max(1,Round(labelWidth*scale)), Round(20*scale))
        UI["ToolbarLocation"].Visible := labelWidth >= 48
        IvoryUI.Redraw(UI["ToolbarLocation"])
        x := labelWidth+16
        for name in IvoryUI.ToolbarOrder {
            button := IvoryUI.ToolbarButtons[name]
            item := IvoryUI.Items[button.Hwnd]
            item.x := x
            button.Text := dense ? compact[name][1] : name
            button.Move(Round(x*scale), Round(3*scale), Round(item.w*scale), Round(20*scale))
            IvoryUI.Redraw(button)
            x += item.w+3
        }
        IvoryPositionToolbarLabels(width, x, narrow, scale)
    } finally {
        IvoryRestoreDpi(previousDpi)
        IvoryUI.ToolbarPositioning := false
    }
}

IvoryPositionToolbarLabels(width, navEnd, narrow, scale) {
    global UI
    layout := UserProfile.ToolbarLayout(width, navEnd, narrow)
    for spec in [["Status",layout.start,layout.statusW],
        ["RobloxStatus",layout.onlineX,layout.onlineW],
        ["ToolbarProfile",layout.identityX,layout.identityW]] {
        ctrl := UI[spec[1]]
        ctrl.Visible := spec[3] > 0
        ctrl.Move(Round(spec[2]*scale), Round(layout.y*scale),
            Max(1,Round(spec[3]*scale)), Round(layout.h*scale))
        IvoryUI.Redraw(ctrl)
    }
}

IvoryFitMenu(*) {
    global MainGui, PAGE_CONTROLS
    if !IvoryMenuVisible() || IvoryKeyCaptureActive()
        return
    MainGui.GetPos(&x, &y, &w, &h)
    MonitorGetWorkArea(MonitorFromPoint(x, y), &left, &top, &right, &bottom)
    dpi := Max(96, DllCall("user32\GetDpiForWindow", "Ptr", MainGui.Hwnd, "UInt"))/96
    scale := Max(0.05, Min(0.8, (right-left-16)/(504*dpi), (bottom-top-16)/(604*dpi)))
    if Abs(scale-IvoryUI.Scale) > 0.001 {
        IvoryUI.ClosePopup()
        IvoryUI.Scale := scale
        for _, item in IvoryUI.Items {
            if item.ctrl.Gui.Hwnd = MainGui.Hwnd {
                item.ctrl.Move(Round(item.x*scale), Round(item.y*scale),
                    Max(1,Round(item.w*scale)), Max(1,Round(item.h*scale)))
                IvoryUI.Redraw(item.ctrl)
            }
        }
        for page, _ in PAGE_CONTROLS
            IvoryApplyTabs(page)
        w := Round(504*scale*dpi)
        h := Round(604*scale*dpi)
        SetTimer(IvoryPositionToolbar, -1)
    }
    x := Max(left+8, Min(right-w-8, x))
    y := Max(top+8, Min(bottom-h-8, y))
    MainGui.Show("NA x" x " y" y " w" Round(504*scale) " h" Round(604*scale))
}

IvoryHide(*) {
    global MainGui
    IvoryCaptureCancel()
    IvoryUI.ClosePopup()
    MainGui.Hide()
    IvoryRefreshToolbar()
}

IvoryMenuVisible() {
    global MainGui
    return IsObject(MainGui) && DllCall("user32\IsWindowVisible", "Ptr", MainGui.Hwnd, "Int")
        && !DllCall("user32\IsIconic", "Ptr", MainGui.Hwnd, "Int")
}

IvoryToggleMenu(*) {
    if IvoryMenuVisible()
        IvoryHide()
    else
        IvoryShow()
}

IvoryToolbarNavigate(page, *) {
    ShowPage(page)
    IvoryShow()
}

IvoryToolbarExit(*) {
    ExitApp()
}

IvoryRefreshToolbar() {
    global ACTIVE_PAGE, UI, APP_NAME
    if !IsObject(IvoryUI.Toolbar) || !UI.Has("ToolbarLocation")
        return
    family := IvoryFamily(ACTIVE_PAGE)
    selected := family = "targeting" ? "targeting" : family = "macros" ? "macros" : ACTIVE_PAGE = "config" ? "configs" : "system"
    if IsObject(IvoryUI.Popup) && IvoryUI.PopupSource = IvoryUI.ToolbarButtons["themes"].Hwnd
        selected := "themes"
    for name, button in IvoryUI.ToolbarButtons {
        IvoryUI.Items[button.Hwnd].selected := name = selected
        IvoryUI.Redraw(button)
    }
    UI["ToolbarLocation"].Text := APP_NAME
    IvoryUI.Redraw(UI["ToolbarBackground"])
}

IvorySetToolbarEnabled(enabled, *) {
    if SetCfg("App", "TopBarEnabled", enabled ? 1 : 0)
        RefreshAllValues()
}

IvoryMenuSizeChanged(gui, minMax, width, height) {
    IvoryRefreshToolbar()
    if minMax != -1 && IvoryUI.ToolbarEnabled
        SetTimer(IvoryPositionToolbar, -1)
}

IvoryToolbarMainMoved(wParam, lParam, msg, hwnd) {
    global MainGui
    if hwnd = MainGui.Hwnd && IvoryUI.ToolbarEnabled
        SetTimer(IvoryPositionToolbar, -1)
}

IvoryToolbarDisplayChanged(*) {
    IvoryUI.AppBarDirty := true
    if IvoryUI.ToolbarEnabled {
        SetTimer(IvoryPositionToolbar, -1)
        SetTimer(IvoryFitMenu, -50)
    }
}

IvoryToolbarDpiChanged(wParam, lParam, msg, hwnd) {
    global MainGui
    if IvoryUI.ToolbarEnabled && (hwnd = MainGui.Hwnd || hwnd = IvoryUI.Toolbar.Hwnd)
    {
        IvoryUI.AppBarDirty := true
        SetTimer(IvoryPositionToolbar, -1)
        SetTimer(IvoryFitMenu, -50)
    }
}

IvoryToolbarListen() {
    if !IvoryUI.ToolbarAnimating {
        IvoryUI.ToolbarAnimating := true
        IvoryUI.AnimationTime := DllCall("kernel32\GetTickCount64", "UInt64")
        SetTimer(IvoryToolbarAnimate, CfgBool("App", "CPUFriendly", false) ? 33 : 16)
    }
    if IvoryUI.ToolbarListening
        return
    IvoryUI.ToolbarListening := true
    IvoryUI.ToolbarHookCallback := CallbackCreate(IvoryToolbarForeground, , 7)

    IvoryUI.ToolbarHook := DllCall("user32\SetWinEventHook", "UInt", 3, "UInt", 3,
        "Ptr", 0, "Ptr", IvoryUI.ToolbarHookCallback, "UInt", 0, "UInt", 0, "UInt", 2, "Ptr")
    if !IvoryUI.ToolbarHook {
        CallbackFree(IvoryUI.ToolbarHookCallback)
        IvoryUI.ToolbarHookCallback := 0
        SetTimer(IvoryKeepToolbarTop, 1000)
    }
}

IvoryToolbarForeground(hook, event, hwnd, objectId, childId, eventThread, eventTime) {
    if IvoryUI.ToolbarEnabled
        SetTimer(IvoryKeepToolbarTop, -1)
}

IvoryKeepToolbarTop(*) {
    if !IvoryUI.ToolbarEnabled || !IsObject(IvoryUI.Toolbar)
        return
    hwnd := IvoryUI.Toolbar.Hwnd
    if DllCall("user32\IsWindowVisible", "Ptr", hwnd, "Int")
        DllCall("user32\SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", 0, "Int", 0,
            "Int", 0, "Int", 0, "UInt", 0x13)
}

IvoryToolbarShutdown(releaseCallback := true, *) {
    IvoryUI.ToolbarEnabled := false
    IvoryUI.ToolbarListening := false
    IvoryUI.ToolbarAnimating := false
    SetTimer(IvoryToolbarAnimate, 0)
    SetTimer(IvoryKeepToolbarTop, 0)
    SetTimer(IvoryPositionToolbar, 0)
    SetTimer(IvoryFitMenu, 0)
    IvoryAppBarRemove()
    if IvoryUI.ToolbarHook {
        DllCall("user32\UnhookWinEvent", "Ptr", IvoryUI.ToolbarHook)
        IvoryUI.ToolbarHook := 0
    }
    if IvoryUI.ToolbarHookCallback {
        if releaseCallback
            CallbackFree(IvoryUI.ToolbarHookCallback)
        IvoryUI.ToolbarHookCallback := 0
    }
}

IvoryPageVisible(page) {
    global ACTIVE_PAGE
    return page = ACTIVE_PAGE || (IvoryFamily(ACTIVE_PAGE) = "targeting" && IvoryFamily(page) = "targeting")
}

IvoryMappedTab(page, tab, key) {
    if page = "trigger"
        return "Triggerbot"
    if page = "camlock"
        return tab = "Tracking" ? "Main" : tab = "Prediction" ? "Field" : tab
    if page = "aimlock" {
        if tab = "Prediction" || InStr("|ResponseMs|LockRadius|LockHoldMs|Deadzone|MaxStep|ScanMs|", "|" key "|")
            return "Safety"
        return tab = "Tracking" ? "Main" : tab
    }
    return tab
}

IvoryContentHeight(group) {
    return IvoryUI.Rows[group.id ":" group.selected]-IvoryHiddenRowHeight(group,group.selected)
}

IvoryScrollGroup(groupKey, distance, absolute := false) {
    group := IvoryUI.Groups[groupKey]
    maxScroll := Max(0, IvoryContentHeight(group)-group.bodyH)
    value := absolute ? distance : group.scroll[group.selected]+distance
    group.scroll[group.selected] := Max(0, Min(maxScroll, value))
    IvoryApplyTabs(StrSplit(groupKey, ":")[1])
}

IvoryMouseWheel(wParam, lParam, msg, hwnd) {
    global MainGui, ConfigMenu
    if IsObject(ConfigMenu) && IvoryConfigWheel(wParam, lParam, msg, hwnd) = 1
        return 1
    point := Buffer(8)
    DllCall("user32\GetCursorPos", "Ptr", point)
    DllCall("user32\ScreenToClient", "Ptr", MainGui.Hwnd, "Ptr", point)
    scale := DllCall("user32\GetDpiForWindow", "Ptr", MainGui.Hwnd, "UInt") / 96 * IvoryUI.Scale
    x := NumGet(point, 0, "Int")/scale
    y := NumGet(point, 4, "Int")/scale
    delta := (wParam >> 16) & 0xFFFF
    if delta >= 0x8000
        delta -= 0x10000
    for key, group in IvoryUI.Groups {
        if key != group.id || !IvoryPageVisible(StrSplit(key, ":")[1])
            continue
        if x >= group.x && x < group.x+232 && y >= group.y && y < group.y+group.height {
            IvoryScrollGroup(key, -delta/120*34)
            return 0
        }
    }
}

IvoryScrollClick(ctrl, *) {
    item := IvoryUI.Items[ctrl.Hwnd]
    group := IvoryUI.Groups[item.group]
    point := IvoryUI.Point(ctrl)
    maxScroll := Max(0, IvoryContentHeight(group)-group.bodyH)
    IvoryScrollGroup(item.group, point.y/Max(1,group.bodyH)*maxScroll, true)
}

IvoryStatusValid(state) {
    if !IsObject(state)
        return false
    for key in ["started", "hold", "fade"] {
        if !state.HasOwnProp(key) || !IsNumber(state.%key%)
            return false
    }
    return state.started >= 0 && state.hold >= 0 && state.fade > 0
}
