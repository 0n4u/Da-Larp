GetPreset(section, name) {
    if section = "CameraTurn" {
        if name = "Quarter Turn"
            return Map("Angle", 90, "DurationMs", 120, "Curve", "eased")
        if name = "Half Turn"
            return Map("Angle", 180, "DurationMs", 180, "Curve", "eased")
        if name = "Full Turn"
            return Map("Angle", 360, "DurationMs", 300, "Curve", "eased")
    }
    values := PresetValues(section, name)
    if section = "Movement" && !values.Has("StepMode")
        values["StepMode"] := "cycle"
    if section = "Camlock" || section = "Aimlock" || section = "Triggerbot" {
        values["Hotkey"] := "RButton"
        values["Mode"] := "hold"
        values["TargetColor"] := "0x000000"
        values["SecondaryColor"] := ""
        values["TertiaryColor"] := ""
        values["ReferenceWidth"] := 1920
        values["ReferenceHeight"] := 1080
        if section = "Triggerbot"
            values["IgnoreHeldClick"] := 1
        else if name = "Rage" || name = "Aggressive" {

            values["VelocityBlend"] := section = "Camlock" ? 0.28 : 0.26
            values["MaxLeadPx"] := section = "Camlock" ? 18 : 16
        }
    }
    return values
}

