TargetEngineField(origin, fovMode, fovX, fovY, cameraFov, left, top, width, height, scaleX, scaleY,
    &centerX, &centerY, &field, &bounds) {
    targetPolicy := EffectiveTargetField(origin)
    GetTargetOrigin(targetPolicy[1], left, top, width, height, &centerX, &centerY)
    fieldRadii := ShapeFieldRadii(targetPolicy[2], FovGuideRadii(fovMode, fovX, fovY, cameraFov, width, height, scaleX, scaleY))
    field := [centerX, centerY, fieldRadii[1], fieldRadii[2], targetPolicy[2]]
    bounds := [Max(left, centerX-fieldRadii[1]), Max(top, centerY-fieldRadii[2]),
        Min(left+width-1, centerX+fieldRadii[1]), Min(top+height-1, centerY+fieldRadii[2])]
    return targetPolicy
}

TargetEngineCaptureBounds(bounds,viewport,rejectEnabled) {
    if bounds.Length != 4 || viewport.Length != 4
        throw Error("Invalid targeting capture geometry")
    if bounds[1] > bounds[3] || bounds[2] > bounds[4] || viewport[3] < 1 || viewport[4] < 1
        throw Error("Targeting rectangle is outside the active viewport")
    padding := rejectEnabled && (bounds[3]-bounds[1] < 50 || bounds[4]-bounds[2] < 50) ? 25 : 0
    left := Max(viewport[1],bounds[1]-padding)
    top := Max(viewport[2],bounds[2]-padding)
    right := Min(viewport[1]+viewport[3]-1,bounds[3]+padding)
    bottom := Min(viewport[2]+viewport[4]-1,bounds[4]+padding)
    if right < left || bottom < top
        throw Error("Capture is outside the active viewport")
    return [left,top,right,bottom]
}

TargetEngineCapture(bounds,viewport := unset) {
    if !IsSet(viewport)
        viewport := [bounds[1],bounds[2],bounds[3]-bounds[1]+1,bounds[4]-bounds[2]+1]
    options := WorkerOptions()
    captureBounds := TargetEngineCaptureBounds(bounds,viewport,options["BackgroundReject"])
    return TargetSnapshot.Capture(captureBounds[1],captureBounds[2],captureBounds[3],captureBounds[4])
}

TargetEngineFind(frame, field, referenceX, referenceY, colors, tolerances, support,
    &targetX, &targetY, &colorIndex, bounds := unset, preferred := -1) {
    if !IsSet(bounds)
        bounds := [frame.left, frame.top, frame.left+frame.width-1, frame.top+frame.height-1]
    if bounds[1] > bounds[3] || bounds[2] > bounds[4]
        return false
    if colors.Length != 3 || tolerances.Length != 3 || support < 1 || support > 9
        throw Error("Invalid color detection profile")
    return TargetSnapshot.AdvancedFind(frame, field, referenceX, referenceY, colors, tolerances,
        support, &targetX, &targetY, &colorIndex, bounds, preferred)
}
