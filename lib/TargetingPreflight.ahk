WorkerTargetingProbeRequested() {
    return A_Args.Length > 0 && A_Args[1] = "--targeting-preflight"
}

WorkerTargetingProbe(name, colors, tolerances, support, tracking := unset) {
    if !IsObject(colors) || !IsObject(tolerances) || colors.Length != 3 || tolerances.Length != 3
        throw Error("Three initialized color and tolerance profiles are required")
    for index, color in colors {
        if !IsInteger(color) || color < (index = 1 ? 0 : -1) || color > 0xFFFFFF
            throw Error("Invalid initialized color profile " index)
        if !IsInteger(tolerances[index]) || tolerances[index] < 0 || tolerances[index] > 255
            throw Error("Invalid initialized tolerance " index)
    }
    if !IsInteger(support) || support < 1 || support > 9
        throw Error("Invalid initialized match support")
    fovRadii := FovGuideRadii("pixels", 7, 9, 85, 1920, 1080, 1, 1)
    if fovRadii[1] != 7 || fovRadii[2] != 9
        throw Error("Targeting FOV geometry helper unavailable")
    if IsSet(tracking) {
        if tracking["AngularMotion"] != 0 && tracking["AngularMotion"] != 1
            throw Error("Angular motion is not initialized")
        for key in ["TertiaryOffsetX","TertiaryOffsetY"]
            if !IsInteger(tracking[key]) || Abs(tracking[key]) > 500
                throw Error("Invalid initialized " key)
        if tracking["SampleCapturedAt"] != 0
            throw Error("Tracking sample timestamp is not initialized")
    }
    TargetSnapshot.Init()
    TargetSnapshot.InitAdvanced()
    pixels := Buffer(5*5*4, 0)
    Loop 25
        NumPut("UInt",colors[1],pixels,(A_Index-1)*4)
    frame := {left:-2,top:-2,width:5,height:5,tick:0,pixels:pixels.Ptr}
    field := [0,0,2,2,"circle"]
    if !TargetSnapshot.Find(frame,field,0,0,colors,tolerances,support,&x,&y,&index)
        || x != 0 || y != 0 || index != 0
        throw Error("Initialized worker settings failed the native scan probe")
    field := [0,0,2,2,"triangle"]
    if !TargetSnapshot.AdvancedFind(frame,field,0,0,colors,tolerances,support,
        &advancedX,&advancedY,&advancedColor,[-2,-2,2,2])
        || advancedX != 0 || advancedY != 0 || advancedColor != 0
        throw Error("Advanced polygon scanner failed the native preflight")
    FileAppend("PASS: " name " initialized settings, polygon scanner and color detector`n","*")
    return true
}
