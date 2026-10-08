class IvoryUI {
    static Items := Map()
    static Brushes := Map()
    static Fonts := Map()
    static PixelScales := Map()
    static Groups := Map()
    static Rows := Map()
    static Hover := 0
    static Drag := 0
    static ScrollDrag := 0
    static Popup := 0
    static PopupSource := 0
    static PopupHandles := []
    static Theme := "Ivory"
    static Accent := 0xFFFFFF
    static Main := 0
    static PaintCounts := Map()
    static Scale := 0.8
    static Toolbar := 0
    static ToolbarBaseScale := 0.8
    static ToolbarButtons := Map()
    static ToolbarOrder := []
    static ToolbarEnabled := false
    static ToolbarMonitor := 0
    static ToolbarHook := 0
    static ToolbarHookCallback := 0
    static ToolbarListening := false
    static ToolbarPositioning := false
    static ToolbarAnimating := false
    static AnimationTime := 0
    static AnimationStarted := 0
    static AppBarMessage := 0
    static TaskbarMessage := 0
    static AppBarRegistered := false
    static AppBarRect := 0
    static AppBarDesired := ""
    static AppBarDirty := true
    static AppBarFailed := false
    static KeyCapture := 0
    static StatusMessage := 0
    static FontPath := ""
    static AvatarGdiToken := 0

    static Init(gui) {
        this.Main := gui
        this.AnimationStarted := DllCall("kernel32\GetTickCount64", "UInt64")
        this.FontPath := A_ScriptDir "\assets\fonts\ivory-tahoma.ttf"
        if FileExist(this.FontPath)
            DllCall("gdi32\AddFontResourceExW", "Str", this.FontPath, "UInt", 0x10, "Ptr", 0)
        this.SubclassHandler := CallbackCreate(ObjBindMethod(this, "Subclass"), , 6)
        this.DrawHandler := ObjBindMethod(this, "Draw")
        this.MoveHandler := ObjBindMethod(this, "MouseMove")
        this.DownHandler := ObjBindMethod(this, "MouseDown")
        this.UpHandler := ObjBindMethod(this, "MouseUp")
        this.KeyHandler := ObjBindMethod(this, "KeyDown")
        this.CancelHandler := ObjBindMethod(this, "CancelCapture")
        this.DoubleHandler := ObjBindMethod(this, "DoubleClick")
        this.ActivateHandler := ObjBindMethod(this, "Activate")
        OnMessage(0x2B, this.DrawHandler)
        OnMessage(0x200, this.MoveHandler)
        OnMessage(0x201, this.DownHandler)
        OnMessage(0x202, this.UpHandler)
        OnMessage(0x100, this.KeyHandler)
        OnMessage(0x215, this.CancelHandler)
        OnMessage(0x203, this.DoubleHandler)
        OnMessage(0x6, this.ActivateHandler)
        OnMessage(0x20A, IvoryMouseWheel)
        OnExit(ObjBindMethod(this, "Cleanup"))
    }

    static Add(gui, kind, x, y, w, h, text := "", label := "", callback := 0, hidden := false) {
        IvoryApplyCapture(gui.Hwnd)
        clickable := IsObject(callback)
        scale := this.PixelScales.Has(gui.Hwnd) ? this.PixelScales[gui.Hwnd] : this.Scale
        options := ("x" Round(x*scale) " y" Round(y*scale)
            " w" Max(1, Round(w*scale)) " h" Max(1, Round(h*scale))
            " +0x4000000 " (hidden ? "Hidden " : ""))

        ctrl := gui.Add(clickable ? "Button" : "Text", options (clickable ? "-Wrap" : "+0xD"), text)

        DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Str", "")
        item := {ctrl: ctrl, kind: kind, label: label, color: 0xFFFFFF, textAlpha: 255, selected: false,
            callback: callback, page: "", group: "", tab: "", section: "", key: "", pending: "",
            min: "", max: "", choices: "", module: ""}
        item.x := x
        item.y := y
        item.w := w
        item.h := h
        item.row := -1
        item.inline := false
        item.pinned := false
        item.animated := false
        item.selectionBlend := 0
        item.hoverBlend := 0
        item.pulsing := false
        item.scrolling := false
        item.changedAt := 0
        this.Items[ctrl.Hwnd] := item
        if !DllCall("comctl32\SetWindowSubclass", "Ptr", ctrl.Hwnd, "Ptr", this.SubclassHandler,
            "UPtr", 0x4956, "UPtr", 0, "Int")
            throw OSError()
        if clickable
            SendMessage(0xF4, 0xB, 1, ctrl)
        if this.PaintCounts.Has(ctrl.Hwnd)
            this.PaintCounts.Delete(ctrl.Hwnd)
        this.Raise(ctrl)
        if clickable
            ctrl.OnEvent("Click", callback)
        return ctrl
    }

    static Subclass(hwnd, msg, wParam, lParam, subclassId, refData) {
        Critical("On")
        if msg = 0x82 {
            DllCall("comctl32\RemoveWindowSubclass", "Ptr", hwnd, "Ptr", this.SubclassHandler, "UPtr", subclassId)
            return DllCall("comctl32\DefSubclassProc", "Ptr", hwnd, "UInt", msg, "Ptr", wParam, "Ptr", lParam, "Ptr")
        }
        if msg = 0xF4 && this.Items.Has(hwnd) && IsObject(this.Items[hwnd].callback)
            wParam := 0xB
        if this.Items.Has(hwnd) {
            if msg = 0x14
                return 1
            if msg = 0xF {
                ps := Buffer(A_PtrSize = 8 ? 72 : 64, 0)
                dc := DllCall("user32\BeginPaint", "Ptr", hwnd, "Ptr", ps, "Ptr")
                try this.Paint(hwnd, dc)
                finally DllCall("user32\EndPaint", "Ptr", hwnd, "Ptr", ps)
                return 0
            }
            if msg = 0x318 {
                this.Paint(hwnd, wParam)
                return 0
            }
        }
        return DllCall("comctl32\DefSubclassProc", "Ptr", hwnd, "UInt", msg, "Ptr", wParam, "Ptr", lParam, "Ptr")
    }

    static Raise(ctrl) {

        if !DllCall("user32\SetWindowPos", "Ptr", ctrl.Hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13)
            throw OSError()
    }

    static Redraw(ctrl) {
        if IsObject(ctrl)
            DllCall("user32\InvalidateRect", "Ptr", ctrl.Hwnd, "Ptr", 0, "Int", false)
    }

    static ControlScale(ctrl) {
        hwnd := ctrl.Gui.Hwnd
        if this.PixelScales.Has(hwnd)
            return this.PixelScales[hwnd]
        return Max(96, DllCall("user32\GetDpiForWindow", "Ptr", ctrl.Hwnd, "UInt"))/96*this.Scale
    }

    static Brush(rgb) {
        if !this.Brushes.Has(rgb) {
            bgr := ((rgb & 255) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 255)
            this.Brushes[rgb] := DllCall("gdi32\CreateSolidBrush", "UInt", bgr, "Ptr")
        }
        return this.Brushes[rgb]
    }

    static Fill(dc, x, y, w, h, rgb) {
        if w <= 0 || h <= 0
            return
        rect := Buffer(16)
        NumPut("Int", Round(x), "Int", Round(y), "Int", Round(x + w), "Int", Round(y + h), rect)
        DllCall("user32\FillRect", "Ptr", dc, "Ptr", rect, "Ptr", this.Brush(rgb))
    }

    static Gradient(dc, x, y, w, h, top := 0x262626, bottom := 0x131313) {
        h := Max(1, Round(h))
        Loop h {
            f := (A_Index - 1) / Max(1, h - 1)
            r := Round(((top >> 16) & 255) * (1-f) + ((bottom >> 16) & 255) * f)
            g := Round(((top >> 8) & 255) * (1-f) + ((bottom >> 8) & 255) * f)
            b := Round((top & 255) * (1-f) + (bottom & 255) * f)
            this.Fill(dc, x, y + A_Index - 1, w, 1, (r << 16) | (g << 8) | b)
        }
    }

    static Frame(dc, x, y, w, h, fill := 0x141414, topLine := false) {
        this.Fill(dc, x, y, w, h, 0x000000)
        this.Fill(dc, x+1, y+1, w-2, h-2, 0x323232)
        this.Fill(dc, x+2, y+2, w-4, h-4, fill)
        if topLine
            this.Fill(dc, x+2, y+2, w-4, 1, this.Accent)
    }

    static Text(dc, text, x, y, w, h, rgb := 0xFFFFFF, align := 0) {
        rect := Buffer(16)
        bgr := ((rgb & 255) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 255)
        flags := 0x24 | 0x800 | 0x8000 | align

        NumPut("Int", Round(x+1), "Int", Round(y+1), "Int", Round(x+w+1), "Int", Round(y+h+1), rect)
        DllCall("gdi32\SetTextColor", "Ptr", dc, "UInt", 0)
        DllCall("user32\DrawTextW", "Ptr", dc, "Str", text, "Int", -1, "Ptr", rect, "UInt", flags)
        NumPut("Int", Round(x), "Int", Round(y), "Int", Round(x+w), "Int", Round(y+h), rect)
        DllCall("gdi32\SetTextColor", "Ptr", dc, "UInt", bgr)
        DllCall("user32\DrawTextW", "Ptr", dc, "Str", text, "Int", -1, "Ptr", rect, "UInt", flags)
    }

    static FadedLabelText(dc, text, w, h, rgb, alpha) {
        if alpha <= 0 || text = ""
            return
        if alpha >= 255 {
            this.Text(dc, text, 1, 0, w-2, h, rgb)
            return
        }

        layer := DllCall("gdi32\CreateCompatibleDC", "Ptr", dc, "Ptr")
        if !layer
            return
        bitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", dc, "Int", w, "Int", h, "Ptr")
        if !bitmap {
            DllCall("gdi32\DeleteDC", "Ptr", layer)
            return
        }
        oldBitmap := DllCall("gdi32\SelectObject", "Ptr", layer, "Ptr", bitmap, "Ptr")
        font := DllCall("gdi32\GetCurrentObject", "Ptr", dc, "UInt", 6, "Ptr")
        oldFont := DllCall("gdi32\SelectObject", "Ptr", layer, "Ptr", font, "Ptr")
        try {
            DllCall("gdi32\BitBlt", "Ptr", layer, "Int", 0, "Int", 0, "Int", w, "Int", h,
                "Ptr", dc, "Int", 0, "Int", 0, "UInt", 0xCC0020)
            DllCall("gdi32\SetBkMode", "Ptr", layer, "Int", 1)
            this.Text(layer, text, 1, 0, w-2, h, rgb)

            DllCall("msimg32\AlphaBlend", "Ptr", dc, "Int", 0, "Int", 0, "Int", w, "Int", h,
                "Ptr", layer, "Int", 0, "Int", 0, "Int", w, "Int", h, "UInt", alpha << 16, "Int")
        } finally {
            DllCall("gdi32\SelectObject", "Ptr", layer, "Ptr", oldFont)
            DllCall("gdi32\SelectObject", "Ptr", layer, "Ptr", oldBitmap)
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
            DllCall("gdi32\DeleteDC", "Ptr", layer)
        }
    }

    static MixColor(first, second, amount) {
        amount := Max(0, Min(1, amount))
        r := Round(((first >> 16) & 255)*(1-amount)+((second >> 16) & 255)*amount)
        g := Round(((first >> 8) & 255)*(1-amount)+((second >> 8) & 255)*amount)
        b := Round((first & 255)*(1-amount)+(second & 255)*amount)
        return (r << 16) | (g << 8) | b
    }

    static TextWidth(dc, text) {
        size := Buffer(8, 0)
        DllCall("gdi32\GetTextExtentPoint32W", "Ptr", dc, "Str", text, "Int", StrLen(text), "Ptr", size)
        return NumGet(size, 0, "Int")
    }


    static FeatureLabel(dc, item, w, h, s) {
        pulse := item.pulsing ? 0.72+0.28*(0.5+0.5*Sin(this.AnimationTime/1000*1.4)) : 1
        dotColor := this.MixColor(0x1E1E1E,item.color,pulse)
        oldBrush := DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", this.Brush(dotColor), "Ptr")
        oldPen := DllCall("gdi32\SelectObject", "Ptr", dc,
            "Ptr", DllCall("gdi32\GetStockObject", "Int", 8, "Ptr"), "Ptr")
        dot := Max(2,Round(5*s))
        x := Round(2*s)
        y := Round((h-dot)/2)
        DllCall("gdi32\Ellipse", "Ptr", dc, "Int", x, "Int", y, "Int", x+dot, "Int", y+dot)
        DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", oldPen)
        DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", oldBrush)
        prefix := item.label " · "
        prefixX := Round(12*s)
        prefixW := this.TextWidth(dc,prefix)
        this.Text(dc,prefix,prefixX,0,prefixW+1,h,item.color)
        valueX := prefixX+prefixW
        valueW := Max(1,w-valueX-2)
        textW := this.TextWidth(dc,item.ctrl.Text)+2
        overflow := Max(0,textW-valueW)
        item.scrolling := overflow > 0
        offset := 0
        if overflow > 0 {
            elapsed := Max(0,this.AnimationTime-item.changedAt-1800)
            cycle := Max(12000,overflow/Max(1,18*s)*2000)
            offset := Round(overflow*(1-Cos(6.283185307179586*Mod(elapsed,cycle)/cycle))/2)
        }
        saved := DllCall("gdi32\SaveDC", "Ptr", dc, "Int")
        try {
            DllCall("gdi32\IntersectClipRect", "Ptr", dc, "Int", valueX, "Int", 0, "Int", w, "Int", h)
            this.Text(dc,item.ctrl.Text,valueX-offset,0,Max(textW,valueW),h,0xD8D8D8)
        } finally DllCall("gdi32\RestoreDC", "Ptr", dc, "Int", saved)
    }

    static DrawProfileAvatar(dc, item, w, h, s) {
        this.Fill(dc, 0, 0, w, h, 0x141414)
        size := Min(w,h)-Round(4*s)
        x := Round((w-size)/2), y := Round((h-size)/2)
        ring := DllCall("gdi32\CreateEllipticRgn", "Int", x, "Int", y,
            "Int", x+size, "Int", y+size, "Ptr")
        inside := DllCall("gdi32\CreateEllipticRgn", "Int", x+Round(2*s), "Int", y+Round(2*s),
            "Int", x+size-Round(2*s), "Int", y+size-Round(2*s), "Ptr")
        if ring {
            DllCall("gdi32\FillRgn", "Ptr", dc, "Ptr", ring, "Ptr", this.Brush(this.Accent))
            DllCall("gdi32\DeleteObject", "Ptr", ring)
        }
        if inside {
            DllCall("gdi32\FillRgn", "Ptr", dc, "Ptr", inside, "Ptr", this.Brush(0x252525))
            DllCall("gdi32\DeleteObject", "Ptr", inside)
        }
        picture := item.HasOwnProp("avatarPath") ? item.avatarPath : ""
        if picture != "" && FileExist(picture) && this.PaintAvatarImage(dc, picture,
            x+Round(3*s), y+Round(3*s), size-Round(6*s))
            return
        initial := item.HasOwnProp("initial") ? item.initial : "?"
        this.Text(dc, initial, x, y, size, size, this.Accent, 1)
    }

    static PaintAvatarImage(dc, path, x, y, size) {
        if !this.AvatarGdiToken {
            startup := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
            NumPut("UInt", 1, startup)
            token := 0
            if DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", startup, "Ptr", 0, "UInt") != 0
                return false
            this.AvatarGdiToken := token
        }
        bitmap := 0, graphics := 0, clipPath := 0
        try {
            if DllCall("gdiplus\GdipLoadImageFromFile", "WStr", path, "Ptr*", &bitmap, "UInt") != 0
                return false
            imageW := 0, imageH := 0
            DllCall("gdiplus\GdipGetImageWidth", "Ptr", bitmap, "UInt*", &imageW)
            DllCall("gdiplus\GdipGetImageHeight", "Ptr", bitmap, "UInt*", &imageH)
            if imageW < 1 || imageH < 1
                return false
            if DllCall("gdiplus\GdipCreateFromHDC", "Ptr", dc, "Ptr*", &graphics, "UInt") != 0
                return false
            if DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &clipPath, "UInt") != 0
                return false
            DllCall("gdiplus\GdipAddPathEllipse", "Ptr", clipPath, "Float", x+0.0, "Float", y+0.0,
                "Float", size+0.0, "Float", size+0.0)
            DllCall("gdiplus\GdipSetClipPath", "Ptr", graphics, "Ptr", clipPath, "Int", 0)
            DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", graphics, "Int", 7)
            crop := Min(imageW,imageH)
            return DllCall("gdiplus\GdipDrawImageRectRectI", "Ptr", graphics, "Ptr", bitmap,
                "Int", x, "Int", y, "Int", size, "Int", size,
                "Int", Floor((imageW-crop)/2), "Int", Floor((imageH-crop)/2),
                "Int", crop, "Int", crop, "Int", 2, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt") = 0
        } catch {
            return false
        } finally {
            if clipPath
                DllCall("gdiplus\GdipDeletePath", "Ptr", clipPath)
            if graphics
                DllCall("gdiplus\GdipDeleteGraphics", "Ptr", graphics)
            if bitmap
                DllCall("gdiplus\GdipDisposeImage", "Ptr", bitmap)
        }
    }

    static Draw(wParam, lParam, msg, hwnd) {
        Critical("On")
        if !lParam
            return
        offset := A_PtrSize = 8 ? 24 : 20
        handle := NumGet(lParam, offset, "Ptr")
        if !this.Items.Has(handle)
            return
        targetDC := NumGet(lParam, offset + A_PtrSize, "Ptr")
        this.Paint(handle, targetDC, NumGet(lParam, 16, "UInt"))
        return true
    }

    static Paint(handle, targetDC, state := 0) {
        if !targetDC || !this.Items.Has(handle)
            return
        Critical("On")
        item := this.Items[handle]
        rect := Buffer(16)
        if !DllCall("user32\GetClientRect", "Ptr", handle, "Ptr", rect, "Int")
            return
        left := 0
        top := 0
        w := NumGet(rect, 8, "Int")
        h := NumGet(rect, 12, "Int")
        if w <= 0 || h <= 0
            return true
        dc := DllCall("gdi32\CreateCompatibleDC", "Ptr", targetDC, "Ptr")
        if !dc
            return
        bitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", targetDC, "Int", w, "Int", h, "Ptr")
        if !bitmap {
            DllCall("gdi32\DeleteDC", "Ptr", dc)
            return
        }
        oldBitmap := DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", bitmap, "Ptr")
        if !oldBitmap || oldBitmap = -1 {
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
            DllCall("gdi32\DeleteDC", "Ptr", dc)
            return
        }
        dpi := DllCall("user32\GetDpiForWindow", "Ptr", handle, "UInt")
        scale := this.ControlScale(item.ctrl)
        fontSize := 13
        if item.kind = "profile-avatar"
            fontSize := item.w <= 65 ? 26 : 35
        else if item.kind = "config-picker" || item.kind = "config-menu-row" || item.kind = "config-menu-list"
            fontSize := 12
        else if item.kind = "profile-heading"
            fontSize := 15
        else if item.kind = "profile-meta"
            fontSize := 10
        else if item.kind = "profile-card-name"
            fontSize := 12
        else if item.kind = "profile-button" || item.kind = "profile-button-primary"
            || item.kind = "profile-selector" || item.kind = "profile-titlebar"
            fontSize := 11
        else if item.kind = "profile-close"
            fontSize := 18
        fontWeight := item.kind = "profile-heading" ? 600 : 400
        fontKey := dpi ":" scale ":" fontSize ":" fontWeight
        if !this.Fonts.Has(fontKey)
            this.Fonts[fontKey] := DllCall("gdi32\CreateFontW", "Int", -Max(1,Round(fontSize*scale)), "Int", 0,
                "Int", 0, "Int", 0, "Int", fontWeight, "UInt", 0, "UInt", 0, "UInt", 0,
                "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 3, "UInt", 0, "Str", "Tahoma", "Ptr")
        oldFont := DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", this.Fonts[fontKey], "Ptr")
        DllCall("gdi32\SetBkMode", "Ptr", dc, "Int", 1)
        try {
            this.Render(dc, item, w, h, scale, state)
            this.PaintCounts[handle] := this.PaintCounts.Has(handle) ? this.PaintCounts[handle]+1 : 1
            DllCall("gdi32\BitBlt", "Ptr", targetDC, "Int", left, "Int", top, "Int", w, "Int", h,
                "Ptr", dc, "Int", 0, "Int", 0, "UInt", 0xCC0020)
        } finally {
            DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", oldFont)
            DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", oldBitmap)
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
            DllCall("gdi32\DeleteDC", "Ptr", dc)
        }
        return true
    }

    static ProfileRounded(dc, w, h, s, borderColor, fillColor) {
        radius := Max(2, Round(6*s))
        outer := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0,
            "Int", w, "Int", h, "Int", radius, "Int", radius, "Ptr")
        if outer {
            DllCall("gdi32\FillRgn", "Ptr", dc, "Ptr", outer, "Ptr", this.Brush(borderColor))
            DllCall("gdi32\DeleteObject", "Ptr", outer)
        }
        inner := DllCall("gdi32\CreateRoundRectRgn", "Int", 1, "Int", 1,
            "Int", w-1, "Int", h-1, "Int", radius, "Int", radius, "Ptr")
        if inner {
            DllCall("gdi32\FillRgn", "Ptr", dc, "Ptr", inner, "Ptr", this.Brush(fillColor))
            DllCall("gdi32\DeleteObject", "Ptr", inner)
        }
    }

    static Render(dc, item, w, h, s, state) {
        kind := item.kind
        hot := this.Hover = item.ctrl.Hwnd || (state & 0x10)
        text := item.ctrl.Text
        this.Fill(dc, 0, 0, w, h, 0x141414)
        if kind = "window" {
            this.Frame(dc, 0, 0, w, h, 0x1E1E1E)
            this.Fill(dc, 1, 1, w-2, 1, this.Accent)
            this.Fill(dc, 1, h-2, w-2, 1, this.Accent)
            this.Fill(dc, 1, 1, 1, h-2, this.Accent)
            this.Fill(dc, w-2, 1, 1, h-2, this.Accent)
            return
        }
        if kind = "panel" {
            this.Frame(dc, 0, 0, w, h)
            return
        }
        if kind = "bar" {
            this.Frame(dc, 0, 0, w, h, 0x1E1E1E)
            this.Gradient(dc, 2, 2, w-4, h-4)
            return
        }
        if kind = "identity" {
            this.Gradient(dc, 0, 0, w, h)
            badgeW := 62*s
            badgeX := w-badgeW
            region := DllCall("gdi32\CreateRoundRectRgn", "Int", Round(badgeX), "Int", Round(2*s),
                "Int", w, "Int", h-Round(2*s), "Int", Round(8*s), "Int", Round(8*s), "Ptr")
            if region {
                DllCall("gdi32\FillRgn", "Ptr", dc, "Ptr", region,
                    "Ptr", this.Brush(this.MixColor(0x1E1E1E, this.Accent, 0.14)), "Int")
                DllCall("gdi32\DeleteObject", "Ptr", region)
            }
            this.Text(dc, "Lifetime", badgeX+3*s, 0, badgeW-6*s, h, this.Accent, 1)
            this.Text(dc, text, 5*s, 0, Max(1,badgeX-13*s), h, 0xEAEAEA, 2)
            return
        }
        if kind = "profile-bg" {
            this.Fill(dc, 0, 0, w, h, 0x101215)
            this.Fill(dc, 0, 0, w, 1, 0x34363D)
            this.Fill(dc, 0, h-1, w, 1, 0x34363D)
            this.Fill(dc, 0, 0, 1, h, 0x34363D)
            this.Fill(dc, w-1, 0, 1, h, 0x34363D)
            return
        }
        if kind = "profile-titlebar" {
            this.Fill(dc, 0, 0, w, h, 0x14161A)
            this.Fill(dc, 0, h-1, w, 1, 0x292B31)
            this.Text(dc, text, 15*s, 0, w-53*s, h, this.Accent)
            return
        }
        if kind = "profile-close" {
            this.Fill(dc, 0, 0, w, h, 0x14161A)
            this.Text(dc, text, 0, 0, w, h, hot ? this.Accent : 0xD6D8DC, 1)
            return
        }
        if kind = "profile-label" || kind = "profile-muted" || kind = "profile-heading" {
            this.Fill(dc, 0, 0, w, h, 0x101215)
            shade := kind = "profile-muted" ? (item.color = 0xFFFFFF ? 0xAAAAAE : item.color) : (kind = "profile-heading" ? 0xFFFFFF : this.Accent)
            this.Text(dc, text, 0, 0, w, h, shade, kind = "profile-heading" ? 1 : 0)
            return
        }
        if kind = "profile-meta" {
            this.Fill(dc, 0, 0, w, h, 0x101215)
            this.Text(dc, "LAST LOGIN", 0, 0, 77*s, h, 0xC6C8CB)
            this.Text(dc, " / ", 77*s, 0, 17*s, h, this.Accent)
            this.Text(dc, SubStr(text, StrLen("LAST LOGIN  /  ")+1), 97*s, 0,
                Max(1,w-97*s), h, this.Accent)
            return
        }
        if kind = "config-picker" {
            this.Frame(dc, 0, 0, w, h, hot ? 0x202025 : 0x171717)
            if hot
                this.Fill(dc, 1, h-2, w-2, 1, this.Accent)
            this.Text(dc, text, 10*s, 0, w-47*s, h, 0xF4F4F4)
            this.Text(dc, "v", w-27*s, 0, 16*s, h, this.Accent, 1)
            return
        }
        if kind = "config-menu-list" {
            IvoryConfigPaintList(dc, item, w, h, s)
            return
        }
        if kind = "config-menu-scroll" {
            this.Fill(dc, 0, 0, w, h, 0x1A1A1A)
            thumbH := Max(12*s, Round(h*item.max))
            y := Round((h-thumbH)*item.min)
            this.Fill(dc, 1, y, Max(1, w-2), thumbH, hot ? this.Accent : 0x797980)
            return
        }
        if kind = "config-menu-row" {
            selected := item.selected
            fill := selected ? this.MixColor(0x171717, this.Accent, 0.17) : (hot ? 0x28282B : 0x171717)
            this.Fill(dc, 0, 0, w, h, fill)
            if selected
                this.Fill(dc, 0, 0, 2*s, h, this.Accent)
            this.Text(dc, text, 10*s, 0, w-18*s, h, selected ? this.Accent : 0xEDEDEE)
            return
        }
        if kind = "profile-selector" {
            this.Fill(dc, 0, 0, w, h, 0x101215)
            this.ProfileRounded(dc, w, h, s, hot ? this.Accent : 0x43464C,
                hot ? 0x202329 : 0x17191D)
            this.Text(dc, text, 11*s, 0, w-47*s, h, 0xF2F2F4)
            this.Text(dc, "⌄", w-27*s, 0, 19*s, h, 0xBFC2C8, 1)
            return
        }
        if kind = "profile-button" || kind = "profile-button-primary" {
            this.Fill(dc, 0, 0, w, h, 0x101215)
            primary := kind = "profile-button-primary"
            this.ProfileRounded(dc, w, h, s,
                primary ? this.Accent : (hot ? 0x686A70 : 0x3D4046),
                hot ? (primary ? 0x29202A : 0x26282D) : 0x17191D)
            this.Text(dc, text, 4*s, 0, w-8*s, h,
                primary ? this.Accent : 0xE7E7E9, 1)
            return
        }
        if kind = "profile-card" {
            this.Frame(dc, 0, 0, w, h, 0x17191D)
            return
        }
        if kind = "profile-card-label" || kind = "profile-card-name" {
            this.Fill(dc, 0, 0, w, h, 0x17191D)
            this.Text(dc, text, 1, 0, w-2, h, kind = "profile-card-name" ? 0xF4F4F4 : this.Accent)
            return
        }
        if kind = "profile-input" {
            this.Frame(dc, 0, 0, w, h, 0x17191D)
            return
        }
        if kind = "profile-avatar" {
            this.DrawProfileAvatar(dc, item, w, h, s)
            return
        }
        if kind = "swatch" {
            this.Frame(dc, 0, 0, w, h, item.color)
            red := (item.color >> 16) & 255, green := (item.color >> 8) & 255, blue := item.color & 255
            foreground := red*0.299+green*0.587+blue*0.114 >= 150 ? 0x141414 : 0xFFFFFF
            this.Text(dc, text, 2*s, 0, w-4*s, h, foreground, 1)
            return
        }
        if kind = "brand" || kind = "feature-label" {
            this.Gradient(dc, 0, 0, w, h)
            if kind = "brand"
                this.Text(dc, text, 1, 0, w-2, h, this.Accent)
            else
                this.FeatureLabel(dc, item, w, h, s)
            return
        }
        if kind = "label" || kind = "title" || kind = "bar-label" {
            if kind = "title"
                this.Fill(dc, 0, 0, w, h, 0x1E1E1E)
            if kind = "bar-label" {
                this.Gradient(dc, 0, 0, w, h)
                this.FadedLabelText(dc, text, w, h, item.color, item.textAlpha)
                return
            }
            this.Text(dc, text, 1, 0, w-2, h, item.color)
            return
        }
        if kind = "scrollbar" {
            group := this.Groups[item.group]
            content := IvoryContentHeight(group)
            if content > group.bodyH {
                track := h-4
                thumbH := Max(12*s, track*group.bodyH/content)
                thumbY := 2+(track-thumbH)*group.scroll[group.selected]/Max(1, content-group.bodyH)
                this.Fill(dc, 0, thumbY, w, thumbH, this.Accent)
            }
            return
        }
        if kind = "tab" || kind = "button" || kind = "drag" || kind = "group-title" {
            hover := item.animated ? item.hoverBlend : hot ? 1 : 0
            selection := item.animated ? item.selectionBlend : item.selected ? 1 : 0
            topColor := this.MixColor(0x262626,0x303030,hover)
            this.Frame(dc, 0, 0, w, h, this.MixColor(0x141414,0x262626,hover))
            this.Gradient(dc, 2, 2, w-4, h-4, topColor)
            if kind = "tab" || kind = "group-title" {
                if selection > 0 || kind = "group-title"
                    this.Fill(dc, 2, 2, w-4, Max(1, Round(s)),
                        this.MixColor(topColor,this.Accent,kind = "group-title" ? 1 : selection))
            }
            this.Text(dc, text, 4*s, 0, w-8*s, h, this.MixColor(0xD8D8D8,this.Accent,selection), 1)
            return
        }
        if kind = "bool" || kind = "module" {
            checked := kind = "module" ? CfgBool("Modules", item.module, false) : CfgBool(item.section, item.key, false)
            box := Max(8, Round(13*s))
            y := Round((h-box)/2)
            this.Frame(dc, 0, y, box, box, hot ? 0x262626 : 0x1E1E1E)
            if checked
                this.Gradient(dc, 2, y+2, box-4, box-4, this.Accent, 0x777777)
            this.Text(dc, kind = "module" ? "Enabled" : item.label, 17*s, 0, w-17*s, h)
            return
        }
        if kind = "key" || kind = "color" || kind = "text" {
            if item.inline {
                this.Frame(dc, 0, 0, w, h, hot ? 0x262626 : 0x1E1E1E)
                this.Text(dc, text, 3*s, 0, w-6*s, h, 0xFFFFFF, 1)
                return
            }
            this.Text(dc, item.label, 0, 0, w-96*s, h)
            bw := kind = "color" ? 28*s : 74*s
            this.Frame(dc, w-bw, 0, bw, h, hot ? 0x262626 : 0x1E1E1E)
            if kind = "color" {
                value := Cfg(item.section, item.key, "")
                rgb := RegExMatch(value, "i)^0x[0-9a-f]{6}$") ? value+0 : 0x323232
                this.Fill(dc, w-bw+3, 3, bw-6, h-6, rgb)
            } else
                this.Text(dc, text, w-bw+3, 0, bw-6, h, 0xFFFFFF, 1)
            return
        }
        if kind = "choice" {
            this.Text(dc, item.label, 0, 0, w, 14*s)
            y := Round(15*s)
            this.Frame(dc, 0, y, w, h-y-2*s, hot ? 0x262626 : 0x1E1E1E)
            this.Gradient(dc, 2, y+2, w-4, h-y-6*s)
            this.Text(dc, text, 5*s, y, w-22*s, h-y-2*s)
            arrowY := y + (h-y)/2 - 2*s
            this.Fill(dc, w-15*s, arrowY, 7*s, s, 0xFFFFFF)
            this.Fill(dc, w-14*s, arrowY+s, 5*s, s, 0xFFFFFF)
            this.Fill(dc, w-13*s, arrowY+2*s, 3*s, s, 0xFFFFFF)
            this.Fill(dc, w-12*s, arrowY+3*s, s, s, 0xFFFFFF)
            return
        }
        if kind = "int" || kind = "float" {
            this.Text(dc, item.label, 0, 0, w, 14*s)
            y := Round(15*s)
            bh := Round(13*s)
            barW := w - Round(32*s)
            this.Frame(dc, 0, y, barW, bh, hot ? 0x262626 : 0x1E1E1E)
            value := item.pending != "" ? item.pending : Cfg(item.section, item.key, item.min)
            f := IsNumber(value) && item.max > item.min ? Max(0, Min(1, (value-item.min)/(item.max-item.min))) : 0
            this.Gradient(dc, 2, y+2, Round((barW-4)*f), bh-4, this.Accent, 0x777777)
            this.Text(dc, item.pending != "" ? item.pending : text, 2, y, barW-4, bh, 0xFFFFFF, 1)
            this.Frame(dc, barW+4*s, y, 12*s, bh)
            this.Frame(dc, barW+20*s, y, 12*s, bh)
            this.Text(dc, "-", barW+4*s, y, 12*s, bh, 0xFFFFFF, 1)
            this.Text(dc, "+", barW+20*s, y, 12*s, bh, 0xFFFFFF, 1)
        }
    }

    static MouseMove(wParam, lParam, msg, hwnd) {
        if IsObject(this.ScrollDrag) {
            if this.ScrollDrag.kind = "config-menu-scroll"
                IvoryConfigScrollbarClick(this.ScrollDrag.ctrl)
            else
                IvoryScrollClick(this.ScrollDrag.ctrl)
            return 0
        }
        if IsObject(this.Drag) {
            this.DragValue()
            return 0
        }
        if !this.Items.Has(hwnd)
            return
        if this.Items[hwnd].kind = "config-menu-list"
            IvoryConfigHoverAt(this.Items[hwnd].ctrl)
        if this.Hover != hwnd {
            old := this.Hover
            this.Hover := hwnd
            if this.Items.Has(old)
                this.Redraw(this.Items[old].ctrl)
            this.Redraw(this.Items[hwnd].ctrl)

            tme := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
            NumPut("UInt", tme.Size, "UInt", 2, "Ptr", hwnd, tme)
            DllCall("user32\TrackMouseEvent", "Ptr", tme)
            OnMessage(0x2A3, IvoryMouseLeave)
        }
    }

    static Point(ctrl) {
        pt := Buffer(8)
        DllCall("user32\GetCursorPos", "Ptr", pt)
        DllCall("user32\ScreenToClient", "Ptr", ctrl.Hwnd, "Ptr", pt)
        s := this.ControlScale(ctrl)
        return {x: NumGet(pt, 0, "Int")/s, y: NumGet(pt, 4, "Int")/s}
    }

    static MouseDown(wParam, lParam, msg, hwnd) {
        if !this.Items.Has(hwnd)
            return
        item := this.Items[hwnd]
        if item.kind = "scrollbar" || item.kind = "config-menu-scroll" {
            this.ScrollDrag := item
            DllCall("user32\SetCapture", "Ptr", hwnd)
            if item.kind = "config-menu-scroll"
                IvoryConfigScrollbarStart(item.ctrl)
            else
                IvoryScrollClick(item.ctrl)
            return 0
        }
        if item.kind = "drag" || item.kind = "title" {
            BeginDrag()
            return 0
        }
        if item.kind != "int" && item.kind != "float"
            return
        p := this.Point(item.ctrl)
        item.ctrl.GetPos(,, &w)
        w /= this.Scale
        if p.y < 15 || p.y > 28 || p.x >= w-32
            return
        if GetKeyState("Ctrl", "P")
            return
        this.Drag := item
        DllCall("user32\SetFocus", "Ptr", hwnd)
        DllCall("user32\SetCapture", "Ptr", hwnd)
        this.DragValue()
        return 0
    }

    static DragValue() {
        item := this.Drag
        p := this.Point(item.ctrl)
        item.ctrl.GetPos(,, &w)
        w /= this.Scale
        f := Max(0, Min(1, p.x/Max(1, w-32)))
        item.pending := Round(item.min + f*(item.max-item.min), item.kind = "int" ? 0 : 2)
        this.Redraw(item.ctrl)
    }

    static MouseUp(wParam, lParam, msg, hwnd) {
        if IsObject(this.ScrollDrag) {
            this.ScrollDrag := 0
            DllCall("user32\ReleaseCapture")
            return 0
        }
        if !IsObject(this.Drag)
            return
        item := this.Drag
        value := item.pending
        this.Drag := 0
        item.pending := ""
        DllCall("user32\ReleaseCapture")
        IvoryCommit(item, value)
        return 0
    }

    static CancelCapture(*) {
        this.ScrollDrag := 0
        if !IsObject(this.Drag)
            return
        item := this.Drag
        item.pending := ""
        this.Drag := 0
        this.Redraw(item.ctrl)
    }

    static DoubleClick(wParam, lParam, msg, hwnd) {
        if !this.Items.Has(hwnd)
            return
        item := this.Items[hwnd]
        if item.kind = "int" || item.kind = "float" {
            this.CancelCapture()
            DllCall("user32\ReleaseCapture")
            IvoryOpenEditor(item)
            return 0
        }
    }

    static KeyDown(wParam, lParam, msg, hwnd) {
        if !this.Items.Has(hwnd)
            return
        item := this.Items[hwnd]
        if item.kind != "int" && item.kind != "float"
            return
        if wParam = 0x25 || wParam = 0x27 {
            IvoryStep(item, wParam = 0x25 ? -1 : 1)
            return 0
        }
        if wParam = 0x0D || wParam = 0x20 {
            IvoryOpenEditor(item)
            return 0
        }
    }

    static Activate(wParam, lParam, msg, hwnd) {
        IvoryAppBarActivate(hwnd)
        if IsObject(this.Popup) && hwnd = this.Popup.Hwnd && (wParam & 0xFFFF) = 0
            SetTimer(() => IvoryClosePopupIf(hwnd), -1)
        if IvoryKeyCaptureActive() && this.KeyCapture.phase != "opening" && hwnd = this.KeyCapture.gui.Hwnd && (wParam & 0xFFFF) = 0
            SetTimer(() => IvoryCaptureLostFocus(hwnd), -1)
    }

    static ClosePopup(*) {
        global ConfigMenu
        if !IsObject(this.Popup)
            return
        gui := this.Popup
        popupHwnd := gui.Hwnd
        if IsObject(ConfigMenu) && ConfigMenu.gui.Hwnd = popupHwnd {
            SetTimer(IvoryConfigScrollTick, 0)
            ConfigMenu := 0
        }
        handles := this.PopupHandles.Clone()
        if IsObject(this.ScrollDrag) && this.ScrollDrag.ctrl.Gui.Hwnd = popupHwnd {
            this.ScrollDrag := 0
            DllCall("user32\ReleaseCapture")
        }
        this.Popup := 0
        this.PopupSource := 0
        this.PopupHandles := []
        if this.PixelScales.Has(popupHwnd)
            this.PixelScales.Delete(popupHwnd)
        for handle in handles {
            if this.Hover = handle
                this.Hover := 0
            if this.Items.Has(handle)
                this.Items.Delete(handle)
            if this.PaintCounts.Has(handle)
                this.PaintCounts.Delete(handle)
        }
        try gui.Hide()
        SetTimer(IvoryDestroyGui.Bind(gui), -1)
        IvoryRefreshToolbar()
    }

    static ShowChoices(ctrl, choices, callback) {
        this.ClosePopup()
        choiceMenu := Menu()
        current := StrLower(ctrl.Text)
        for _, value in choices {
            choiceMenu.Add(value, IvoryChoiceSelect.Bind(value, callback))
            if StrLower(value) = current
                try choiceMenu.Check(value)
        }
        rect := Buffer(16, 0)
        if DllCall("user32\GetWindowRect", "Ptr", ctrl.Hwnd, "Ptr", rect.Ptr, "Int") {
            previousMode := A_CoordModeMenu
            CoordMode("Menu", "Screen")
            try choiceMenu.Show(NumGet(rect, 0, "Int"), NumGet(rect, 12, "Int"))
            finally CoordMode("Menu", previousMode)
        } else
            choiceMenu.Show()
    }

    static Cleanup(*) {
        IvoryClearStatus()
        IvoryCaptureCancel()
        IvoryToolbarShutdown(false)
        if this.AvatarGdiToken {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", this.AvatarGdiToken)
            this.AvatarGdiToken := 0
        }
        for hwnd, item in this.Items {
            if DllCall("user32\IsWindow", "Ptr", hwnd, "Int")
                DllCall("comctl32\RemoveWindowSubclass", "Ptr", hwnd, "Ptr", this.SubclassHandler, "UPtr", 0x4956)
        }
    }
}

