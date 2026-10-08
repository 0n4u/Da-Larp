MonotonicMs() {
    static frequency := 0
    if frequency <= 0 {
        if !DllCall("QueryPerformanceFrequency", "Int64*", &frequency) || frequency <= 0
            throw Error("QueryPerformanceFrequency failed")
    }
    counter := 0
    if !DllCall("QueryPerformanceCounter", "Int64*", &counter)
        throw Error("QueryPerformanceCounter failed")
    return counter * 1000.0 / frequency
}

TimeGain(strength, response, dtMs, referenceMs) {
    if dtMs <= 0 || referenceMs <= 0
        return 0.0
    base := Min(0.99, Max(0.0, strength * response))
    return 1.0 - (1.0 - base) ** (Min(50, dtMs) / referenceMs)
}

TemporalBlend(blend, dtMs, referenceMs) {

    if dtMs <= 0 || referenceMs <= 0
        return 0.0
    blend := Min(1.0, Max(0.0, blend))
    return 1.0 - (1.0-blend) ** (Min(50, dtMs)/referenceMs)
}

LimitMotion(&dx, &dy, maxStep) {
    length := Sqrt(dx*dx+dy*dy)
    if length > maxStep && length > 0 {
        ratio := Max(0.0, maxStep)/length
        dx *= ratio
        dy *= ratio
    }
}

QuantizeMotion(rawX, rawY, maxStep, &residualX, &residualY, &moveX, &moveY) {
    if rawX*residualX < 0
        residualX := 0.0
    if rawY*residualY < 0
        residualY := 0.0
    residualX += rawX
    residualY += rawY
    LimitMotion(&residualX, &residualY, maxStep)
    moveX := residualX >= 0 ? Floor(residualX) : Ceil(residualX)
    moveY := residualY >= 0 ? Floor(residualY) : Ceil(residualY)
    residualX -= moveX
    residualY -= moveY
}

PixelAngularDelta(target, origin, cameraCenter, cameraFov, dimension) {
    radians := 0.017453292519943295
    focal := Max(1, dimension)/2/Tan(Min(179, Max(1, cameraFov))*radians/2)
    return (ATan((target-cameraCenter)/focal)-ATan((origin-cameraCenter)/focal))/radians
}

AngularInputUnits(angle, calibration) {
    units := angle/360*calibration["UnitsPer360"]*calibration["ReferenceSensitivity"]/calibration["Sensitivity"]
    if calibration["DpiScaling"]
        units *= calibration["Dpi"]/calibration["ReferenceDpi"]
    return units
}

TriggerSameTarget(x, y, color, previousX, previousY, previousColor, radius, scaleX := 1, scaleY := 1) {
    dx := (x-previousX)/Max(0.001, scaleX)
    dy := (y-previousY)/Max(0.001, scaleY)
    return color = previousColor && dx*dx+dy*dy <= radius*radius
}

EnablePhysicalPixelCoordinates() {

    previous := 0
    try previous := DllCall("user32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    if !previous {
        try DllCall("user32\SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")
    }
}

NearestColor(x1, y1, x2, y2, refX, refY, color, tolerance, &outX, &outY, &captureFailed := unset) {
    captureFailed := false
    if x1 > x2 || y1 > y2
        return false

    refX := Min(x2, Max(x1, Round(refX)))
    refY := Min(y2, Max(y1, Round(refY)))
    found := false
    bestDist := 0.0

    rects := [
        [refX, refY, x2, y2],
        [refX, refY, x1, y2],
        [refX, refY, x2, y1],
        [refX, refY, x1, y1]
    ]

    for rect in rects {
        try {
            if PixelSearch(&px, &py, rect[1], rect[2], rect[3], rect[4], color, tolerance) {
                dist := (px - refX) ** 2 + (py - refY) ** 2
                if !found || dist < bestDist {
                    found := true
                    bestDist := dist
                    bestX := px
                    bestY := py
                }
            }
        } catch {
            captureFailed := true
            return false
        }
    }

    if found {
        outX := bestX
        outY := bestY
        return true
    }
    return false
}

NearestColorProgressive(x1, y1, x2, y2, refX, refY, color, tolerance, quality, &outX, &outY, &captureFailed := unset) {
    captureFailed := false
    if x1 > x2 || y1 > y2
        return false

    quality := StrLower(quality)
    fractions := quality = "precise" ? [0.45, 1.0] : (quality = "balanced" ? [0.65, 1.0] : [1.0])
    halfW := Max(1, Max(Abs(refX - x1), Abs(x2 - refX)))
    halfH := Max(1, Max(Abs(refY - y1), Abs(y2 - refY)))

    for fraction in fractions {
        sx1 := Max(x1, Round(refX - halfW * fraction))
        sy1 := Max(y1, Round(refY - halfH * fraction))
        sx2 := Min(x2, Round(refX + halfW * fraction))
        sy2 := Min(y2, Round(refY + halfH * fraction))
        if NearestColor(sx1, sy1, sx2, sy2, refX, refY, color, tolerance, &outX, &outY, &failed)
            return true
        if failed {
            captureFailed := true
            return false
        }
    }
    return false
}

TrackingScaledOffsets(colorIndex,scaleX,scaleY,primaryX,primaryY,secondaryX,secondaryY,tertiaryX,tertiaryY) {
    x := colorIndex = 2 ? tertiaryX : colorIndex = 1 ? secondaryX : primaryX
    y := colorIndex = 2 ? tertiaryY : colorIndex = 1 ? secondaryY : primaryY
    return [x*scaleX,y*scaleY]
}
