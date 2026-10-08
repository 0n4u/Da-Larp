FovGuideRadii(mode, fovX, fovY, cameraFov, width, height, scaleX, scaleY) {
    if mode != "degrees"
        return [Max(1, Round(fovX*scaleX)), Max(1, Round(fovY*scaleY))]
    radians := 0.017453292519943295
    vertical := Min(179, Max(1, cameraFov))*radians
    horizontal := 2*ATan(Tan(vertical/2)*(width/Max(1, height)))
    angleX := Min(89, Max(0.05, fovX))*radians
    angleY := Min(89, Max(0.05, fovY))*radians
    return [Max(1, Round(width/2*Tan(angleX)/Tan(horizontal/2))),
        Max(1, Round(height/2*Tan(angleY)/Tan(vertical/2)))]
}

FovInkMatches(color, opacity, target, tolerance) {

    alpha := Min(255, Max(0, opacity))/255
    for shift in [16, 8, 0] {
        channel := (color >> shift) & 255
        wanted := (target >> shift) & 255
        low := Floor(channel*alpha)
        high := Ceil(channel*alpha+255*(1-alpha))
        if high < wanted-tolerance || low > wanted+tolerance
            return false
    }
    return true
}

FovSafeColor(preferred, opacity, targets) {
    for color in [preferred, 0x89B4FA, 0xF38BA8, 0xA6E3A1, 0xFAB387, 0xCBA6F7, 0xF9E2AF] {
        safe := true
        for target in targets {
            if FovInkMatches(color, opacity, target[1], target[2]) {
                safe := false
                break
            }
        }
        if safe
            return color
    }
    return -1
}

OverlayTolerance(path, section, key, fallback) {
    value := IniRead(path, section, key, fallback)
    if !IsNumber(value)
        return fallback
    value := Round(value+0)
    if key != "Tolerance" && value < 0
        return fallback
    return Min(255, Max(0, value))
}

OverlayTargetColors(configPath, stateDir, includeDisabled := false) {
    targets := []
    for section in ["Aimlock", "Camlock", "Triggerbot"] {
        if !includeDisabled && IniRead(configPath,"Modules",section,0) != 1
            continue
        status := stateDir "\" StrLower(section) ".status.ini"
        pid := IniRead(status,"Worker","Pid",0)
        live := IsNumber(pid) && pid > 0 && !!ProcessExist(pid)
        fallback := section = "Aimlock" ? 7 : section = "Camlock" ? 8 : 18
        pendingTolerance := OverlayTolerance(configPath,section,"Tolerance",fallback)
        loadedTolerance := live ? OverlayTolerance(status,"Field","Tolerance",pendingTolerance) : pendingTolerance
        for pair in [["TargetColor","Color","Tolerance"], ["SecondaryColor","Secondary","SecondaryTolerance"],
            ["TertiaryColor","Tertiary","TertiaryTolerance"]] {
            value := Trim(IniRead(configPath,section,pair[1],""))
            if pair[1] = "TargetColor" && !RegExMatch(value,"i)^0x[0-9a-f]{6}$")
                value := "0x000000"
            if RegExMatch(value,"i)^0x[0-9a-f]{6}$")
                targets.Push([value+0,OverlayTolerance(configPath,section,pair[3],pendingTolerance)])
            loaded := live ? IniRead(status,"Field",pair[2],-1) : -1
            if IsNumber(loaded) && loaded >= 0 && loaded <= 0xFFFFFF
                targets.Push([loaded+0,OverlayTolerance(status,"Field",pair[3],loadedTolerance)])
        }
    }
    if includeDisabled || IniRead(configPath,"Modules","WeaponDetection",0) = 1 {
        section := "WeaponDetection"
        status := stateDir "\weapondetection.status.ini"
        pid := IniRead(status,"Worker","Pid",0)
        live := IsNumber(pid) && pid > 0 && !!ProcessExist(pid)
        pendingTolerance := OverlayTolerance(configPath,section,"Tolerance",20)
        loadedTolerance := live ? OverlayTolerance(status,"Weapon","Tolerance",pendingTolerance) : pendingTolerance
        method := StrLower(IniRead(configPath,section,"Method","image"))
        for key in ["Color1","Color2"] {
            value := Trim(IniRead(configPath,section,key,""))
            if method != "image" && key = "Color1" && !RegExMatch(value,"i)^0x[0-9a-f]{6}$")
                value := "0x000000"
            if method != "image" && RegExMatch(value,"i)^0x[0-9a-f]{6}$")
                targets.Push([value+0,pendingTolerance])
            loaded := live ? IniRead(status,"Weapon",key,-1) : -1
            if IsNumber(loaded) && loaded >= 0 && loaded <= 0xFFFFFF
                targets.Push([loaded+0,loadedTolerance])
        }
    }
    return targets
}