MonitorFromPoint(x, y) {
    count := MonitorGetCount()
    Loop count {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if x >= l && x < r && y >= t && y < b
            return A_Index
    }
    return MonitorGetPrimary()
}

IvoryMouseLeave(wParam, lParam, msg, hwnd) {
    if IvoryUI.Hover = hwnd {
        IvoryUI.Hover := 0
        if IvoryUI.Items.Has(hwnd)
            IvoryUI.Redraw(IvoryUI.Items[hwnd].ctrl)
    }
}

IvoryChoiceSelect(value, callback, *) {
    callback.Call(value)
}

IvoryCommit(item, value) {
    if SetCfg(item.section, item.key, value, item.module != "") {
        RefreshAllValues()
        SetStatus(item.label " updated", "ok")
    } else
        RefreshAllValues()
    IvoryUI.Redraw(item.ctrl)
}

IvoryStep(item, direction) {
    step := item.kind = "int" ? 1 : (item.max-item.min <= 2 ? 0.01 : 0.1)
    value := Cfg(item.section, item.key, item.min) + direction*step
    IvoryCommit(item, Round(Max(item.min, Min(item.max, value)), item.kind = "int" ? 0 : 2))
}

IvoryEdit(ctrl, *) {
    item := IvoryUI.Items[ctrl.Hwnd]
    if item.kind = "int" || item.kind = "float" {
        p := IvoryUI.Point(ctrl)
        ctrl.GetPos(,, &w)
        w /= IvoryUI.Scale
        if p.y >= 15 && p.x >= w-32 && !GetKeyState("Ctrl", "P") {
            IvoryStep(item, p.x < w-16 ? -1 : 1)
            return
        }
    }
    if item.kind = "choice" {
        IvoryUI.ShowChoices(ctrl, item.choices, IvoryCommit.Bind(item))
        return
    }
    IvoryOpenEditor(item)
}

