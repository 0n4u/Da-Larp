class InputOwnership {
    static LocalOwners := Map()
    __New(sender, scope := "Local\DaLarp.Input.v1") {
        this.Sender := sender
        this.Scope := scope
        this.Held := Map()
    }
    Canonical(key) {
        name := StrLower(GetKeyName(key))
        if name = "" || RegExMatch(name, "i)^wheel")
            throw Error("Invalid held output key: " key)
        return name
    }
    Down(key) {
        key := this.Canonical(key)
        resource := this.Scope "." key
        previous := A_IsCritical
        Critical("On")
        try {
            if InputOwnership.LocalOwners.Has(resource)
                return false
            handle := DllCall("kernel32\CreateMutexW", "Ptr", 0, "Int", 0, "Str", resource, "Ptr")
            if !handle
                return false
            result := DllCall("kernel32\WaitForSingleObject", "Ptr", handle, "UInt", 0, "UInt")
            if result != 0 && result != 0x80 {
                DllCall("kernel32\CloseHandle", "Ptr", handle)
                return false
            }
            this.Held[key] := handle
            InputOwnership.LocalOwners[resource] := true
            try this.Sender.Call(key, true)
            catch as err {
                this.Forget(key)
                throw err
            }
            return true
        } finally Critical(previous)
    }
    Up(key) {
        key := this.Canonical(key)
        previous := A_IsCritical
        Critical("On")
        try {
            if !this.Held.Has(key)
                return false
            try this.Sender.Call(key, false)
            finally this.Forget(key)
            return true
        } finally Critical(previous)
    }
    Forget(key) {
        handle := this.Held[key]
        this.Held.Delete(key)
        InputOwnership.LocalOwners.Delete(this.Scope "." key)
        DllCall("kernel32\ReleaseMutex", "Ptr", handle)
        DllCall("kernel32\CloseHandle", "Ptr", handle)
    }
    ReleaseAll() {
        keys := []
        for key in this.Held
            keys.Push(key)
        for key in keys
            try this.Up(key)
    }
}

WorkerInputOwner() {
    static owner := InputOwnership((key, down) => SendEvent("{Blind}{" key (down ? " down}" : " up}")))
    return owner
}
WorkerKeyDown(key) {
    return WorkerInputOwner().Down(key)
}
WorkerKeyUp(key) {
    return WorkerInputOwner().Up(key)
}
WorkerReleaseInputs(*) {
    WorkerInputOwner().ReleaseAll()
}
