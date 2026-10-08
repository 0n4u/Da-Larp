#Requires AutoHotkey v2.0.18+
#SingleInstance Off
#NoTrayIcon
#Warn All, StdOut
Persistent

global GuardRoot := RegExReplace(A_ScriptDir, "i)\\tools$", "")
global GuardState := GuardRoot "\state"
global GuardReady := GuardState "\guardian.ready"
global GuardError := GuardState "\guardian.error"
global GuardJob := 0
global GuardMainPid := 0
global GuardMainHandle := 0
global GuardWorkers := Map()
global GuardMissingPid := 0
global GuardMissingTick := 0
global GuardPid := DllCall("kernel32\GetCurrentProcessId", "UInt")
global GuardRoster := GuardState "\guardian." GuardPid ".roster"

try {
    GuardStart()
    Loop {
        Sleep(200)
        if !GuardPoll()
            ExitApp(0)
    }
} catch as guardianFault {
    try FileAppend(guardianFault.Message, GuardError, "UTF-8")
    ExitApp(1)
}

GuardStart() {
    global GuardRoot, GuardState, GuardReady, GuardError, GuardJob, GuardMainHandle, GuardMainPid, GuardPid, GuardRoster
    DirCreate(GuardState)
    try FileDelete(GuardError)
    try FileDelete(GuardReady)
    try FileDelete(GuardRoster)
    job := DllCall("kernel32\CreateJobObjectW", "Ptr", 0, "Ptr", 0, "Ptr")
    if !job
        throw OSError(A_LastError)
    GuardJob := job
    OnExit(GuardShutdown)
    limits := Buffer(144, 0)
    NumPut("UInt", 0x2000, limits, 16)
    if !DllCall("kernel32\SetInformationJobObject", "Ptr", job, "Int", 9, "Ptr", limits.Ptr, "UInt", limits.Size, "Int")
        throw OSError(A_LastError)
    IniWrite(GuardPid, GuardReady, "Guardian", "Pid")
    IniWrite(0, GuardReady, "Guardian", "Main")
    command := Chr(34) A_AhkPath Chr(34) " " Chr(34) GuardRoot "\DaHoodSuite.ahk" Chr(34)
    startup := Buffer(104, 0)
    NumPut("UInt", startup.Size, startup, 0)
    processInfo := Buffer(24, 0)
    commandBuffer := Buffer(StrPut(command, "UTF-16") * 2, 0)
    StrPut(command, commandBuffer, "UTF-16")
    if !DllCall("kernel32\CreateProcessW", "Ptr", 0, "Ptr", commandBuffer.Ptr,
        "Ptr", 0, "Ptr", 0, "Int", 0, "UInt", 0x00000004,
        "Ptr", 0, "Str", GuardRoot, "Ptr", startup.Ptr, "Ptr", processInfo.Ptr, "Int")
        throw OSError(A_LastError)
    GuardMainHandle := NumGet(processInfo, 0, "Ptr")
    threadHandle := NumGet(processInfo, 8, "Ptr")
    GuardMainPid := NumGet(processInfo, 16, "UInt")
    try {
        if !DllCall("kernel32\AssignProcessToJobObject", "Ptr", job, "Ptr", GuardMainHandle, "Int")
            throw OSError(A_LastError)
        if DllCall("kernel32\ResumeThread", "Ptr", threadHandle, "UInt") = 0xFFFFFFFF
            throw OSError(A_LastError)
    } catch as startupFault {
        DllCall("kernel32\TerminateProcess", "Ptr", GuardMainHandle, "UInt", 1)
        throw startupFault
    } finally {
        DllCall("kernel32\CloseHandle", "Ptr", threadHandle)
    }
    IniWrite(GuardMainPid, GuardReady, "Guardian", "Main")
}

GuardPoll() {
    global GuardMainHandle, GuardRoster, GuardWorkers, GuardMissingPid, GuardMissingTick
    if DllCall("kernel32\WaitForSingleObject", "Ptr", GuardMainHandle, "UInt", 0, "UInt") != 0x102
        return false
    expected := GuardExpectedWorkers(GuardRoster)
    for pid, handle in GuardWorkers.Clone() {
        if !expected.Has(pid) {
            if handle
                DllCall("kernel32\CloseHandle", "Ptr", handle)
            GuardWorkers.Delete(pid)
        }
    }
    for pid, _ in expected {
        if !GuardWorkers.Has(pid)
            GuardWorkers[pid] := DllCall("kernel32\OpenProcess", "UInt", 0x00100000, "Int", 0, "UInt", pid, "Ptr")
    }
    missing := 0
    for pid, handle in GuardWorkers {
        if !handle || DllCall("kernel32\WaitForSingleObject", "Ptr", handle, "UInt", 0, "UInt") != 0x102 {
            missing := pid
            break
        }
    }
    if !missing {
        GuardMissingPid := 0
        return true
    }
    if GuardMissingPid != missing {
        GuardMissingPid := missing
        GuardMissingTick := A_TickCount
        return true
    }
    if A_TickCount - GuardMissingTick < GuardRecoveryGrace(GuardRoster)
        return true
    if GuardExpectedWorkers(GuardRoster).Has(missing)
        return false
    GuardMissingPid := 0
    return true
}

GuardRecoveryGrace(path) {
    try payload := FileRead(path,"UTF-8")
    catch
        return 450
    return RegExMatch(payload,"m)^recover=1\r?$") ? 5000 : 450
}

GuardExpectedWorkers(path) {
    expected := Map()
    if !FileExist(path)
        return expected
    try payload := FileRead(path, "UTF-8")
    catch
        return expected
    for _, line in StrSplit(payload, "`n", "`r") {
        if RegExMatch(Trim(line), "^worker=(\d+)$", &match)
            expected[Integer(match[1])] := true
    }
    return expected
}

GuardShutdown(*) {
    global GuardJob, GuardMainHandle, GuardWorkers, GuardReady, GuardRoster
    for _, handle in GuardWorkers {
        if handle
            DllCall("kernel32\CloseHandle", "Ptr", handle)
    }
    if GuardMainHandle
        DllCall("kernel32\CloseHandle", "Ptr", GuardMainHandle)
    if GuardJob
        DllCall("kernel32\CloseHandle", "Ptr", GuardJob)
    try FileDelete(GuardReady)
    try FileDelete(GuardRoster)
}
