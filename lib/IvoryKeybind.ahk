IvoryKeyPrompt(ctrl) {
    global MainGui
    if IvoryKeyCaptureActive()
        return {Result: "Cancel", Value: ctrl.Text}
    IvoryUI.ClosePopup()
    item := IvoryUI.Items[ctrl.Hwnd]
    current := Cfg(item.section, item.key, "")
    dialog := Gui("+Owner" MainGui.Hwnd " -Caption +Border +ToolWindow +AlwaysOnTop", "Set keybind")
    dialog.BackColor := "141414"
    state := {gui: dialog, item: item, result: {Result: "Cancel", Value: current},
        handles: [], keyboard: 0, mouseNames: [], ignored: Map(), phase: "opening",
        source: "", value: "", vk: 0, sc: 0, restoreFocus: true}
    IvoryUI.KeyCapture := state
    try {
        for spec in [["panel",0,0,380,148,""], ["bar",2,2,376,24,""],
            ["label",10,4,358,20,"Set keybind · " item.label],
            ["label",12,41,356,20,"Press a keyboard key or mouse button."],
            ["label",12,65,356,18,"Current: " current],
            ["label",12,88,356,18,"Esc cancels · Del clears · release to save"]] {
            added := IvoryUI.Add(dialog, spec*)
            state.handles.Push(added.Hwnd)
        }
        state.detail := IvoryUI.Items[state.handles[4]].ctrl
        state.status := IvoryUI.Items[state.handles[6]].ctrl
        state.cancel := IvoryUI.Add(dialog, "button", 286, 116, 82, 24, "Cancel", "", IvoryCaptureCancel)
        state.handles.Push(state.cancel.Hwnd)
        dialog.OnEvent("Close", IvoryCaptureCancel)
        dialog.OnEvent("Escape", IvoryCaptureCancel)
        MainGui.Opt("+Disabled")
        MainGui.GetPos(&x, &y, &w, &h)
        s := IvoryUI.Scale
        dialog.Show("Hide w" Round(380*s) " h" Round(148*s))
        dialog.GetPos(,, &dw, &dh)
        MonitorGetWorkArea(MonitorFromPoint(x, y), &ml, &mt, &mr, &mb)
        dialog.Show("x" Max(ml, Min(mr-dw, Round(x+(w-dw)/2)))
            " y" Max(mt, Min(mb-dh, Round(y+(h-dh)/2))))

        Loop 255 {
            if GetKeyState(Format("vk{:02X}", A_Index), "P")
                state.ignored["vk" A_Index] := true
        }
        for name in ["LButton", "RButton", "MButton", "XButton1", "XButton2"] {
            if GetKeyState(name, "P")
                state.ignored[name] := true
        }
        keyboard := InputHook("L0 I1 T30")
        keyboard.VisibleNonText := false
        keyboard.KeyOpt("{All}", "SN")
        keyboard.OnKeyDown := IvoryCaptureKeyDown
        keyboard.OnKeyUp := IvoryCaptureKeyUp
        keyboard.OnEnd := IvoryCaptureEnded
        state.keyboard := keyboard
        HotIf(IvoryCaptureMouseContext)
        try {
            for name in ["LButton", "RButton", "MButton", "XButton1", "XButton2"] {
                Hotkey("$*" name, IvoryCaptureMouseDown.Bind(name), "On I1")
                state.mouseNames.Push("$*" name)
                Hotkey("$*" name " up", IvoryCaptureMouseUp.Bind(name), "On I1")
                state.mouseNames.Push("$*" name " up")
            }

            for name in ["WheelUp", "WheelDown", "WheelLeft", "WheelRight"] {
                Hotkey("$*" name, IvoryCaptureWheel, "On I1")
                state.mouseNames.Push("$*" name)
            }
        } finally HotIf()
        state.phase := "waiting"
        keyboard.Start()
        WinWaitClose("ahk_id " dialog.Hwnd)
    } catch {
        SetStatus("key capture unavailable · binding unchanged", "error")
    } finally {
        if IsObject(IvoryUI.KeyCapture) && IvoryUI.KeyCapture = state
            IvoryCaptureFinish("Cancel")
        HotIf(IvoryCaptureMouseContext)
        try {
            for name in state.mouseNames
                Hotkey(name, "Off")
        } finally HotIf()
        MainGui.Opt("-Disabled")
        for handle in state.handles {
            if IvoryUI.Items.Has(handle)
                IvoryUI.Items.Delete(handle)
            if IvoryUI.PaintCounts.Has(handle)
                IvoryUI.PaintCounts.Delete(handle)
        }
        if state.restoreFocus && IvoryMenuVisible() && !WinActive("ahk_id " MainGui.Hwnd)
            try WinActivate("ahk_id " MainGui.Hwnd)
    }
    return state.result
}

IvoryKeyCaptureActive() {
    return IsObject(IvoryUI.KeyCapture)
}

IvoryCaptureMouseContext(*) {
    return IvoryKeyCaptureActive() && IvoryUI.KeyCapture.phase != "opening"
        && WinActive("ahk_id " IvoryUI.KeyCapture.gui.Hwnd)
}

