TrackingFindTarget(&outX, &outY, &colorIndex, &centerX, &centerY, &scaleX, &scaleY, &captureFailed) {
    global FovMode, FovX, FovY, CameraFov, Origin, TargetColor, SecondaryColor, Tolerance
    global TrackValid, TrackX, TrackY, TrackSecondary, LastSeenTick, LockRadius, LockHoldMs, SwitchDelayMs
    global TargetReacquired, ScanColors, ScanTolerances, MinPixels, SampleCapturedAt
    static misses := 0
    static previousPolicy := ""
    colorIndex := 0
    TargetReacquired := true
    captureFailed := false
    if !GetClientRect(&left, &top, &width, &height) {
        captureFailed := true
        ResetTracking(true)
        return false
    }
    HandleViewportChange(left, top, width, height)
    GetResolutionScale(width, height, &scaleX, &scaleY)
    policy := TargetEngineField(Origin, FovMode, FovX, FovY, CameraFov, left, top, width, height,
        scaleX, scaleY, &centerX, &centerY, &field, &bounds)
    signature := policy[1] ":" policy[2]
    if previousPolicy != "" && signature != previousPolicy
        ResetTracking(true)
    previousPolicy := signature
    fovLeft := bounds[1], fovTop := bounds[2], fovRight := bounds[3], fovBottom := bounds[4]
    WorkerSignalField(centerX, centerY, field[3], field[4], TargetColor, SecondaryColor, Tolerance, policy[1], policy[2],
        ScanColors[3], ScanTolerances[2], ScanTolerances[3])
    try {
        TargetMarker.RefreshColor()
        frame := TargetEngineCapture(bounds,[left,top,width,height])
        SampleCapturedAt := frame.tick
        if TrackValid && MonotonicMs()-LastSeenTick <= Max(LockHoldMs, SwitchDelayMs) {
            radiusX := Max(2, Round(LockRadius*scaleX)), radiusY := Max(2, Round(LockRadius*scaleY))
            lockBounds := [Max(fovLeft, Round(TrackX)-radiusX), Max(fovTop, Round(TrackY)-radiusY),
                Min(fovRight, Round(TrackX)+radiusX), Min(fovBottom, Round(TrackY)+radiusY)]
            if lockBounds[1] <= lockBounds[3] && lockBounds[2] <= lockBounds[4]
                && TargetEngineFind(frame, field, TrackX, TrackY, ScanColors, ScanTolerances, MinPixels,
                    &outX, &outY, &colorIndex, lockBounds, TrackSecondary) {
                misses := 0
                TargetReacquired := false
                return true
            }
        }
        if TrackValid && MonotonicMs()-LastSeenTick < SwitchDelayMs {
            misses += 1
            return false
        }
        options := WorkerOptions()
        if options["AdaptiveScan"] && !TrackValid && Mod(misses, 3) != 2 {
            scale := misses = 0 ? 0.48 : 0.75
            localBounds := [Max(bounds[1], Round(centerX-field[3]*scale)),
                Max(bounds[2], Round(centerY-field[4]*scale)),
                Min(bounds[3], Round(centerX+field[3]*scale)),
                Min(bounds[4], Round(centerY+field[4]*scale))]
            if TargetEngineFind(frame, field, centerX, centerY, ScanColors, ScanTolerances, MinPixels,
                &outX, &outY, &colorIndex, localBounds) {
                misses := 0
                return true
            }
            misses += 1
            return false
        }
        if TargetEngineFind(frame, field, centerX, centerY, ScanColors, ScanTolerances, MinPixels,
            &outX, &outY, &colorIndex) {
            misses := 0
            return true
        }
        misses += 1
        return false
    } catch {
        captureFailed := true
        ResetTracking(true)
        return false
    }
}

TrackingMotionUnits(desiredX, desiredY, centerX, centerY, scaleX, scaleY, &dx, &dy) {
    global AngularMotion, CameraFov, LastViewportX, LastViewportY, LastViewportW, LastViewportH
    if !AngularMotion {
        dx := (desiredX-centerX)/Max(0.001, scaleX)
        dy := (desiredY-centerY)/Max(0.001, scaleY)
        return
    }
    horizontalFov := VerticalToHorizontalFov(CameraFov, LastViewportW, LastViewportH)
    angleX := PixelAngularDelta(desiredX, centerX, LastViewportX+LastViewportW/2, horizontalFov, LastViewportW)
    angleY := PixelAngularDelta(desiredY, centerY, LastViewportY+LastViewportH/2, CameraFov, LastViewportH)
    calibration := WorkerCameraCalibration()
    dx := AngularInputUnits(angleX, calibration)
    dy := AngularInputUnits(angleY, calibration)
}

TrackingPredictedLead(velocity, leadMs, sampleAgeMs, maxLead, samples, sampleGapMs) {
    if samples < 3 || maxLead <= 0 || leadMs <= 0 || sampleGapMs > 80
        return 0.0
    age := Min(32.0, Max(0.0, sampleAgeMs))
    horizon := Min(80.0, Max(0.0, leadMs + age))
    confidence := Min(1.0, Max(0.0, (samples-2)/4.0))
    if sampleGapMs > 25
        confidence *= Max(0.0, 1.0-(sampleGapMs-25)/55.0)
    return Max(-maxLead, Min(maxLead, velocity*horizon*confidence))
}

PredictionCurveGain(speed, low, mid, high) {
    speed := Max(0.0, Abs(speed))
    if speed <= 0.4
        return low+(mid-low)*speed/0.4
    return mid+(high-mid)*Min(1.0,(speed-0.4)/1.2)
}

TrackingAdvancedLead(velocity, acceleration, leadMs, sampleAgeMs, maxLead,
    samples, gap, curveLow, curveMid, curveHigh, accelGain) {
    if samples < 3 || leadMs <= 0 || maxLead <= 0 || gap <= 0 || gap > 80
        return 0.0
    horizon := Min(80.0,Max(0.0,leadMs+Min(32.0,Max(0.0,sampleAgeMs))))
    confidence := Min(1.0, Max(0.0,(samples-2)/4.0))
    if gap > 25
        confidence *= Max(0.0,1.0-(gap-25)/55.0)
    motion := velocity*horizon*PredictionCurveGain(velocity,curveLow,curveMid,curveHigh)
    motion += 0.5*acceleration*horizon*horizon*accelGain
    return Max(-maxLead,Min(maxLead,motion*confidence))
}
