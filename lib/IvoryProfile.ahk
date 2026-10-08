IvoryEnsureProfile() {
    UserProfile.Current := UserProfile.Load()
    loop {
        if !IsObject(UserProfile.Current) {
            if !IvoryProfileSetup()
                ExitApp()
            continue
        }
        choice := IvoryProfileGate()
        if choice = "load" {
            try UserProfile.RecordLogin()
            catch as err
                MsgBox("Your profile loaded, but the last-login timestamp could not be saved.`n" err.Message,
                    "Da Larp", "Icon!")
            UserProfile.Ready := true
            IvoryRefreshProfile()
            return
        }
        if choice = "edit" {
            IvoryProfileSetup(true)
            continue
        }
        ExitApp()
    }
}

IvoryRefreshProfile() {
    global UI
    if UI.Has("ToolbarProfile") && IsObject(UserProfile.Current) {
        UI["ToolbarProfile"].Text := UserProfile.Current.username
        IvoryUI.Redraw(UI["ToolbarProfile"])
    }
}

IvoryEditProfile(*) {
    if !UserProfile.Ready || IsObject(UserProfile.Dialog)
        return
    IvoryUI.ClosePopup()
    if IvoryProfileSetup(true) {
        IvoryRefreshProfile()
        SetStatus("profile saved", "ok")
    }
}

IvoryProfileWindow(width, height) {
    global MainGui, APP_NAME
    dialog := Gui("+Owner" MainGui.Hwnd " -Caption -Border -DPIScale +ToolWindow", APP_NAME " profile")
    dialog.MarginX := 0, dialog.MarginY := 0
    dialog.BackColor := "141414"
    monitor := MonitorGetPrimary()
    if UserProfile.Ready {
        MainGui.GetPos(&menuX, &menuY)
        monitor := MonitorFromPoint(menuX, menuY)
    }
    MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
    dpi := Max(96, DllCall("user32\GetDpiForWindow", "Ptr", dialog.Hwnd, "UInt"))/96
    scale := Max(0.25, Min(dpi, (right-left-24)/width, (bottom-top-24)/height))
    IvoryUI.PixelScales[dialog.Hwnd] := scale
    dialog.SetFont("s" (9*scale/dpi) " cFFFFFF", "Tahoma")
    UserProfile.Dialog := dialog
    return {gui: dialog, hwnd: dialog.Hwnd, scale: scale, width: width, height: height,
        area: [left,top,right,bottom], handles: [], closing: false, action: "exit"}
}

IvoryProfileAdd(window, kind, x, y, w, h, label := "", callback := 0) {
    control := IvoryUI.Add(window.gui, kind, x, y, w, h, label, "", callback)
    window.handles.Push(control.Hwnd)
    return control
}

IvoryProfileShow(window, focus := 0) {
    global MainGui
    gui := window.gui, scale := window.scale
    MainGui.Opt("+Disabled")
    try {
        gui.Show("Hide w" Round(window.width*scale) " h" Round(window.height*scale))
        gui.GetPos(,, &realW, &realH)
        area := window.area
        gui.Show("x" Round(area[1]+(area[3]-area[1]-realW)/2)
            " y" Round(area[2]+(area[4]-area[2]-realH)/2))
        if IsObject(focus)
            focus.Focus()
        WinWaitClose("ahk_id " window.hwnd)
    } finally {
        MainGui.Opt("-Disabled")
        for hwnd in window.handles {
            if IvoryUI.Hover = hwnd
                IvoryUI.Hover := 0
            if IvoryUI.Items.Has(hwnd)
                IvoryUI.Items.Delete(hwnd)
            if IvoryUI.PaintCounts.Has(hwnd)
                IvoryUI.PaintCounts.Delete(hwnd)
        }
        if IvoryUI.PixelScales.Has(window.hwnd)
            IvoryUI.PixelScales.Delete(window.hwnd)
        UserProfile.Dialog := 0
        if UserProfile.Ready
            try WinActivate("ahk_id " MainGui.Hwnd)
    }
    return window.action
}

IvoryProfileClose(window, action, *) {
    if window.closing
        return
    window.closing := true
    window.action := action
    IvoryQueueDestroyGui(window.gui)
}

IvoryProfileGate() {
    global APP_NAME
    window := IvoryProfileWindow(356, 286)
    IvoryProfileAdd(window, "profile-bg", 0, 0, 356, 286)
    IvoryProfileAdd(window, "profile-titlebar", 0, 0, 356, 36, APP_NAME "  /  profile")
    IvoryProfileAdd(window, "profile-heading", 30, 53, 296, 23, "Choose your profile")
    avatar := IvoryProfileAdd(window, "profile-avatar", 150, 84, 56, 56,
        "", IvoryProfileClose.Bind(window, "edit"))
    IvoryUI.Items[avatar.Hwnd].avatarPath := UserProfile.Current.avatar
    IvoryUI.Items[avatar.Hwnd].initial := SubStr(UserProfile.Current.username, 1, 1)
    IvoryProfileAdd(window, "profile-meta", 22, 162, 312, 19,
        "LAST LOGIN  /  " (UserProfile.Current.lastLogin = "" ? "NEVER"
            : FormatTime(UserProfile.Current.lastLogin, "MMM d, yyyy  h:mm tt")))
    IvoryProfileAdd(window, "profile-selector", 22, 190, 234, 35,
        UserProfile.Current.username, IvoryProfileClose.Bind(window, "edit"))
    IvoryProfileAdd(window, "profile-button-primary", 266, 190, 68, 35,
        "Load", IvoryProfileClose.Bind(window, "load"))
    IvoryProfileAdd(window, "profile-button", 22, 242, 120, 31,
        "Edit profile", IvoryProfileClose.Bind(window, "edit"))
    IvoryProfileAdd(window, "profile-button", 262, 242, 72, 31,
        "Exit", IvoryProfileClose.Bind(window, "exit"))
    IvoryProfileAdd(window, "profile-close", 323, 5, 25, 25,
        "×", IvoryProfileClose.Bind(window, "exit"))
    window.gui.OnEvent("Close", IvoryProfileClose.Bind(window, "exit"))
    window.gui.OnEvent("Escape", IvoryProfileClose.Bind(window, "exit"))
    return IvoryProfileShow(window)
}