IvoryPaletteColors() {
    return [["Black",0x000000],["Coal",0x141414],["Slate",0x323232],["Gray",0x737378],["Silver",0xBFC4CC],["White",0xFFFFFF],
        ["Snow",0xFDFDFC],["Cream",0xFFF2D5],["Sand",0xDCC37B],["Gold",0xF9E2AF],["Amber",0xFFC247],["Orange",0xFF9E64],
        ["Peach",0xFAB387],["Coral",0xFF7D75],["Red",0xFF4D67],["Rose",0xE98995],["Pink",0xFF9DB4],["Blush",0xF38BA8],
        ["Ruby",0xC93A5B],["Berry",0xB9558C],["Mauve",0xC49AB5],["Lilac",0xCBA6F7],["Purple",0xBE95FF],["Violet",0xA66BFF],
        ["Plum",0x7D5BA6],["Indigo",0x5F6BDA],["Blue",0x3264FF],["Sky",0x89B4FA],["Ice",0xB6DCFF],["Cyan",0x79F8FB],
        ["Aqua",0x66DBEB],["Teal",0x50C9BA],["Mint",0x8FD7AE],["Green",0x89D9A0],["Lime",0xA6E3A1],["Leaf",0x58B978],
        ["Forest",0x287A5D],["Olive",0x7A9E5A],["Yellow",0xFFE466],["Lemon",0xF9F99A],["Honey",0xDFB567],["Brown",0x9F775E],
        ["Stone",0xA6A6AA],["Ash",0x9D9B9B],["Steel",0x697C94],["Navy",0x263D74],["Azure",0x5A8EE9],["Azure2",0x5856D6]]
}

