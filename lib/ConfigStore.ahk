class ConfigStore {
    static FullPath(path) {
        size := DllCall("kernel32\GetFullPathNameW", "Str", path, "UInt", 0, "Ptr", 0, "Ptr", 0, "UInt")
        if !size
            throw OSError()
        pathBuffer := Buffer(size*2,0)
        if !DllCall("kernel32\GetFullPathNameW", "Str", path, "UInt", size, "Ptr", pathBuffer, "Ptr", 0, "UInt")
            throw OSError()
        return StrGet(pathBuffer)
    }

    static IsSamePath(a,b) => StrLower(this.FullPath(a)) = StrLower(this.FullPath(b))

    static Apply(path, mutate, validate := 0, prepare := 0, activate := 0, recover := 0, backupPath := "") {
        path := this.FullPath(path)
        token := DllCall("GetCurrentProcessId","UInt") "-" A_TickCount "-" Random(100000,999999)
        stage := path ".stage-" token ".tmp"
        rollback := path ".rollback-" token ".tmp"
        prepared := false, replaced := false, preserveRollback := false
        try {
            FileCopy(path, rollback, false)
            FileCopy(path, stage, false)
            mutate.Call(stage)
            if IsObject(validate)
                validate.Call(stage)
            if backupPath != "" && DirExist(backupPath)
                throw Error("Recovery backup destination is a directory")
            if backupPath != ""
                FileCopy(rollback,backupPath,true)
            prepared := true
            if IsObject(prepare)
                prepare.Call(path)
            FileMove(stage,path,true)
            replaced := true
            if IsObject(activate)
                activate.Call(path)
            return true
        } catch as transactionError {
            if replaced {
                try FileCopy(rollback,path,true)
                catch as rollbackError {
                    preserveRollback := true
                    throw Error(transactionError.Message " / rollback failed: " rollbackError.Message " / recovery copy: " rollback)
                }
            }
            if prepared && IsObject(recover) {
                try recover.Call(path)
                catch as recoveryError
                    throw Error(transactionError.Message " / runtime recovery failed: " recoveryError.Message)
            }
            throw transactionError
        } finally {
            try FileDelete(stage)
            if !preserveRollback
                try FileDelete(rollback)
        }
    }

    static MergeSections(stage, source, factory, sections) {
        values := Map()
        for section in sections {
            defaults := IniRead(factory,section,,"__missing__")
            if defaults = "__missing__"
                throw Error("Factory config is missing section " section)
            values[section] := [defaults,IniRead(source,section,,"")]
        }
        for section, pairs in values {
            try IniDelete(stage,section)
            IniWrite(pairs[1],stage,section)
            if Trim(pairs[2]) != ""
                IniWrite(pairs[2],stage,section)
        }
    }
}