PresetValues(section, name) {
    if section = "Movement" && name = "First Person"
        return Map("Mode", "hold", "StepMode", "actions", "StepMs", 15, "MiddleTaps", 2, "WheelUp", 1, "WheelDown", 1)
    if section = "Movement" && name = "Wheel Toggle"
        return Map("Mode", "toggle", "StepMode", "actions", "StepMs", 10, "MiddleTaps", 0, "WheelUp", 1, "WheelDown", 1)
    if section = "WallHop" {
        if name = "Original Flick" || name = "Semi Rage"
            return Map("DistancePx", 35, "ReturnMs", 4, "CooldownMs", 120)
        if name = "Gentle Flick" || name = "Legit"
            return Map("DistancePx", 25, "ReturnMs", 8, "CooldownMs", 180)
        if name = "Wide Flick" || name = "Rage"
            return Map("DistancePx", 50, "ReturnMs", 2, "CooldownMs", 90)
    }
    if section = "KeyRepeat" {
        if name = "Stomp Repeat"
            return Map("OutputKey", "e", "Mode", "hold", "IntervalMs", 120, "HoldMs", 8)
        if name = "Bunny Hop"
            return Map("OutputKey", "Space", "Mode", "hold", "IntervalMs", 100, "HoldMs", 20)
        if name = "Reload Repeat"
            return Map("OutputKey", "r", "Mode", "hold", "IntervalMs", 300, "HoldMs", 12)
        if name = "Q Spam"
            return Map("OutputKey", "q", "Mode", "hold", "IntervalMs", 30, "HoldMs", 8)
        if name = "Legit"
            return Map("IntervalMs", 120, "HoldMs", 8)
        if name = "Semi Rage"
            return Map("IntervalMs", 70, "HoldMs", 8)
        if name = "Rage"
            return Map("IntervalMs", 35, "HoldMs", 6)
    }
    if section = "Recoil" {
        if name = "Gentle" || name = "Legit"
            return Map("PullX", 0, "PullY", 1, "IntervalMs", 10, "MaxStep", 12, "RequireAim", 1)
        if name = "Balanced" || name = "Semi Rage"
            return Map("PullX", 0, "PullY", 2, "IntervalMs", 10, "MaxStep", 12, "RequireAim", 1)
        if name = "Strong" || name = "Rage"
            return Map("PullX", 0, "PullY", 4, "IntervalMs", 10, "MaxStep", 16, "RequireAim", 1)
    }
    if section = "FOV" {
        if name = "Circle"
            return Map("Shape", "circle", "Color", "0xFFFFFF", "Opacity", 255, "Thickness", 1)
        if name = "Ellipse"
            return Map("Shape", "ellipse", "Color", "0xFFFFFF", "Opacity", 255, "Thickness", 1)
        if name = "Exact Box"
            return Map("Shape", "rectangle", "Color", "0xFFFFFF", "Opacity", 255, "Thickness", 1)
    }

    if section = "Movement" && name = "Balanced"
        return Map("StepMs", 12, "MiddleTaps", 2, "WheelUp", 1, "WheelDown", 1)
    if section = "Movement" && name = "Quick"
        return Map("StepMs", 10, "MiddleTaps", 2, "WheelUp", 1, "WheelDown", 1)
    if section = "Movement" && name = "Reliable"
        return Map("StepMs", 14, "MiddleTaps", 2, "WheelUp", 1, "WheelDown", 1)
    if section = "GunSpam" && name = "Balanced"
        return Map("IntervalMs", 4, "ClickHoldMs", 0)
    if section = "GunSpam" && name = "Rapid"
        return Map("IntervalMs", 3, "ClickHoldMs", 0)
    if section = "GunSpam" && name = "Reliable"
        return Map("IntervalMs", 5, "ClickHoldMs", 1)
    if section = "Emote" && name = "Balanced"
        return Map("OpenMs", 38, "BetweenMs", 72, "FinalMs", 165, "PressCount", 4)
    if section = "Emote" && name = "Quick"
        return Map("OpenMs", 34, "BetweenMs", 64, "FinalMs", 145, "PressCount", 4)
    if section = "Emote" && name = "Reliable"
        return Map("OpenMs", 45, "BetweenMs", 80, "FinalMs", 180, "PressCount", 4)
    if section = "SOCD" && name = "Arrows Last"
        return Map("Mode", "last", "Left", "Left", "Right", "Right", "Up", "Up", "Down", "Down")
    if section = "SOCD" && name = "WASD Last"
        return Map("Mode", "last", "Left", "a", "Right", "d", "Up", "w", "Down", "s")
    if section = "SOCD" && name = "WASD Neutral"
        return Map("Mode", "neutral", "Left", "a", "Right", "d", "Up", "w", "Down", "s")

    if section = "Movement" && name = "Legit"
        return GetPreset("Movement", "Reliable")
    if section = "Movement" && name = "Semi Rage"
        return GetPreset("Movement", "Balanced")
    if section = "Movement" && name = "Rage"
        return GetPreset("Movement", "Quick")
    if section = "GunSpam" && name = "Legit"
        return GetPreset("GunSpam", "Reliable")
    if section = "GunSpam" && name = "Semi Rage"
        return GetPreset("GunSpam", "Balanced")
    if section = "GunSpam" && name = "Rage"
        return GetPreset("GunSpam", "Rapid")
    if section = "Emote" && name = "Legit"
        return GetPreset("Emote", "Reliable")
    if section = "Emote" && name = "Semi Rage"
        return GetPreset("Emote", "Balanced")
    if section = "Emote" && name = "Rage"
        return GetPreset("Emote", "Quick")
    if section = "SOCD" && name = "Legit"
        return GetPreset("SOCD", "WASD Neutral")
    if section = "SOCD" && name = "Semi Rage"
        return GetPreset("SOCD", "WASD Last")
    if section = "SOCD" && name = "Rage"
        return GetPreset("SOCD", "WASD Last")

    if section = "Triggerbot" && name = "Legit"
        return Map("ScaleMode", "auto", "FovX", 2, "FovY", 2, "Tolerance", 18, "ScanMs", 4, "FireMode", "edge", "ConfirmScans", 3, "RearmMs", 30, "PostFireMs", 1, "ClickHoldMs", 9, "CooldownMs", 50, "ConfirmMs", 14)

    if section = "Triggerbot" && name = "Semi Rage"
        return Map("ScaleMode", "auto", "FovX", 4, "FovY", 4, "Tolerance", 30, "ScanMs", 3, "FireMode", "repeat", "ConfirmScans", 2, "RearmMs", 12, "PostFireMs", 0, "ClickHoldMs", 6, "CooldownMs", 24, "ConfirmMs", 6)

    if section = "Triggerbot" && name = "Rage"
        return Map("ScaleMode", "auto", "FovX", 6, "FovY", 6, "Tolerance", 42, "ScanMs", 2, "FireMode", "repeat", "ConfirmScans", 1, "RearmMs", 0, "PostFireMs", 0, "ClickHoldMs", 4, "CooldownMs", 10, "ConfirmMs", 0)

    if section = "Camlock" && name = "Legit"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 85, "FovY", 65, "Tolerance", 8, "ScanMs", 5, "StrengthX", 0.12, "StrengthY", 0.11, "ResponseCurve", "smooth", "PredictionEnabled", 0, "LeadMsX", 6, "LeadMsY", 4, "VelocityBlend", 0.22, "MaxLeadPx", 8, "MaxStep", 24, "Deadzone", 1.5, "LockRadius", 34, "LockHoldMs", 85, "OffsetX", 0, "OffsetY", 5, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 5)
    if section = "Camlock" && name = "Semi Rage"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 145, "FovY", 110, "Tolerance", 12, "ScanMs", 3, "StrengthX", 0.28, "StrengthY", 0.26, "ResponseCurve", "linear", "PredictionEnabled", 0, "LeadMsX", 10, "LeadMsY", 8, "VelocityBlend", 0.30, "MaxLeadPx", 12, "MaxStep", 56, "Deadzone", 0.5, "LockRadius", 48, "LockHoldMs", 70, "OffsetX", 0, "OffsetY", 5, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 4)
    if section = "Camlock" && name = "Rage"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 240, "FovY", 180, "Tolerance", 16, "ScanMs", 2, "StrengthX", 0.58, "StrengthY", 0.54, "ResponseCurve", "aggressive", "PredictionEnabled", 1, "LeadMsX", 12, "LeadMsY", 10, "VelocityBlend", 0.34, "MaxLeadPx", 22, "MaxStep", 115, "Deadzone", 0, "LockRadius", 72, "LockHoldMs", 45, "OffsetX", 0, "OffsetY", 4, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 3)

    if section = "Aimlock" && name = "Legit"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 50, "FovY", 40, "Tolerance", 7, "ScanMs", 4, "StrengthX", 0.28, "StrengthY", 0.26, "ResponseCurve", "smooth", "PredictionEnabled", 0, "LeadMsX", 5, "LeadMsY", 4, "VelocityBlend", 0.20, "MaxLeadPx", 8, "MaxStep", 46, "Deadzone", 0.75, "LockRadius", 24, "LockHoldMs", 65, "OffsetX", 0, "OffsetY", 5, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 4)
    if section = "Aimlock" && name = "Semi Rage"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 90, "FovY", 70, "Tolerance", 10, "ScanMs", 3, "StrengthX", 0.50, "StrengthY", 0.47, "ResponseCurve", "linear", "PredictionEnabled", 0, "LeadMsX", 8, "LeadMsY", 6, "VelocityBlend", 0.28, "MaxLeadPx", 12, "MaxStep", 80, "Deadzone", 0.25, "LockRadius", 34, "LockHoldMs", 55, "OffsetX", 0, "OffsetY", 5, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 3)
    if section = "Aimlock" && name = "Rage"
        return Map("ScaleMode", "auto", "FovMode", "pixels", "FovX", 180, "FovY", 140, "Tolerance", 15, "ScanMs", 2, "StrengthX", 0.90, "StrengthY", 0.86, "ResponseCurve", "aggressive", "PredictionEnabled", 1, "LeadMsX", 10, "LeadMsY", 8, "VelocityBlend", 0.32, "MaxLeadPx", 20, "MaxStep", 160, "Deadzone", 0, "LockRadius", 60, "LockHoldMs", 35, "OffsetX", 0, "OffsetY", 4, "SecondaryOffsetX", 0, "SecondaryOffsetY", 0, "ResponseMs", 2)

    if section = "Triggerbot" && name = "Precision"
        return GetPreset("Triggerbot", "Legit")
    if section = "Triggerbot" && name = "Balanced"
        return GetPreset("Triggerbot", "Semi Rage")
    if section = "Triggerbot" && (name = "Rapid" || name = "Legacy")
        return GetPreset("Triggerbot", "Rage")
    if section = "Camlock" && name = "Smooth"
        return GetPreset("Camlock", "Legit")
    if section = "Camlock" && (name = "Balanced" || name = "Responsive" || name = "Kairu Legacy")
        return GetPreset("Camlock", "Semi Rage")
    if section = "Aimlock" && name = "Precision"
        return GetPreset("Aimlock", "Legit")
    if section = "Aimlock" && name = "Balanced"
        return GetPreset("Aimlock", "Semi Rage")
    if section = "Aimlock" && name = "Aggressive"
        return GetPreset("Aimlock", "Rage")

    throw Error("Unknown preset: " section "/" name)
}