IvoryColorPrompt(prompt, current := "", allowNone := false) {
    global MainGui
    result := {Result:"Cancel", Value:current}
    dialog := Gui("+Owner" MainGui.Hwnd " -Caption +Border +ToolWindow", "Color palette")
    dialog.BackColor := "141414"
    dialog.SetFont("s9 cFFFFFF", "Tahoma")
    handles := []
    for spec in [["panel",0,0,400,346,""],["bar",2,2,396,24,""],
        ["label",10,4,378,20,prompt],["label",12,31,376,20,"Choose a color from the palette."]] {
        control := IvoryUI.Add(dialog, spec*)
        handles.Push(control.Hwnd)
    }
    for index, spec in IvoryPaletteColors() {
        x := 12+Mod(index-1,6)*63, y := 57+Floor((index-1)/6)*30
        color := Format("0x{:06X}",spec[2])
        control := IvoryUI.Add(dialog,"swatch",x,y,59,26,spec[1],"",IvoryColorPromptSelect.Bind(dialog,result,color))
        IvoryUI.Items[control.Hwnd].color := spec[2]
        handles.Push(control.Hwnd)
    }
    control := IvoryUI.Add(dialog,"button",12,307,116,27,"Keep current","",IvoryColorPromptSelect.Bind(dialog,result,current))
    handles.Push(control.Hwnd)
    if allowNone {
        control := IvoryUI.Add(dialog,"button",142,307,116,27,"None / disable","",IvoryColorPromptSelect.Bind(dialog,result,""))
        handles.Push(control.Hwnd)
    }
    control := IvoryUI.Add(dialog,"button",272,307,116,27,"Cancel","",IvoryColorPromptCancel.Bind(dialog,result))
    handles.Push(control.Hwnd)
    dialog.OnEvent("Close",IvoryColorPromptCancel.Bind(dialog,result))
    dialog.OnEvent("Escape",IvoryColorPromptCancel.Bind(dialog,result))
    MainGui.Opt("+Disabled")
    scale := IvoryUI.Scale
    try {
        MainGui.GetPos(&x,&y,&w,&h)
        dialog.Show("Hide w" Round(400*scale) " h" Round(346*scale))
        dialog.GetPos(,,&dw,&dh)
        dialog.Show("x" Round(x+(w-dw)/2) " y" Round(y+(h-dh)/2))
        WinWaitClose("ahk_id " dialog.Hwnd)
    } finally {
        MainGui.Opt("-Disabled")
        for handle in handles {
            if IvoryUI.Hover = handle
                IvoryUI.Hover := 0
            if IvoryUI.Items.Has(handle)
                IvoryUI.Items.Delete(handle)
            if IvoryUI.PaintCounts.Has(handle)
                IvoryUI.PaintCounts.Delete(handle)
        }
        try WinActivate("ahk_id " MainGui.Hwnd)
    }
    return result
}

