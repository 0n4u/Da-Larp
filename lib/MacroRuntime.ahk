class MacroGate {
    __New(key, mode := "hold", register := true) {
        if register {
            InstallKeybdHook()
            InstallMouseHook()
        }
        this.Key := key
        this.Mode := mode
        this.Latched := false
        this.Toggled := false
        this.Pending := false
        this.OutputHeld := ""
        this.Epoch := 0
        this.Blocked := GetKeyState(key, "P")
        if register {
            this.DownFn := ObjBindMethod(this, "Down")
            this.UpFn := ObjBindMethod(this, "Up")
            HotIfWinActive("ahk_exe RobloxPlayerBeta.exe")
            try {
                Hotkey("$*" key, this.DownFn)
                Hotkey("$*" key " up", this.UpFn)
            } finally HotIfWinActive()
        }
    }

    Down(*) {
        if !MacroFocused() || this.Blocked || this.Latched || !GetKeyState(this.Key, "P")
            return
        this.Latched := true
        this.Epoch += 1
        if this.Mode = "toggle" {
            this.Toggled := !this.Toggled
        } else if this.Mode = "once"
            this.Pending := true
    }

    Up(*) {
        if this.Latched && this.Mode = "hold"
            this.Epoch += 1
        this.Latched := false
        this.Blocked := false
    }

    Ready(epoch := -1) {
        physical := GetKeyState(this.Key, "P")
        if !MacroFocused() {
            if this.Latched || this.Toggled || this.Pending
                this.Epoch += 1
            this.Latched := false
            this.Toggled := false
            this.Pending := false
            this.Blocked := physical
            return false
        }
        if !physical {
            this.Latched := false
            this.Blocked := false
        }
        if this.Blocked || (epoch >= 0 && epoch != this.Epoch)
            return false
        if this.Mode = "once"
            return true
        return this.Mode = "toggle" ? this.Toggled : this.Latched && physical
    }

    ConsumePress() {
        if !this.Ready() || !this.Pending
            return false
        this.Pending := false
        return true
    }

    Wait(ms, epoch) {
        deadline := MonotonicMs()+Max(0, ms)
        loop {
            if !this.Ready(epoch)
                return false
            remaining := deadline-MonotonicMs()
            if remaining <= 0
                return true
            Sleep(Min(5, Ceil(remaining)))
        }
    }
}

MacroFocused() {
    return !!WinActive("ahk_exe RobloxPlayerBeta.exe") && WorkerInputAllowed()
}

MacroRead(section, key, fallback) {
    global ConfigPath
    return IniRead(ConfigPath, section, key, fallback)
}

MacroNumber(section, key, fallback, low, high, integer := true) {
    value := MacroRead(section, key, fallback)
    if !IsNumber(value)
        return fallback
    value := Min(high, Max(low, value+0))
    return integer ? Round(value) : value
}

MacroChoice(section, key, fallback, choices) {
    value := StrLower(Trim(MacroRead(section, key, fallback)))
    for choice in choices
        if value = choice
            return choice
    return fallback
}

MacroKey(section, key, fallback) {
    value := Trim(MacroRead(section, key, fallback))
    try {
        if GetKeyName(value) != "" && !RegExMatch(value, "i)^Wheel")
            return value
    }
    throw Error("Invalid key: " section "." key)
}

MacroMove(dx, dy) {
    if dx || dy
        DllCall("user32\mouse_event", "UInt", 1, "Int", dx, "Int", dy, "UInt", 0, "UPtr", 0)
}

MacroTap(key, holdMs, gate, epoch) {
    if !gate.Ready(epoch)
        return false
    if GetKeyName(key) = "LButton" && !WorkerAllowsFire()
        return false

    try {
        if !WorkerKeyDown(key)
            return false
        gate.OutputHeld := key
        return gate.Wait(holdMs, epoch)
    } finally {
        try WorkerKeyUp(key)
        finally gate.OutputHeld := ""
    }
}
