TargetOriginPoint(mode, left, top, width, height, mouseX := 0, mouseY := 0) {
    if mode != "cursor"
        return [left+Floor(width/2), top+Floor(height/2)]
    return [Max(left, Min(left+width-1, Round(mouseX))),
        Max(top, Min(top+height-1, Round(mouseY)))]
}

GetTargetOrigin(mode, left, top, width, height, &centerX, &centerY) {
    mouseX := 0
    mouseY := 0
    if mode = "cursor" {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
    }
    originCoords := TargetOriginPoint(mode, left, top, width, height, mouseX, mouseY)
    centerX := originCoords[1]
    centerY := originCoords[2]
}

EffectiveTargetField(configuredOrigin) {
    options := WorkerOptions()
    return ResolveTargetField(configuredOrigin, options["FOVEnabled"], options["FOVOrigin"], options["FOVShape"])
}

ResolveTargetField(configuredOrigin, guideEnabled, guideOrigin, guideShape) {
    if guideEnabled
        return [guideOrigin = "cursor" ? "cursor" : "camera", guideShape]
    return [configuredOrigin, "rectangle"]
}

ShapeFieldRadii(shape, radii) {
    if shape = "circle"
        return [Max(radii[1], radii[2]), Max(radii[1], radii[2])]
    return radii
}