IvoryColorPromptSelect(dialog,result,color,*) {
    result.Result := "OK"
    result.Value := color
    IvoryQueueDestroyGui(dialog)
}

IvoryColorPromptCancel(dialog,result,*) {
    result.Result := "Cancel"
    IvoryQueueDestroyGui(dialog)
}

IvoryPrompt(prompt, current := "", kind := "text") {
    global MainGui
    result := {Result: "Cancel", Value: current}
    dialog := Gui("+Owner" MainGui.Hwnd " -Caption +Border +ToolWindow", "Edit setting")
    dialog.BackColor := "141414"
    dialog.SetFont("s9 cFFFFFF", "Tahoma")
    handles := []
    for spec in [["panel",0,0,380,166,""],["bar",2,2,376,24,""],
        ["label",10,4,358,20,StrSplit(prompt,"`n")[1]],
        ["label",12,37,356,32,"Enter a value; Apply saves the change"]] {
        ctrl := IvoryUI.Add(dialog, spec*)
        handles.Push(ctrl.Hwnd)
    }
    s := IvoryUI.Scale
    edit := dialog.Add("Edit", "x" Round(12*s) " y" Round(78*s) " w" Round(356*s) " h" Round(25*s)
        " Background1E1E1E cFFFFFF -E0x200", current)
    IvoryUI.Raise(edit)
    apply := IvoryUI.Add(dialog, "button", 196, 123, 82, 26, "Apply", "", IvoryPromptFinish.Bind(dialog, result, edit, "OK"))
    cancel := IvoryUI.Add(dialog, "button", 286, 123, 82, 26, "Cancel", "", IvoryPromptFinish.Bind(dialog, result, edit, "Cancel"))
    handles.Push(apply.Hwnd, cancel.Hwnd)
    dialog.OnEvent("Close", IvoryPromptFinish.Bind(dialog, result, edit, "Cancel"))
    dialog.OnEvent("Escape", IvoryPromptFinish.Bind(dialog, result, edit, "Cancel"))
    onEnter := (wParam, lParam, msg, hwnd) => IvoryPromptEnter(dialog, result, edit, wParam, hwnd)
    OnMessage(0x100, onEnter)
    MainGui.Opt("+Disabled")
    try {
        MainGui.GetPos(&x, &y, &w, &h)
        dialog.Show("Hide w" Round(380*s) " h" Round(166*s))
        dialog.GetPos(,, &dw, &dh)
        dialog.Show("x" Round(x+(w-dw)/2) " y" Round(y+(h-dh)/2))
        edit.Focus()
        SendMessage(0xB1, 0, -1, edit)
        WinWaitClose("ahk_id " dialog.Hwnd)
    } finally {
        OnMessage(0x100, onEnter, 0)
        MainGui.Opt("-Disabled")
        for handle in handles {
            if IvoryUI.Items.Has(handle)
                IvoryUI.Items.Delete(handle)
            if IvoryUI.PaintCounts.Has(handle)
                IvoryUI.PaintCounts.Delete(handle)
        }
        try WinActivate("ahk_id " MainGui.Hwnd)
    }
    return result
}

