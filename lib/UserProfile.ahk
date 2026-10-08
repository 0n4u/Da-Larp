class UserProfile {
    static Path := A_AppData "\DaLarp\profile.ini"
    static AvatarDirectory := A_AppData "\DaLarp\avatars"
    static Current := 0
    static Ready := false
    static Dialog := 0

    static Name(value) {
        name := Trim(value)
        if !RegExMatch(name, "^[\p{L}\p{N}][\p{L}\p{N} ._-]{0,31}$")
            throw ValueError("Use 1-32 letters/numbers; spaces, . _ - allowed.")
        return name
    }

    static Load(path := "") {
        if path = ""
            path := this.Path
        if !FileExist(path) || DirExist(path)
            return 0
        try {
            if IniRead(path, "Profile", "Version", "") != "1"
                return 0
            name := this.Name(IniRead(path, "Profile", "Username", ""))
            created := IniRead(path, "Profile", "Created", "")
            if !this.ValidTimestamp(created)
                return 0
            lastLogin := IniRead(path, "Profile", "LastLogin", "")
            if lastLogin != "" && !this.ValidTimestamp(lastLogin)
                lastLogin := ""
            avatar := IniRead(path, "Profile", "Avatar", "")
            if avatar != "" && (!FileExist(avatar) || DirExist(avatar))
                avatar := ""
            return {username: name, created: created, lastLogin: lastLogin, avatar: avatar}
        } catch {
            return 0
        }
    }

    static CheckAvatar(source) {
        if source = ""
            return ""
        if !FileExist(source) || DirExist(source)
            throw ValueError("The selected picture no longer exists.")
        SplitPath(source,,, &extension)
        extension := StrLower(extension)
        if !InStr("|png|jpg|jpeg|bmp|gif|", "|" extension "|")
            throw ValueError("Choose a PNG, JPG, BMP or GIF image.")
        if FileGetSize(source) > 8388608
            throw ValueError("Choose a picture smaller than 8 MB.")
        try {
            pictureType := 0
            pictureHandle := LoadPicture(source, "w64 h64", &pictureType)
            if !pictureHandle
                throw Error("Image decoding failed")
            if pictureType = 0
                DllCall("gdi32\DeleteObject", "Ptr", pictureHandle)
            else
                DllCall("user32\DestroyIcon", "Ptr", pictureHandle)
        } catch {
            throw ValueError("The image cannot be opened. Try another picture.")
        }
        return source
    }

    static ValidTimestamp(value) {
        if !RegExMatch(value, "^\d{14}$")
            return false
        year := SubStr(value,1,4)+0, month := SubStr(value,5,2)+0, day := SubStr(value,7,2)+0
        if year < 1601 || month < 1 || month > 12 || day < 1
            return false
        days := [31,28,31,30,31,30,31,31,30,31,30,31]
        if Mod(year,4) = 0 && (Mod(year,100) != 0 || Mod(year,400) = 0)
            days[2] := 29
        return day <= days[month] && SubStr(value,9,2)+0 < 24
            && SubStr(value,11,2)+0 < 60 && SubStr(value,13,2)+0 < 60
    }

    static RemoveManagedAvatar(path) {
        if path = ""
            return
        SplitPath(path, &name, &directory)
        if StrLower(RTrim(directory,"\\/")) != StrLower(RTrim(this.AvatarDirectory,"\\/"))
            || !RegExMatch(name, "i)^avatar-\d{14}-\d{6}\.(png|jpg|jpeg|bmp|gif)$")
            return
        try FileDelete(path)
    }

    static StoreAvatar(source) {
        this.CheckAvatar(source)
        SplitPath(source,,, &extension)
        DirCreate(this.AvatarDirectory)
        destination := this.AvatarDirectory "\avatar-" A_NowUTC "-" Random(100000,999999) "." StrLower(extension)
        temporary := destination ".tmp"
        try {
            FileCopy(source, temporary)
            FileMove(temporary, destination)
            return destination
        } finally {
            try FileDelete(temporary)
        }
    }

    static Save(value, path := "", avatar := unset, login := unset) {
        name := this.Name(value)
        if path = ""
            path := this.Path
        SplitPath(path,, &directory)
        DirCreate(directory)
        previous := this.Load(path)
        created := IsObject(previous) ? previous.created : A_NowUTC
        lastLogin := IsObject(previous) ? previous.lastLogin : ""
        if IsSet(login)
            lastLogin := login
        if lastLogin != "" && !this.ValidTimestamp(lastLogin)
            throw ValueError("Invalid login timestamp.")
        oldAvatar := IsObject(previous) ? previous.avatar : ""
        newAvatar := IsSet(avatar) ? avatar : oldAvatar
        copiedAvatar := ""
        temporary := path "." DllCall("kernel32\GetCurrentProcessId", "UInt") ".tmp"
        stream := 0
        try {
            if newAvatar != "" && newAvatar != oldAvatar {
                copiedAvatar := this.StoreAvatar(newAvatar)
                newAvatar := copiedAvatar
            }
            stream := FileOpen(temporary, "w", "UTF-16")
            if !IsObject(stream)
                throw Error("Could not open the profile file.")
            stream.Write("[Profile]`r`nVersion=1`r`nUsername=" name "`r`nCreated=" created
                "`r`nLastLogin=" lastLogin "`r`nAvatar=" newAvatar "`r`n")
            if !DllCall("kernel32\FlushFileBuffers", "Ptr", stream.Handle, "Int")
                throw OSError(A_LastError)
            stream.Close()
            stream := 0
            saved := this.Load(temporary)
            if !IsObject(saved) || saved.username != name || saved.created != created
                || saved.lastLogin != lastLogin || saved.avatar != newAvatar
                throw Error("The profile could not be verified.")
            if !DllCall("kernel32\MoveFileExW", "Str", temporary, "Str", path, "UInt", 0x9, "Int")
                throw OSError(A_LastError)
            if oldAvatar != newAvatar
                this.RemoveManagedAvatar(oldAvatar)
            return saved
        } catch as profileSaveError {
            if copiedAvatar != ""
                try FileDelete(copiedAvatar)
            throw profileSaveError
        } finally {
            if IsObject(stream)
                stream.Close()
            try FileDelete(temporary)
        }
    }

    static RecordLogin() {
        if !IsObject(this.Current)
            throw Error("Cannot log in without a profile.")
        this.Current := this.Save(this.Current.username, this.Path, this.Current.avatar, A_Now)
        return this.Current
    }

    static ToolbarLayout(width, navEnd, narrow) {
        start := narrow ? 8 : navEnd+8
        available := Max(1, width-start-8)
        identityW := Min(224, available)
        identityX := width-8-identityW
        remaining := Max(0, identityX-start-10)
        onlineW := remaining >= 290 ? 140 : 0
        statusW := Max(0, remaining-onlineW-(onlineW ? 10 : 0))
        return {start: start, identityX: identityX, identityW: identityW,
            onlineX: identityX-10-onlineW, onlineW: onlineW, statusW: statusW,
            y: narrow ? 25 : 3, h: narrow ? 18 : 20}
    }
}
