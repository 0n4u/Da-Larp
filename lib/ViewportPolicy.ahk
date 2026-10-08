ViewportPreferMonitor(monitorOk,geometryFullscreen,styleFullscreen,hintKnown,hint,lastToggleTick,nowTick) {
    if !monitorOk
        return false
    if geometryFullscreen || styleFullscreen
        return true
    return hintKnown && hint && lastToggleTick > 0
        && nowTick >= lastToggleTick && nowTick-lastToggleTick <= 650
}