IvoryPromptEnter(dialog, result, edit, key, hwnd) {
    if key = 13 && hwnd = edit.Hwnd {
        IvoryPromptFinish(dialog, result, edit, "OK")
        return 0
    }
}

IvoryPromptFinish(dialog, result, edit, action, *) {
    result.Result := action
    result.Value := edit.Value
    IvoryQueueDestroyGui(dialog)
}

IvoryOpenEditor(item) {
    EditSetting(item.section, item.key, item.kind, item.min, item.max, item.choices, item.module, item.ctrl)
    IvoryUI.Redraw(item.ctrl)
}

IvoryClosePopupIf(hwnd) {
    if IsObject(IvoryUI.Popup) && IvoryUI.Popup.Hwnd = hwnd
        IvoryUI.ClosePopup()
}

IvoryQueueClosePopup(hwnd, *) {
    if !IsObject(IvoryUI.Popup) || IvoryUI.Popup.Hwnd != hwnd
        return
    try IvoryUI.Popup.Hide()
    SetTimer(IvoryClosePopupIf.Bind(hwnd), -1)
}

IvoryQueueDestroyGui(gui) {
    if !IsObject(gui)
        return
    try gui.Hide()
    SetTimer(IvoryDestroyGui.Bind(gui), -1)
}

IvoryDestroyGui(gui) {
    if IsObject(gui)
        try gui.Destroy()
}
