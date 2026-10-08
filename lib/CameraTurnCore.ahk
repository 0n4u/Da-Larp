CameraTurnUnits(angle, unitsPer360, referenceSensitivity, sensitivity, scaleDpi, referenceDpi, dpi) {
    if unitsPer360 <= 0 || sensitivity <= 0 || referenceSensitivity <= 0 || referenceDpi <= 0 || dpi <= 0
        throw Error("Camera-turn calibration must be positive")
    units := angle/360*unitsPer360*referenceSensitivity/sensitivity
    if scaleDpi
        units *= dpi/referenceDpi
    if Abs(units) > 60000
        throw Error("Turn exceeds 60000 input units; check calibration")
    return Round(units)
}

CameraTurnPosition(total, elapsed, duration, curve) {
    progress := duration <= 0 ? 1 : Min(1, Max(0, elapsed/duration))
    if curve = "eased"
        progress := 1-(1-progress)**3
    return Round(total*progress)
}
