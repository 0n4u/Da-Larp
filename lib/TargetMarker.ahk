class TargetMarker {
    static Window := 0
    static Enabled := false
    static Requested := false
    static Color := 0xFAB387
    static PreferredColor := 0xFAB387
    static Size := 5
    static LastFrame := ""
    static LastColorRefresh := -10000
    static ConfigPath := ""
    static StateDir := ""

    static Init(section, path := unset, stateDir := unset) {
        if !IsSet(path)
            path := A_ScriptDir "\..\config\settings.ini"
        if !IsSet(stateDir)
            stateDir := A_ScriptDir "\..\state"
        this.ConfigPath := path
        this.StateDir := stateDir
        this.Requested := IniRead(path, section, "TargetDot", 0) = 1
        this.Enabled := this.Requested
        if !this.Requested
            return
        value := IniRead(path, section, "DotColor", "0xFAB387")
        this.PreferredColor := RegExMatch(value, "i)^0x[0-9a-f]{6}$") ? value+0 : 0xFAB387
        size := IniRead(path, section, "DotSize", 5)
        this.Size := IsNumber(size) ? Min(16, Max(2, Round(size+0))) : 5
        this.RefreshColor(true)
        OnExit(ObjBindMethod(this, "Shutdown"))
    }

    static RefreshColor(force := false) {
        if !this.Requested
            return
        now := MonotonicMs()
        if !force && now-this.LastColorRefresh < 250
            return
        targets := OverlayTargetColors(this.ConfigPath,this.StateDir,true)
        nextColor := FovSafeColor(this.PreferredColor,255,targets)
        this.LastColorRefresh := now
        if nextColor < 0 {
            this.Hide()
            this.Enabled := false
            WorkerSignalIssue("marker-color-conflict", "target marker has no safe color")
            return
        }
        if nextColor != this.Color || !this.Enabled {
            this.Hide()
            this.Color := nextColor
            if IsObject(this.Window)
                this.Window.BackColor := Format("{:06X}",this.Color)
        }
        this.Enabled := true
    }

    static Show(x, y) {
        this.RefreshColor()
        if !this.Enabled
            return
        if !WorkerInputAllowed() || !WinActive("ahk_exe RobloxPlayerBeta.exe") {
            this.Hide()
            return
        }
        if !IsObject(this.Window) {
            this.Window := Gui("-Owner -Caption -Border -DPIScale +AlwaysOnTop +ToolWindow +E0x08080020", "Da Larp target")
            this.Window.BackColor := Format("{:06X}", this.Color)
            region := DllCall("gdi32\CreateEllipticRgn", "Int", 0, "Int", 0, "Int", this.Size, "Int", this.Size, "Ptr")
            if !region || !DllCall("user32\SetWindowRgn", "Ptr", this.Window.Hwnd, "Ptr", region, "Int", true, "Int") {
                if region
                    DllCall("gdi32\DeleteObject", "Ptr", region)
                this.Window.Destroy()
                this.Window := 0
                this.Enabled := false
                WorkerSignalIssue("marker-unavailable", "cannot create the target marker region")
                return
            }
            if !DllCall("user32\SetLayeredWindowAttributes", "Ptr", this.Window.Hwnd, "UInt", 0, "UChar", 255, "UInt", 2, "Int") {
                this.Window.Destroy()
                this.Window := 0
                this.Enabled := false
                WorkerSignalIssue("marker-unavailable", "cannot set target marker opacity")
                return
            }
        }
        CaptureApply(this.Window.Hwnd, WorkerOptions()["CaptureExcluded"])
        left := Round(x-this.Size/2), top := Round(y-this.Size/2)
        signature := left "," top
        if signature = this.LastFrame
            return
        if !DllCall("user32\SetWindowPos", "Ptr", this.Window.Hwnd, "Ptr", -1, "Int", left, "Int", top,
            "Int", this.Size, "Int", this.Size, "UInt", 0x50, "Int") {
            this.Hide()
            WorkerSignalIssue("marker-unavailable", "cannot position the target marker")
            return
        }
        this.LastFrame := signature
    }

    static Hide() {
        if IsObject(this.Window) && this.LastFrame != ""
            this.Window.Hide()
        this.LastFrame := ""
    }

    static Shutdown(*) {
        if IsObject(this.Window)
            this.Window.Destroy()
        this.Window := 0
    }
}