GlobalProfilePresets(name) {
    switch name {
        case "Legit":
            return Map("Movement", "Legit", "GunSpam", "Legit", "Emote", "Legit", "SOCD", "Legit", "Triggerbot", "Legit", "Camlock", "Legit", "Aimlock", "Legit", "WallHop", "Legit", "KeyRepeat", "Legit", "Recoil", "Legit")
        case "Semi Rage":
            return Map("Movement", "Semi Rage", "GunSpam", "Semi Rage", "Emote", "Semi Rage", "SOCD", "Semi Rage", "Triggerbot", "Semi Rage", "Camlock", "Semi Rage", "Aimlock", "Semi Rage", "WallHop", "Semi Rage", "KeyRepeat", "Semi Rage", "Recoil", "Semi Rage")
        case "Rage":
            return Map("Movement", "Rage", "GunSpam", "Rage", "Emote", "Rage", "SOCD", "Rage", "Triggerbot", "Rage", "Camlock", "Rage", "Aimlock", "Rage", "WallHop", "Rage", "KeyRepeat", "Rage", "Recoil", "Rage")

        case "Stable":
            return GlobalProfilePresets("Legit")
        case "Balanced":
            return GlobalProfilePresets("Semi Rage")
        case "Responsive":
            return GlobalProfilePresets("Rage")
        default:
            throw Error("Unknown global profile: " name)
    }
}
