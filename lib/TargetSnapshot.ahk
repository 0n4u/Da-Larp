class TargetSnapshot {
    static AdvancedLibrary := 0
    static AdvancedScan := 0
    static Library := 0
    static Scan := 0
    static DC := 0
    static Bitmap := 0
    static PreviousBitmap := 0
    static Pixels := 0
    static Width := 0
    static Height := 0

    static Init() {
        if this.Scan
            return
        if A_PtrSize != 8
            throw Error("The included targeting scanner requires AutoHotkey64.exe")
        path := A_ScriptDir "\..\runtime\TargetScan.dll"
        this.Library := DllCall("kernel32\LoadLibraryExW", "Str", path, "Ptr", 0, "UInt", 0x1100, "Ptr")
        if !this.Library
            throw OSError(, "TargetScan.dll could not be loaded; extract the complete project")
        this.Scan := DllCall("kernel32\GetProcAddress", "Ptr", this.Library, "AStr", "ScanPixels", "Ptr")
        if !this.Scan {
            DllCall("kernel32\FreeLibrary", "Ptr", this.Library)
            this.Library := 0
            throw Error("TargetScan.dll is missing ScanPixels")
        }
        OnExit(ObjBindMethod(this, "Shutdown"))
    }

    static ReleaseFrame() {
        if this.DC && this.PreviousBitmap
            DllCall("gdi32\SelectObject", "Ptr", this.DC, "Ptr", this.PreviousBitmap, "Ptr")
        if this.Bitmap
            DllCall("gdi32\DeleteObject", "Ptr", this.Bitmap)
        if this.DC
            DllCall("gdi32\DeleteDC", "Ptr", this.DC)
        this.DC := 0, this.Bitmap := 0, this.PreviousBitmap := 0, this.Pixels := 0
        this.Width := 0, this.Height := 0
    }

    static Capture(left, top, right, bottom) {
        this.Init()
        width := right-left+1, height := bottom-top+1
        if width <= 0 || height <= 0 || width > 32768 || height > 32768 || width*height > 33554432
            throw Error("Invalid targeting capture bounds")
        screen := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
        if !screen
            throw OSError()
        try {
            if !this.DC || width != this.Width || height != this.Height {
                this.ReleaseFrame()
                this.DC := DllCall("gdi32\CreateCompatibleDC", "Ptr", screen, "Ptr")
                info := Buffer(40, 0)
                NumPut("UInt", 40, "Int", width, "Int", -height, "UShort", 1, "UShort", 32, info)
                frameBits := 0
                this.Bitmap := DllCall("gdi32\CreateDIBSection", "Ptr", screen, "Ptr", info, "UInt", 0,
                    "Ptr*", &frameBits, "Ptr", 0, "UInt", 0, "Ptr")
                this.Pixels := frameBits
                if !this.DC || !this.Bitmap || !frameBits {
                    this.ReleaseFrame()
                    throw OSError()
                }
                this.PreviousBitmap := DllCall("gdi32\SelectObject", "Ptr", this.DC, "Ptr", this.Bitmap, "Ptr")
                if !this.PreviousBitmap || this.PreviousBitmap = -1 {
                    this.PreviousBitmap := 0
                    this.ReleaseFrame()
                    throw OSError()
                }
                this.Width := width, this.Height := height
            }
            started := MonotonicMs()
            if !DllCall("gdi32\BitBlt", "Ptr", this.DC, "Int", 0, "Int", 0, "Int", width, "Int", height,
                "Ptr", screen, "Int", left, "Int", top, "UInt", 0x40CC0020, "Int")
                throw OSError()
            if !DllCall("gdi32\GdiFlush", "Int")
                throw OSError()
            return {left:left, top:top, width:width, height:height, tick:started, pixels:this.Pixels}
        } finally DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", screen)
    }

    static Find(frame, field, refX, refY, colors, tolerances, support, &outX, &outY, &colorIndex,
        bounds := unset, preferred := -1) {
        if !IsSet(bounds)
            bounds := [frame.left, frame.top, frame.left+frame.width-1, frame.top+frame.height-1]
        arguments := Buffer(112, 0)
        NumPut("Ptr", frame.pixels, arguments, 0)
        values := [frame.width, frame.height, frame.left, frame.top, field[1], field[2], field[3], field[4],
            field[5] = "rectangle" ? 0 : 1, Round(refX), Round(refY), colors[1], colors[2], colors[3],
            tolerances[1], tolerances[2], tolerances[3], support, preferred, bounds[1], bounds[2], bounds[3], bounds[4]]
        for fieldSlot, value in values
            NumPut("Int", value, arguments, 4+fieldSlot*4)
        result := DllCall(this.Scan, "Ptr", arguments, "Int")
        if result < 0
            throw Error("Invalid targeting scan parameters")
        if !result
            return false
        outX := NumGet(arguments, 100, "Int")
        outY := NumGet(arguments, 104, "Int")
        colorIndex := NumGet(arguments, 108, "Int")
        return true
    }

    static InitAdvanced() {
        if this.AdvancedScan
            return
        path := A_ScriptDir "\..\runtime\TargetScanAdvanced.dll"
        this.AdvancedLibrary := DllCall("kernel32\LoadLibraryExW", "Str", path, "Ptr", 0, "UInt", 0x1100, "Ptr")
        if !this.AdvancedLibrary
            throw Error("TargetScanAdvanced.dll is missing; extract the full v13.6 archive")
        this.AdvancedScan := DllCall("kernel32\GetProcAddress", "Ptr", this.AdvancedLibrary,
            "AStr", "ScanAdvanced", "Ptr")
        if !this.AdvancedScan
            throw Error("TargetScanAdvanced.dll does not expose ScanAdvanced")
    }

    static AdvancedFind(frame, field, refX, refY, colors, tolerances, support,
        &outX, &outY, &colorIndex, bounds, preferred := -1) {
        this.InitAdvanced()
        options := WorkerOptions()
        shapeName := StrLower(field[5])
        shapes := ["circle", "ellipse", "rectangle", "triangle", "diamond", "pentagon",
            "hexagon", "heptagon", "octagon", "decagon", "star", "heart", "cross", "shield"]
        shape := 2
        for shapeIndex, name in shapes {
            if name = shapeName {
                shape := shapeIndex-1
                break
            }
        }
        data := Buffer(128, 0)
        NumPut("Ptr", frame.pixels, data, 0)
        values := [frame.width,frame.height,frame.left,frame.top,Round(field[1]),Round(field[2]),
            Round(field[3]),Round(field[4]),shape,Round(refX),Round(refY),colors[1],colors[2],colors[3],
            tolerances[1],tolerances[2],tolerances[3],support,preferred,
            bounds[1],bounds[2],bounds[3],bounds[4],
            options["BackgroundReject"] ? (options["BackgroundMode"] = "strict" ? 2 : 1) : 0,
            options["BackgroundFillLimit"],
            this.SampleStep(frame.width, frame.height)]
        for parameterIndex, parameterValue in values
            NumPut("Int", parameterValue, data, 4+parameterIndex*4)
        outcome := DllCall(this.AdvancedScan, "Ptr", data, "Int")
        if outcome < 0
            throw Error("Advanced scanner rejected its parameters")
        if !outcome
            return false
        outX := NumGet(data,112,"Int")
        outY := NumGet(data,116,"Int")
        colorIndex := NumGet(data,120,"Int")
        return true
    }

    static SampleStep(width, height) {
        if width < 1 || height < 1
            throw Error("Invalid capture size for scanner")
        area := width*height
        step := area > 150000 ? 3 : area > 25000 ? 2 : 1
        return Min(4,Max(step,Ceil(width/512),Ceil(height/512)))
    }

    static Shutdown(*) {
        if this.AdvancedLibrary
            DllCall("kernel32\FreeLibrary", "Ptr", this.AdvancedLibrary)
        this.AdvancedLibrary := 0, this.AdvancedScan := 0
        this.ReleaseFrame()
        if this.Library
            DllCall("kernel32\FreeLibrary", "Ptr", this.Library)
        this.Library := 0, this.Scan := 0
    }
}
