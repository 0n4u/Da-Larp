class WeaponGate {
    __New(action, confirmation) {
        this.Action := action
        this.Confirmation := confirmation
        this.Streak := 0
        this.LastName := ""
        this.Allowed := false
    }
    Observe(matched, failed, name) {
        permitted := !failed && (this.Action = "block matched" ? !matched : matched)
        if !permitted {
            this.Streak := 0
            this.LastName := ""
            this.Allowed := false
        } else {
            this.Streak := name = this.LastName ? this.Streak+1 : 1
            this.LastName := name
            this.Allowed := this.Streak >= this.Confirmation
        }
        return this.Allowed
    }
}

WeaponRegion(left, top, width, height, percentX, percentY, percentW, percentH) {
    x1 := left+Floor(width*Min(99.9, Max(0, percentX))/100)
    y1 := top+Floor(height*Min(99.9, Max(0, percentY))/100)
    x2 := Min(left+width-1, x1+Max(1, Round(width*percentW/100))-1)
    y2 := Min(top+height-1, y1+Max(1, Round(height*percentH/100))-1)
    return [x1, y1, x2, y2]
}

WeaponAssetPath(relative) {
    relative := StrReplace(relative, "/", "\")
    if !RegExMatch(relative, "i)^assets\\weapons\\[a-z0-9._ -]+\.(png|bmp|jpg|jpeg)$")
        throw Error("Weapon template must be under assets/weapons")
    path := A_ScriptDir "\..\" relative
    if !FileExist(path)
        throw Error("Missing weapon template: " relative)
    return path
}

WeaponImageSize(path) {
    static dimensions := Map()
    if dimensions.Has(path)
        return dimensions[path]
    kind := 0
    bitmap := LoadPicture(path, "", &kind)
    if !bitmap || kind != 0 {
        if bitmap
            DllCall("user32\DestroyIcon", "Ptr", bitmap)
        throw Error("Cannot load weapon image")
    }
    try {
        info := Buffer(32, 0)
        if !DllCall("gdi32\GetObjectW", "Ptr", bitmap, "Int", info.Size, "Ptr", info, "Int")
            throw Error("Cannot read weapon image dimensions")
        size := [NumGet(info, 4, "Int"), Abs(NumGet(info, 8, "Int"))]
        if size[1] <= 0 || size[2] <= 0
            throw Error("Invalid weapon image dimensions")
        dimensions[path] := size
        return size
    } finally DllCall("gdi32\DeleteObject", "Ptr", bitmap)
}