IvoryProfileSetup(editing := false) {
    global APP_NAME
    window := IvoryProfileWindow(390, 390)
    window.action := "cancel"
    IvoryProfileAdd(window, "profile-bg", 0, 0, 390, 390)
    headerLabel := editing ? APP_NAME "  /  edit profile" : APP_NAME "  /  new profile"
    IvoryProfileAdd(window, "profile-titlebar", 0, 0, 390, 36, headerLabel)
    IvoryProfileAdd(window, "profile-heading", 24, 52, 342, 24,
        editing ? "Customize your profile" : "Create your profile")
    IvoryProfileAdd(window, "profile-muted", 24, 81, 342, 20,
        editing ? "Change your name or picture." : "Choose a name and profile picture.")
    current := IsObject(UserProfile.Current) ? UserProfile.Current : 0
    pictureState := {path: IsObject(current) ? current.avatar : ""}
    avatar := IvoryProfileAdd(window, "profile-avatar", 167, 112, 56, 56,
        "", IvoryProfileChooseAvatar.Bind(window, pictureState))
    IvoryUI.Items[avatar.Hwnd].avatarPath := pictureState.path
    IvoryUI.Items[avatar.Hwnd].initial := IsObject(current) ? SubStr(current.username, 1, 1) : "?"
    pictureState.control := avatar
    IvoryProfileAdd(window, "profile-button", 117, 178, 156, 28,
        "Choose picture", IvoryProfileChooseAvatar.Bind(window, pictureState))
    IvoryProfileAdd(window, "profile-label", 24, 222, 342, 18, "USERNAME")
    IvoryProfileAdd(window, "profile-input", 24, 246, 342, 39)
    edit := window.gui.Add("Edit", "x" Round(33*window.scale) " y" Round(252*window.scale)
        " w" Round(324*window.scale) " h" Round(28*window.scale)
        " Background17191D cFFFFFF -E0x200 Limit32",
        IsObject(current) ? current.username : "")
    IvoryUI.Raise(edit)
    DllCall("user32\SendMessageW", "Ptr", edit.Hwnd, "UInt", 0x1501, "Ptr", 1,
        "WStr", "your name (not your real name)", "Ptr")
    hint := IvoryProfileAdd(window, "profile-muted", 24, 296, 342, 24,
        "1-32 characters  ·  Letters, numbers, spaces, . _ -")
    IvoryProfileAdd(window, "profile-button-primary", 24, 341, 150, 33,
        editing ? "Save profile" : "Create profile",
        IvoryProfileSubmit.Bind(window, edit, hint, pictureState))
    IvoryProfileAdd(window, "profile-button", 274, 341, 92, 33,
        editing ? "Cancel" : "Exit", IvoryProfileClose.Bind(window, "cancel"))
    IvoryProfileAdd(window, "profile-close", 357, 5, 25, 25,
        "×", IvoryProfileClose.Bind(window, "cancel"))
    window.gui.OnEvent("Close", IvoryProfileClose.Bind(window, "cancel"))
    window.gui.OnEvent("Escape", IvoryProfileClose.Bind(window, "cancel"))
    onEnter := IvoryProfileEnter.Bind(window, edit, hint, pictureState)
    OnMessage(0x100, onEnter)
    try action := IvoryProfileShow(window, edit)
    finally OnMessage(0x100, onEnter, 0)
    return action = "saved"
}

IvoryProfileChooseAvatar(window, pictureState, *) {
    if window.closing
        return
    source := FileSelect(1, , "Choose a profile picture", "Images (*.png; *.jpg; *.jpeg; *.bmp; *.gif)")
    if source = ""
        return
    try UserProfile.CheckAvatar(source)
    catch as err {
        MsgBox(err.Message, "Profile picture", "Icon!")
        return
    }
    pictureState.path := source
    IvoryUI.Items[pictureState.control.Hwnd].avatarPath := source
    IvoryUI.Redraw(pictureState.control)
}

IvoryProfileEnter(window, edit, hint, pictureState, key, lParam, msg, hwnd) {
    if key = 13 && hwnd = edit.Hwnd {
        IvoryProfileSubmit(window, edit, hint, pictureState)
        return 0
    }
}

IvoryProfileSubmit(window, edit, hint, pictureState, *) {
    if window.closing
        return
    try {
        name := UserProfile.Name(edit.Value)
        UserProfile.Current := UserProfile.Save(name, UserProfile.Path, pictureState.path)
    } catch as err {
        hint.Text := err.Message
        IvoryUI.Items[hint.Hwnd].color := 0xE98995
        IvoryUI.Redraw(hint)
        edit.Focus()
        return
    }
    IvoryProfileClose(window, "saved")
}