IvoryCaptureKeyDown(keyboard, vk, sc) {
    if !IvoryKeyCaptureActive() || IvoryUI.KeyCapture.keyboard != keyboard
        return
    state := IvoryUI.KeyCapture
    if vk = 0x1B {
        IvoryCaptureCancel()
        return
    }
    if vk = 0x2E && state.phase = "waiting" {
        IvoryCaptureFinish("OK", "")
        return
    }
    if state.phase != "waiting" || state.ignored.Has("vk" vk)
        return
    name := GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    if !IvoryCaptureCandidate(name) {
        state.ignored["vk" vk] := true
        return
    }
    state.source := "keyboard"
    state.vk := vk
    state.sc := sc
}

IvoryCaptureKeyUp(keyboard, vk, sc) {
    if !IvoryKeyCaptureActive() || IvoryUI.KeyCapture.keyboard != keyboard
        return
    state := IvoryUI.KeyCapture
    if state.ignored.Has("vk" vk)
        state.ignored.Delete("vk" vk)
    if state.phase = "release" && state.source = "keyboard" && state.vk = vk && state.sc = sc
        IvoryCaptureFinish("OK", state.value)
}

IvoryCaptureMouseDown(name, *) {
    if !IvoryKeyCaptureActive()
        return
    state := IvoryUI.KeyCapture
    if state.phase != "waiting" || state.ignored.Has(name)
        return
    if name = "LButton" {
        point := Buffer(8)
        DllCall("user32\GetCursorPos", "Ptr", point)
        hwnd := DllCall("user32\WindowFromPoint", "Int64", NumGet(point, 0, "Int64"), "Ptr")
        if hwnd = state.cancel.Hwnd {
            state.phase := "cancelmouse"
            return
        }
    }
    if IvoryCaptureCandidate(name)
        state.source := "mouse"
    else
        state.ignored[name] := true
}

IvoryCaptureMouseUp(name, *) {
    if !IvoryKeyCaptureActive()
        return
    state := IvoryUI.KeyCapture
    if state.ignored.Has(name)
        state.ignored.Delete(name)
    if state.phase = "cancelmouse" && name = "LButton"
        IvoryCaptureCancel()
    else if state.phase = "release" && state.source = "mouse" && state.value = name
        IvoryCaptureFinish("OK", name)
}

IvoryCaptureWheel(*) {
    if IvoryKeyCaptureActive() && IvoryUI.KeyCapture.phase = "waiting"
        IvoryCaptureMessage("Use a keyboard key or held mouse button.")
}

IvoryCaptureCandidate(name) {
    state := IvoryUI.KeyCapture
    if name = "" || !IsValidKeyName(name) {
        IvoryCaptureMessage("That input has no supported Windows key name.")
        return false
    }
    if StrLower(name) = "f10" {
        IvoryCaptureMessage("F10 opens the menu. Press another key.")
        return false
    }
    conflict := GlobalHotkeyConflict(state.item.section, state.item.key, name)
    if conflict != "" {
        IvoryCaptureMessage("Already used by " conflict ". Try another key.")
        return false
    }
    state.value := name
    state.phase := "release"
    state.detail.Text := "Release " name " to save."
    state.status.Text := "Esc cancels · waiting for release"
    IvoryUI.Redraw(state.detail)
    IvoryUI.Redraw(state.status)
    return true
}

IvoryCaptureMessage(message) {
    state := IvoryUI.KeyCapture
    state.status.Text := message
    IvoryUI.Redraw(state.status)
}

IvoryCaptureCancel(*) {
    IvoryCaptureFinish("Cancel")
}

IvoryCaptureEnded(keyboard) {
    if IvoryKeyCaptureActive() && IvoryUI.KeyCapture.keyboard = keyboard
        IvoryCaptureCancel()
}

IvoryCaptureLostFocus(hwnd) {
    if IvoryKeyCaptureActive() && IvoryUI.KeyCapture.gui.Hwnd = hwnd {
        IvoryUI.KeyCapture.restoreFocus := false
        IvoryCaptureCancel()
    }
}

IvoryCaptureFinish(action, value := "") {
    if !IvoryKeyCaptureActive()
        return
    state := IvoryUI.KeyCapture
    IvoryUI.KeyCapture := 0
    state.phase := "closing"
    state.result.Result := action
    if action = "OK"
        state.result.Value := value
    if IsObject(state.keyboard)
        state.keyboard.Stop()
    IvoryQueueDestroyGui(state.gui)
}

IvoryKeyIdentity(value) {
    value := Trim(value)
    if value = ""
        return ""
    try {
        canonical := StrLower(GetKeyName(value))
        if canonical != "" {
            aliases := Map("control","ctrl","lcontrol","lctrl","rcontrol","rctrl")
            return aliases.Has(canonical) ? aliases[canonical] : canonical
        }
    }
    return StrLower(value)
}

IvoryKeysOverlap(first, second) {
    first := IvoryKeyIdentity(first)
    second := IvoryKeyIdentity(second)
    if first = "" || second = ""
        return false
    if first = second
        return true
    for family in [["ctrl","lctrl","rctrl"],["shift","lshift","rshift"],["alt","lalt","ralt"]] {
        if (first = family[1] && (second = family[2] || second = family[3]))
            || (second = family[1] && (first = family[2] || first = family[3]))
            return true
    }
    return false
}
