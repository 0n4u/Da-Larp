IvoryBuild_macro() {
    page := "macro"
    IvoryGroup(page, 0, ["Activation"])
    IvoryGroup(page, 1, ["Sequence"])
    IvoryModuleHeader(page, "Movement")
    IvorySetting(page, 0, "Activation", "Activation Key", "Movement", "Hotkey", "key", "", "", "", "Movement")
    IvorySetting(page, 0, "Activation", "Step Delay", "Movement", "StepMs", "int", 1, 100, "", "Movement")
    IvorySetting(page, 0, "Activation", "Activation Mode", "Movement", "Mode", "choice", "", "", ["hold", "toggle"], "Movement")
    IvorySetting(page, 0, "Activation", "Delay Placement", "Movement", "StepMode", "choice", "", "", ["cycle", "actions"], "Movement")
    IvorySetting(page, 1, "Sequence", "Middle Clicks", "Movement", "MiddleTaps", "int", 0, 8, "", "Movement")
    IvorySetting(page, 1, "Sequence", "Wheel Up", "Movement", "WheelUp", "bool", "", "", "", "Movement")
    IvorySetting(page, 1, "Sequence", "Wheel Down", "Movement", "WheelDown", "bool", "", "", "", "Movement")
}

IvoryBuild_extras() {
    page := "extras"
    tabs := ["Wall Hop", "Repeat", "Recoil"]
    IvoryGroup(page, 0, tabs)
    IvoryGroup(page, 1, tabs)
    IvoryModuleHeader(page, "WallHop", "Wall Hop")
    IvoryModuleHeader(page, "KeyRepeat", "Repeat")
    IvoryModuleHeader(page, "Recoil", "Recoil")
    IvorySetting(page, 0, "Wall Hop", "Activation Key", "WallHop", "Hotkey", "key", "", "", "", "WallHop")
    IvorySetting(page, 0, "Wall Hop", "Flick Direction", "WallHop", "Direction", "choice", "", "", ["right", "left"], "WallHop")
    IvorySetting(page, 1, "Wall Hop", "Flick Distance", "WallHop", "DistancePx", "int", 1, 2000, "", "WallHop")
    IvorySetting(page, 1, "Wall Hop", "Return Delay", "WallHop", "ReturnMs", "int", 0, 250, "", "WallHop")
    IvorySetting(page, 1, "Wall Hop", "Cooldown", "WallHop", "CooldownMs", "int", 20, 1000, "", "WallHop")
    IvorySetting(page, 0, "Repeat", "Activation Key", "KeyRepeat", "Hotkey", "key", "", "", "", "KeyRepeat")
    IvorySetting(page, 0, "Repeat", "Activation Mode", "KeyRepeat", "Mode", "choice", "", "", ["hold", "toggle"], "KeyRepeat")
    IvorySetting(page, 0, "Repeat", "Repeated Key", "KeyRepeat", "OutputKey", "key", "", "", "", "KeyRepeat")
    IvorySetting(page, 1, "Repeat", "Repeat Delay", "KeyRepeat", "IntervalMs", "int", 10, 1000, "", "KeyRepeat")
    IvorySetting(page, 1, "Repeat", "Key Hold", "KeyRepeat", "HoldMs", "int", 0, 100, "", "KeyRepeat")
    IvorySetting(page, 0, "Recoil", "Fire Button", "Recoil", "FireKey", "key", "", "", "", "Recoil")
    IvorySetting(page, 0, "Recoil", "Aim Button", "Recoil", "AimKey", "key", "", "", "", "Recoil")
    IvorySetting(page, 0, "Recoil", "Require Aiming", "Recoil", "RequireAim", "bool", "", "", "", "Recoil")
    IvorySetting(page, 1, "Recoil", "Horizontal Pull", "Recoil", "PullX", "float", -50, 50, "", "Recoil")
    IvorySetting(page, 1, "Recoil", "Vertical Pull", "Recoil", "PullY", "float", -50, 50, "", "Recoil")
    IvorySetting(page, 1, "Recoil", "Pull Interval", "Recoil", "IntervalMs", "int", 2, 100, "", "Recoil")
    IvorySetting(page, 1, "Recoil", "Max Step", "Recoil", "MaxStep", "int", 1, 50, "", "Recoil")
}

IvoryBuild_visuals() {
    page := "visuals"
    IvoryGroup(page, 0, ["FOV Circle"])
    IvoryGroup(page, 1, ["Appearance"])
    IvoryModuleHeader(page, "FOV")
    IvorySetting(page, 0, "FOV Circle", "FOV Source", "FOV", "Source", "choice", "", "", ["auto", "camlock", "aimlock", "triggerbot"], "FOV")
    IvorySetting(page, 0, "FOV Circle", "FOV Position", "FOV", "Origin", "choice", "", "", ["cursor", "camera POV"], "FOV")
    IvorySetting(page, 0, "FOV Circle", "Guide Shape", "FOV", "Shape", "choice", "", "", ["circle", "ellipse", "rectangle", "triangle", "diamond", "pentagon", "hexagon", "heptagon", "octagon", "decagon", "star", "heart", "cross", "shield"], "FOV")
    IvorySetting(page, 1, "Appearance", "Circle Color", "FOV", "Color", "color", "", "", "", "FOV")
    IvorySetting(page, 1, "Appearance", "Opacity", "FOV", "Opacity", "int", 128, 255, "", "FOV")
    IvorySetting(page, 1, "Appearance", "Line Thickness", "FOV", "Thickness", "int", 1, 8, "", "FOV")
    IvorySetting(page, 1, "Appearance", "Outline Style", "FOV", "OutlineStyle", "choice", "", "", ["solid", "dashed", "dotted", "segmented", "corners"], "FOV")
    IvoryLabel(page, 25, 300, 213, 18, "Decorative shapes; scanner uses ellipse or box.")
}

IvoryBuild_turns() {
    page := "turns"
    IvoryGroup(page, 0, ["Turn"])
    IvoryGroup(page, 1, ["Calibration"])
    IvoryModuleHeader(page, "CameraTurn")
    IvorySetting(page, 0, "Turn", "Activation Key", "CameraTurn", "Hotkey", "key", "", "", "", "CameraTurn")
    IvorySetting(page, 0, "Turn", "Turn Angle", "CameraTurn", "Angle", "float", 1, 360, "", "CameraTurn")
    IvorySetting(page, 0, "Turn", "Direction", "CameraTurn", "Direction", "choice", "", "", ["right", "left"], "CameraTurn")
    IvorySetting(page, 0, "Turn", "Movement Curve", "CameraTurn", "Curve", "choice", "", "", ["eased", "linear"], "CameraTurn")
    IvorySetting(page, 0, "Turn", "Turn Duration", "CameraTurn", "DurationMs", "int", 20, 2000, "", "CameraTurn")
    IvorySetting(page, 0, "Turn", "Cooldown", "CameraTurn", "CooldownMs", "int", 20, 3000, "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "360 Degree Input Units", "CameraTurn", "UnitsPer360", "float", 1, 100000, "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "Reference Sensitivity", "CameraTurn", "ReferenceSensitivity", "float", 0.001, 10, "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "Current Sensitivity", "CameraTurn", "Sensitivity", "float", 0.001, 10, "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "Scale With DPI", "CameraTurn", "DpiScaling", "bool", "", "", "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "Reference DPI", "CameraTurn", "ReferenceDpi", "int", 100, 32000, "", "CameraTurn")
    IvorySetting(page, 1, "Calibration", "Current DPI", "CameraTurn", "Dpi", "int", 100, 32000, "", "CameraTurn")
}

IvoryBuild_weapons() {
    page := "weapons"
    IvoryGroup(page, 0, ["Detection", "Region"])
    IvoryGroup(page, 1, ["Templates", "Colors"])
    IvoryModuleHeader(page, "WeaponDetection", "Detection")
    IvorySetting(page, 0, "Detection", "Method (both = image OR color)", "WeaponDetection", "Method", "choice", "", "", ["image", "color", "both"], "WeaponDetection")
    IvorySetting(page, 0, "Detection", "Firing Rule", "WeaponDetection", "Action", "choice", "", "", ["block matched", "allow matched"], "WeaponDetection")
    IvorySetting(page, 0, "Detection", "Detection Interval", "WeaponDetection", "ScanMs", "int", 50, 1000, "", "WeaponDetection")
    IvorySetting(page, 0, "Detection", "Permission Confirmations", "WeaponDetection", "ConfirmScans", "int", 1, 8, "", "WeaponDetection")
    IvorySetting(page, 0, "Region", "Region Left (%)", "WeaponDetection", "RegionX", "float", 0, 99.9, "", "WeaponDetection")
    IvorySetting(page, 0, "Region", "Region Top (%)", "WeaponDetection", "RegionY", "float", 0, 99.9, "", "WeaponDetection")
    IvorySetting(page, 0, "Region", "Region Width (%)", "WeaponDetection", "RegionW", "float", 0.1, 100, "", "WeaponDetection")
    IvorySetting(page, 0, "Region", "Region Height (%)", "WeaponDetection", "RegionH", "float", 0.1, 100, "", "WeaponDetection")
    IvorySetting(page, 1, "Templates", "Template 1", "WeaponDetection", "Template1", "text", "", "", "", "WeaponDetection")
    IvorySetting(page, 1, "Templates", "Template 2", "WeaponDetection", "Template2", "text", "", "", "", "WeaponDetection")
    IvorySetting(page, 1, "Templates", "Scale Templates", "WeaponDetection", "ScaleTemplates", "bool", "", "", "", "WeaponDetection")
    IvorySetting(page, 1, "Templates", "Reference Width", "WeaponDetection", "ReferenceWidth", "int", 320, 10000, "", "WeaponDetection")
    IvorySetting(page, 1, "Templates", "Reference Height", "WeaponDetection", "ReferenceHeight", "int", 240, 10000, "", "WeaponDetection")
    IvorySetting(page, 1, "Colors", "Match Color 1", "WeaponDetection", "Color1", "color", "", "", "", "WeaponDetection")
    IvorySetting(page, 1, "Colors", "Match Color 2", "WeaponDetection", "Color2", "color", "", "", "", "WeaponDetection")
    IvorySetting(page, 1, "Colors", "Match Tolerance", "WeaponDetection", "Tolerance", "int", 0, 255, "", "WeaponDetection")
    IvoryAction(page, 1, "Templates", "Import Template 1", ImportWeaponTemplate.Bind(1))
    IvoryAction(page, 1, "Templates", "Import Template 2", ImportWeaponTemplate.Bind(2))
    IvoryAction(page, 0, "Detection", "Show Detection Status", ShowWeaponStatus)
}

IvoryBuild_gun() {
    page := "gun"
    IvoryGroup(page, 0, ["Activation"])
    IvoryGroup(page, 1, ["Input Rules"])
    IvoryModuleHeader(page, "GunSpam")
    IvorySetting(page, 0, "Activation", "Activation Key", "GunSpam", "Hotkey", "key", "", "", "", "GunSpam")
    IvorySetting(page, 0, "Activation", "Click Interval", "GunSpam", "IntervalMs", "int", 1, 100, "", "GunSpam")
    IvorySetting(page, 0, "Activation", "Click Hold", "GunSpam", "ClickHoldMs", "int", 0, 50, "", "GunSpam")
    IvorySetting(page, 1, "Input Rules", "Bypass With Ctrl", "GunSpam", "BypassCtrl", "bool", "", "", "", "GunSpam")
    IvorySetting(page, 1, "Input Rules", "Bypass With Alt", "GunSpam", "BypassAlt", "bool", "", "", "", "GunSpam")
}

IvoryBuild_emote() {
    page := "emote"
    IvoryGroup(page, 0, ["Keys"])
    IvoryGroup(page, 1, ["Timing"])
    IvoryModuleHeader(page, "Emote")
    IvorySetting(page, 0, "Keys", "Activation Key", "Emote", "Hotkey", "key", "", "", "", "Emote")
    IvorySetting(page, 0, "Keys", "Menu Key", "Emote", "MenuKey", "key", "", "", "", "Emote")
    IvorySetting(page, 0, "Keys", "Slot Key", "Emote", "SlotKey", "key", "", "", "", "Emote")
    IvorySetting(page, 0, "Keys", "Press Count", "Emote", "PressCount", "int", 1, 8, "", "Emote")
    IvorySetting(page, 1, "Timing", "Open Delay", "Emote", "OpenMs", "int", 0, 500, "", "Emote")
    IvorySetting(page, 1, "Timing", "Between Presses", "Emote", "BetweenMs", "int", 0, 500, "", "Emote")
    IvorySetting(page, 1, "Timing", "Final Setup Delay", "Emote", "FinalMs", "int", 0, 1000, "", "Emote")
}

IvoryBuild_socd() {
    page := "socd"
    IvoryGroup(page, 0, ["Horizontal"])
    IvoryGroup(page, 1, ["Vertical"])
    IvoryModuleHeader(page, "SOCD")
    IvorySetting(page, 0, "Horizontal", "Resolution Mode", "SOCD", "Mode", "choice", "", "", ["last", "neutral"], "SOCD")
    IvorySetting(page, 0, "Horizontal", "Left Key", "SOCD", "Left", "key", "", "", "", "SOCD")
    IvorySetting(page, 0, "Horizontal", "Right Key", "SOCD", "Right", "key", "", "", "", "SOCD")
    IvorySetting(page, 1, "Vertical", "Up Key", "SOCD", "Up", "key", "", "", "", "SOCD")
    IvorySetting(page, 1, "Vertical", "Down Key", "SOCD", "Down", "key", "", "", "", "SOCD")
}

IvoryBuild_trigger() {
    page := "trigger"
    IvoryGroup(page, 0, ["Main"])
    IvoryGroup(page, 1, ["Detection / Firing"])
    IvoryModuleHeader(page, "Triggerbot")
    IvorySetting(page, 0, "Main", "Activation Key", "Triggerbot", "Hotkey", "key", "", "", "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Fire Mode", "Triggerbot", "FireMode", "choice", "", "", ["edge", "repeat"], "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Confirm Time", "Triggerbot", "ConfirmMs", "int", 0, 250, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Cooldown", "Triggerbot", "CooldownMs", "int", 0, 1000, "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Ignore Physical LMB", "Triggerbot", "IgnoreHeldClick", "bool", "", "", "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Pause While Moving", "Triggerbot", "RequireStationary", "bool", "", "", "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Targeting Origin", "Triggerbot", "Origin", "choice", "", "", ["camera", "cursor"], "Triggerbot")
    IvorySetting(page, 0, "Main", "Activation Mode", "Triggerbot", "Mode", "choice", "", "", ["hold", "toggle", "always"], "Triggerbot")
    IvorySetting(page, 0, "Main", "FOV Radius X", "Triggerbot", "FovX", "int", 1, 300, "", "Triggerbot")
    IvorySetting(page, 0, "Main", "FOV Radius Y", "Triggerbot", "FovY", "int", 1, 300, "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Target Color", "Triggerbot", "TargetColor", "color", "", "", "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Secondary Color", "Triggerbot", "SecondaryColor", "color", "", "", "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Third Color", "Triggerbot", "TertiaryColor", "color", "", "", "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Color Tolerance", "Triggerbot", "Tolerance", "int", 0, 255, "", "Triggerbot")
    IvoryAction(page, 1, "Detection / Firing", "Sample Primary Color (3s)", SampleTargetColor.Bind("Triggerbot", "TargetColor"))
    IvoryAction(page, 1, "Detection / Firing", "Sample Secondary Color (3s)", SampleTargetColor.Bind("Triggerbot", "SecondaryColor"))
    IvoryAction(page, 1, "Detection / Firing", "Sample Third Color (3s)", SampleTargetColor.Bind("Triggerbot", "TertiaryColor"))
    IvorySetting(page, 0, "Main", "Second Tolerance (-1 = shared)", "Triggerbot", "SecondaryTolerance", "int", -1, 255, "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Third Tolerance (-1 = shared)", "Triggerbot", "TertiaryTolerance", "int", -1, 255, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Match Support (pixels)", "Triggerbot", "MinPixels", "int", 1, 9, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Confirmation Radius", "Triggerbot", "ConfirmRadius", "int", 1, 100, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Verify Before Firing", "Triggerbot", "VerifyBeforeFire", "bool", "", "", "", "Triggerbot")
    IvorySetting(page, 0, "Main", "Resolution Scaling", "Triggerbot", "ScaleMode", "choice", "", "", ["auto", "raw"], "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Scan Interval", "Triggerbot", "ScanMs", "int", 1, 100, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Confirm Scans", "Triggerbot", "ConfirmScans", "int", 1, 8, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Re-arm Delay", "Triggerbot", "RearmMs", "int", 0, 500, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Click Hold", "Triggerbot", "ClickHoldMs", "int", 0, 100, "", "Triggerbot")
    IvorySetting(page, 1, "Detection / Firing", "Post-fire Delay", "Triggerbot", "PostFireMs", "int", 0, 250, "", "Triggerbot")
}

IvoryBuildTrackingPage(page, section) {
    IvoryGroup(page, 0, ["Main", "Field"])
    IvoryGroup(page, 1, ["Tracking", "Prediction"])
    IvoryModuleHeader(page, section)
    IvorySetting(page, 0, "Main", "Activation Key", section, "Hotkey", "key", "", "", "", section)
    IvorySetting(page, 0, "Main", "Activation Mode", section, "Mode", "choice", "", "", ["hold", "toggle", "always"], section)
    IvorySetting(page, 0, "Main", "Target Color", section, "TargetColor", "color", "", "", "", section)
    IvorySetting(page, 0, "Main", "Secondary Color", section, "SecondaryColor", "color", "", "", "", section)
    IvorySetting(page, 0, "Main", "Third Color", section, "TertiaryColor", "color", "", "", "", section)
    IvorySetting(page, 0, "Main", "Color Tolerance", section, "Tolerance", "int", 0, 255, "", section)
    IvoryAction(page, 1, "Tracking", "Sample Primary Color (3s)", SampleTargetColor.Bind(section, "TargetColor"))
    IvoryAction(page, 1, "Tracking", "Sample Secondary Color (3s)", SampleTargetColor.Bind(section, "SecondaryColor"))
    IvoryAction(page, 1, "Tracking", "Sample Third Color (3s)", SampleTargetColor.Bind(section, "TertiaryColor"))
    IvorySetting(page, 0, "Main", "Second Tolerance (-1 = shared)", section, "SecondaryTolerance", "int", -1, 255, "", section)
    IvorySetting(page, 0, "Main", "Third Tolerance (-1 = shared)", section, "TertiaryTolerance", "int", -1, 255, "", section)
    IvorySetting(page, 0, "Main", "Match Support (pixels)", section, "MinPixels", "int", 1, 9, "", section)
    IvorySetting(page, 0, "Field", "FOV Mode", section, "FovMode", "choice", "", "", ["pixels", "degrees"], section)
    IvorySetting(page, 0, "Field", "Targeting Origin", section, "Origin", "choice", "", "", ["camera", "cursor"], section)
    IvorySetting(page, 0, "Field", "Camera FOV", section, "CameraFov", "float", 40, 120, "", section)
    IvorySetting(page, 0, "Field", "FOV Radius X", section, "FovX", "float", 1, 1000, "", section)
    IvorySetting(page, 0, "Field", "FOV Radius Y", section, "FovY", "float", 1, 1000, "", section)
    IvorySetting(page, 0, "Field", "Resolution Scaling", section, "ScaleMode", "choice", "", "", ["auto", "raw"], section)
    IvorySetting(page, 0, "Field", "Target Offset X", section, "OffsetX", "int", -500, 500, "", section)
    IvorySetting(page, 0, "Field", "Target Offset Y", section, "OffsetY", "int", -500, 500, "", section)
    IvorySetting(page, 0, "Field", "Secondary Offset X", section, "SecondaryOffsetX", "int", -500, 500, "", section)
    IvorySetting(page, 0, "Field", "Secondary Offset Y", section, "SecondaryOffsetY", "int", -500, 500, "", section)
    IvorySetting(page, 0, "Field", "Third Offset X", section, "TertiaryOffsetX", "int", -500, 500, "", section)
    IvorySetting(page, 0, "Field", "Third Offset Y", section, "TertiaryOffsetY", "int", -500, 500, "", section)
    IvorySetting(page, 1, "Tracking", "Calibrated Angular Motion", section, "AngularMotion", "bool", "", "", "", section)
    IvorySetting(page, 1, "Tracking", "Show Target Dot", section, "TargetDot", "bool", "", "", "", section)
    IvorySetting(page, 1, "Tracking", "Target Dot Color", section, "DotColor", "color", "", "", "", section)
    IvorySetting(page, 1, "Tracking", "Target Dot Size", section, "DotSize", "int", 2, 16, "", section)
    IvorySetting(page, 1, "Tracking", "Tracking Strength X", section, "StrengthX", "float", 0.01, 2.0, "", section)
    IvorySetting(page, 1, "Tracking", "Tracking Strength Y", section, "StrengthY", "float", 0.01, 2.0, "", section)
    IvorySetting(page, 1, "Tracking", "Smooth Style", section, "ResponseCurve", "choice", "", "", ["smooth", "linear", "aggressive"], section)
    IvorySetting(page, 1, "Tracking", "Response Time", section, "ResponseMs", "float", 1, 50, "", section)
    IvorySetting(page, 1, "Prediction", "Use Prediction", section, "PredictionEnabled", "bool", "", "", "", section)
    IvorySetting(page, 1, "Prediction", "Prediction X", section, "LeadMsX", "float", 0, 100, "", section)
    IvorySetting(page, 1, "Prediction", "Prediction Y", section, "LeadMsY", "float", 0, 100, "", section)
    IvorySetting(page, 1, "Prediction", "Velocity Resolver", section, "VelocityBlend", "float", 0.05, 1.0, "", section)
    IvorySetting(page, 1, "Prediction", "Max Prediction", section, "MaxLeadPx", "float", 0, 250, "", section)
    IvoryAction(page, 1, "Prediction", "Edit Prediction Curves", OpenPredictionCurveEditor.Bind(section))
    IvorySetting(page, 1, "Tracking", "Lock Radius", section, "LockRadius", "int", 4, 300, "", section)
    IvorySetting(page, 1, "Tracking", "Lock Hold", section, "LockHoldMs", "int", 0, 500, "", section)
    IvorySetting(page, 1, "Tracking", "Target Switch Delay", section, "SwitchDelayMs", "int", 0, 400, "", section)
    IvorySetting(page, 1, "Tracking", "Deadzone", section, "Deadzone", "float", 0, 50, "", section)
    IvorySetting(page, 1, "Tracking", "Max Step", section, "MaxStep", "int", 1, 500, "", section)
    IvorySetting(page, 1, "Tracking", "Scan Interval", section, "ScanMs", "int", 1, 100, "", section)
}

IvoryBuild_system() {
    page := "system"
    IvoryGroup(page, 0, ["Application"])
    IvoryGroup(page, 1, ["Maintenance"])
    IvorySetting(page, 0, "Application", "Master Enable", "General", "Master", "bool")
    IvorySetting(page, 0, "Application", "Show Top Bar", "App", "TopBarEnabled", "bool")
    IvorySetting(page, 0, "Application", "Reserve Top Bar Space", "App", "TopBarReserveSpace", "bool")
    IvorySetting(page, 0, "Application", "CPU-Friendly Mode", "App", "CPUFriendly", "bool")
    IvorySetting(page, 0, "Application", "Exclude From Capture", "App", "CaptureExcluded", "bool")
    IvorySetting(page, 0, "Application", "Typing Mode", "App", "TypingMode", "bool")
    IvorySetting(page, 0, "Application", "Typing Mode Key", "App", "TypingKey", "key")
    IvorySetting(page, 0, "Application", "Start With Windows", "App", "StartWithWindows", "bool")
    IvorySetting(page, 0, "Application", "Auto Recover Workers", "App", "AutoRecover", "bool")
    IvorySetting(page, 0, "Application", "Remember Window Position", "App", "RememberPosition", "bool")
    IvorySetting(page, 0, "Application", "Close Behavior", "App", "CloseBehavior", "choice", "", "", ["tray", "exit"])
    IvorySetting(page, 0, "Application", "Advanced Settings", "App", "AdvancedUI", "bool")
    IvorySetting(page, 0, "Application", "Background Rejection", "Detection", "BackgroundReject", "bool")
    IvorySetting(page, 0, "Application", "Reject Solid Regions (%)", "Detection", "BackgroundFillLimit", "int", 40, 95)
    IvorySetting(page, 0, "Application", "Background Filter Mode", "Detection", "BackgroundMode", "choice", "", "", ["balanced", "strict"])
    IvorySetting(page, 0, "Application", "Adaptive Scan Region", "Detection", "AdaptiveScan", "bool")
    IvorySetting(page, 0, "Application", "Session Mode", "App", "SessionMode", "bool")
    IvorySetting(page, 0, "Application", "Developer Tools", "App", "DeveloperMode", "bool")
    global CONFIG_PATH
    IvoryAction(page, 1, "Maintenance", "Restart Input Engine", ResetInputEngine)
    IvoryAction(page, 1, "Maintenance", "Edit Profile", IvoryEditProfile)
    IvoryAction(page, 1, "Maintenance", "Open Suite Folder", (*) => Run('explorer.exe "' A_ScriptDir '"'))
    IvoryAction(page, 1, "Maintenance", "Open Config File", (*) => Run('notepad.exe "' CONFIG_PATH '"'))
    IvoryAction(page, 1, "Maintenance", "Exit Suite", (*) => ExitApp())
}

BuildGui() {
    global MainGui, PAGE_CONTROLS, ACTIVE_PAGE, UI, APP_VERSION, APP_NAME
    for page in ["macro", "gun", "emote", "socd", "extras", "turns", "visuals", "weapons", "trigger", "camlock", "aimlock", "config", "system", "debug"]
        PAGE_CONTROLS[page] := []
    MainGui := Gui("-Caption -Border +E0x02000000", APP_NAME)
    MainGui.BackColor := "1E1E1E"
    MainGui.MarginX := 0
    MainGui.MarginY := 0
    MainGui.SetFont("s9 cFFFFFF", "Tahoma")
    MainGui.OnEvent("Close", HandleClose)
    MainGui.OnEvent("Escape", IvoryHide)
    IvoryUI.Init(MainGui)
    OnMessage(0x100, IvoryConfigKeyDown, 2)
    IvoryUI.Add(MainGui, "window", 0, 0, 504, 604)
    IvoryUI.Add(MainGui, "title", 5, 4, 489, 18, APP_NAME, "", BeginDrag)
    IvoryUI.Add(MainGui, "panel", 6, 24, 492, 574)
    IvoryCategory("targeting", "Targeting", 12, 160)
    IvoryCategory("macros", "Macros", 172, 160)
    IvoryCategory("settings", "Settings", 332, 160)
    for spec in [["macro","Macro",18,76],["gun","Gun",96,76],["emote","Emote",174,76],["socd","SOCD",252,76],["extras","Extras",330,76],["turns","Turns",408,78],
        ["config","Config",18,91],["visuals","Visuals",111,91],["weapons","Weapons",204,91],["system","System",297,91],["debug","Debug",390,96]]
        AddNav(spec*)
    IvoryBuild_macro()
    IvoryBuild_gun()
    IvoryBuild_emote()
    IvoryBuild_socd()
    IvoryBuild_extras()
    IvoryBuild_visuals()
    IvoryBuild_turns()
    IvoryBuild_weapons()
    IvoryBuild_trigger()
    IvoryBuildTrackingPage("camlock", "Camlock")
    IvoryBuildTrackingPage("aimlock", "Aimlock")
    IvoryBuildConfigPage()
    IvoryBuild_system()
    IvoryBuildDebugPage()
    IvoryValidatePageRows()
    IvoryBuildToolbar()
    ACTIVE_PAGE := Cfg("App", "LastPage", "camlock")
    if ACTIVE_PAGE = "move"
        ACTIVE_PAGE := "macro"
    if !PAGE_CONTROLS.Has(ACTIVE_PAGE)
        ACTIVE_PAGE := "camlock"
    if ACTIVE_PAGE = "debug" && !CfgBool("App", "DeveloperMode", false)
        ACTIVE_PAGE := "system"
    ShowPage(ACTIVE_PAGE)
    RefreshAllValues()
}

IvoryValidatePageRows() {
    for groupKey, group in IvoryUI.Groups {
        if groupKey != group.id
            continue
        if !group.scroll.Has(group.selected)
            throw Error("UI group has no selected tab: " groupKey " / " group.selected)
        for tab in group.tabs {
            if !group.scroll.Has(tab) || !IvoryUI.Rows.Has(group.id ":" tab)
                throw Error("UI group has no registered row: " groupKey " / " tab)
        }
    }
    for _, item in IvoryUI.Items {
        if item.group = "" || !IvoryUI.Groups.Has(item.group) || item.tab = ""
            continue
        group := IvoryUI.Groups[item.group]
        if !group.scroll.Has(item.tab) || !IvoryUI.Rows.Has(group.id ":" item.tab)
            throw Error("UI control has an invalid tab: " item.page " / " item.group " / " item.tab)
    }
}

IvoryFamily(page) {
    if page = "camlock" || page = "aimlock" || page = "trigger"
        return "targeting"
    if page = "macro" || page = "gun" || page = "emote" || page = "socd" || page = "extras" || page = "turns"
        return "macros"
    return "settings"
}

IvoryCategory(family, label, x, w) {
    global MainGui
    first := family = "targeting" ? "camlock" : family = "macros" ? "macro" : "config"
    ctrl := IvoryUI.Add(MainGui, "tab", x, 28, w, 24, label, "", ShowPage.Bind(first))
    IvoryUI.Items[ctrl.Hwnd].group := "category:" family
}

AddNav(page, label, x, w) {
    global MainGui, NAV_CONTROLS
    ctrl := IvoryUI.Add(MainGui, "tab", x, 58, w, 22, label, "", ShowPage.Bind(page), true)
    NAV_CONTROLS[page] := ctrl
}

IvoryRefreshNavigation() {
    global NAV_CONTROLS, ACTIVE_PAGE
    family := IvoryFamily(ACTIVE_PAGE)
    for page, ctrl in NAV_CONTROLS {
        ctrl.Visible := IvoryFamily(page) = family && (page != "debug" || CfgBool("App", "DeveloperMode", false))
        IvoryUI.Items[ctrl.Hwnd].selected := page = ACTIVE_PAGE
        IvoryUI.Redraw(ctrl)
    }
    for _, item in IvoryUI.Items {
        if InStr(item.group, "category:") = 1 {
            item.selected := item.group = "category:" family
            IvoryUI.Redraw(item.ctrl)
        }
    }
    IvoryRefreshToolbar()
}

ShowPage(page, *) {
    global PAGE_CONTROLS, ACTIVE_PAGE, CONFIG_PATH, ConfigMenu
    if page = "debug" && !CfgBool("App", "DeveloperMode", false)
        return
    if !PAGE_CONTROLS.Has(page)
        return
    IvoryUI.ClosePopup()
    ConfigMenu := 0
    ACTIVE_PAGE := page
    if page = "config"
        IvoryConfigRefreshDropdown()
    for p, controls in PAGE_CONTROLS {
        visible := IvoryPageVisible(p)
        for ctrl in controls
            ctrl.Visible := visible
        if visible
            IvoryApplyTabs(p)
    }
    IvoryRefreshNavigation()
    IniWrite(page, CONFIG_PATH, "App", "LastPage")
    RefreshAllValues()
}

ApplyAdvancedVisibility(page := "") {
    global PAGE_CONTROLS
    if page != ""
        IvoryApplyTabs(page)
    else {
        for name, _ in PAGE_CONTROLS
            IvoryApplyTabs(name)
    }
}

UpdateDeveloperVisibility() {
    global ACTIVE_PAGE
    if ACTIVE_PAGE = "debug" && !CfgBool("App", "DeveloperMode", false)
        ShowPage("system")
    else
        IvoryRefreshNavigation()
}

IvoryPageAdd(page, kind, x, y, w, h, text := "", label := "", callback := 0) {
    global MainGui, PAGE_CONTROLS
    ctrl := IvoryUI.Add(MainGui, kind, x, y, w, h, text, label, callback, true)
    IvoryUI.Items[ctrl.Hwnd].page := page
    PAGE_CONTROLS[page].Push(ctrl)
    return ctrl
}

IvoryLabel(page, x, y, w, h, text) {
    return IvoryPageAdd(page, "label", x, y, w, h, text)
}

IvoryModuleHeader(page, module, tab := "") {
    global MODULE_PILLS, PRESET_LABELS
    groupKey := page ":0"
    group := IvoryUI.Groups[groupKey]
    if tab = ""
        tab := group.tabs[1]
    ctrl := IvoryPageAdd(page, "module", group.x+7, group.bodyY, 133, 18, "disabled", "", ToggleModule.Bind(module))
    item := IvoryUI.Items[ctrl.Hwnd]
    item.module := module
    item.group := groupKey
    item.tab := tab
    item.row := 0
    MODULE_PILLS[module] := ctrl
    IvoryUI.Rows[group.id ":" tab] := 22
}

IvoryGroup(page, column, tabs) {
    groupKey := page ":" column
    targeting := IvoryFamily(page) = "targeting"
    if targeting && column = 1 {
        IvoryUI.Groups[groupKey] := IvoryUI.Groups[page ":0"]
        return
    }
    x := column = 0 ? 18 : 254
    y := targeting ? 58 : 86
    height := targeting ? 528 : 500
    if page = "config" {
        y := 177
        height := 409
    }
    if page = "aimlock" {
        x := 254
        height := 310
        tabs := ["Main", "Field", "Safety"]
    } else if page = "trigger" {
        x := 254
        y := 372
        height := 214
        tabs := ["Triggerbot"]
    }
    title := page = "camlock" ? "Camlock" : page = "aimlock" ? "Aimlock" : ""
    titleHeight := title != "" ? 24 : 0
    group := {id: groupKey, selected: tabs[1], tabs: tabs, x: x, y: y,
        height: height, bodyY: y+29+titleHeight, bodyH: height-36-titleHeight, scroll: Map(), controls: []}
    IvoryUI.Groups[groupKey] := group
    frame := IvoryPageAdd(page, "panel", x, y, 232, height)
    IvoryUI.Items[frame.Hwnd].group := groupKey
    if title != "" {
        heading := IvoryPageAdd(page, "group-title", x+2, y+2, 228, titleHeight, title)
        IvoryUI.Items[heading.Hwnd].group := groupKey
    }
    tabWidth := Floor(228/tabs.Length)
    for index, name in tabs {
        ctrl := IvoryPageAdd(page, tabs.Length = 1 ? "group-title" : "tab", x+2+(index-1)*tabWidth, y+2+titleHeight, tabWidth, 24, name, "", IvorySelectTab.Bind(groupKey, name))
        item := IvoryUI.Items[ctrl.Hwnd]
        item.group := groupKey
        item.tab := name
        item.selected := index = 1
        IvoryUI.Rows[groupKey ":" name] := 0
        group.scroll[name] := 0
    }
    scroll := IvoryPageAdd(page, "scrollbar", x+224, group.bodyY, 4, group.bodyH, "", "", IvoryScrollClick)
    IvoryUI.Items[scroll.Hwnd].group := groupKey
    group.scrollbar := scroll
}

IvorySelectTab(groupKey, name, *) {
    global ACTIVE_PAGE
    IvoryUI.Groups[groupKey].selected := name
    if StrSplit(groupKey, ":")[1] = "extras" {
        IvoryUI.Groups["extras:0"].selected := name
        IvoryUI.Groups["extras:1"].selected := name
    }
    IvoryApplyTabs(StrSplit(groupKey, ":")[1])
}

IvoryApplyTabs(page) {
    global PAGE_CONTROLS
    advanced := CfgBool("App","AdvancedUI",false)
    for ctrl in PAGE_CONTROLS[page] {
        if !IvoryUI.Items.Has(ctrl.Hwnd)
            continue
        item := IvoryUI.Items[ctrl.Hwnd]
        if item.group = "" || !IvoryUI.Groups.Has(item.group)
            continue
        group := IvoryUI.Groups[item.group]
        selected := group.selected = item.tab
        if item.kind = "tab" || item.kind = "group-title" {
            item.selected := item.tab = "" || selected
            IvoryUI.Redraw(ctrl)
        } else if item.row >= 0 {
            if !advanced && IvoryItemAdvanced(item) {
                ctrl.Visible := false
                continue
            }
            maxScroll := Max(0,IvoryContentHeight(group)-group.bodyH)
            group.scroll[group.selected] := Min(maxScroll,group.scroll[group.selected])
            y := group.bodyY+item.row-IvoryHiddenRowHeight(group,item.tab,item.row)-group.scroll[group.selected]
            ctrl.Move(, Round(y*IvoryUI.Scale))
            ctrl.Visible := IvoryPageVisible(page) && selected && y >= group.bodyY && y+item.h <= group.bodyY+group.bodyH
        } else if item.kind = "scrollbar" {
            ctrl.Visible := IvoryPageVisible(page) && IvoryContentHeight(group) > group.bodyH
            IvoryUI.Redraw(ctrl)
        }
    }
}

IvoryItemAdvanced(item) {
    return (item.HasOwnProp("advanced") && item.advanced)
        || (item.section != "" && SettingsSchema.IsAdvanced(item.section,item.key))
}

IvoryHiddenRowHeight(group,tab,beforeRow := 1000000) {
    if CfgBool("App","AdvancedUI",false)
        return 0
    hidden := 0
    for ctrl in group.controls {
        item := IvoryUI.Items[ctrl.Hwnd]
        if item.tab = tab && item.row < beforeRow && !item.inline && IvoryItemAdvanced(item)
            hidden += item.h+(item.kind = "button" ? 7 : 3)
    }
    return hidden
}

IvorySetting(page, column, tab, label, section, key, kind := "text", minV := "", maxV := "", choices := "", module := "") {
    global VALUE_CONTROLS
    groupKey := page ":" column
    group := IvoryUI.Groups[groupKey]
    tab := IvoryMappedTab(page, tab, key)
    rowKey := group.id ":" tab
    if !IvoryUI.Rows.Has(rowKey)
        throw Error("UI setting has no registered layout row: " rowKey " (" section "." key ")")
    x := group.x+7
    row := IvoryUI.Rows[rowKey]
    h := kind = "choice" ? 36 : (kind = "int" || kind = "float") ? 31 : 18
    width := 210
    inlineKey := key = "Hotkey" && module != ""
    if inlineKey {
        x := group.x+150
        row := 0
        width := 67
    }
    ctrl := IvoryPageAdd(page, kind, x, group.bodyY+row, width, h, "", label, IvoryEdit)
    item := IvoryUI.Items[ctrl.Hwnd]
    item.section := section
    item.key := key
    item.min := minV
    item.max := maxV
    item.choices := choices
    item.module := module
    item.group := groupKey
    item.tab := tab
    item.row := row
    item.inline := inlineKey
    if !inlineKey
        IvoryUI.Rows[rowKey] := row+h+3
    group.controls.Push(ctrl)
    VALUE_CONTROLS[section "." key] := ctrl
    return ctrl
}

IvoryAction(page, column, tab, label, callback) {
    groupKey := page ":" column
    group := IvoryUI.Groups[groupKey]
    tab := IvoryMappedTab(page, tab, "")
    rowKey := group.id ":" tab
    if !IvoryUI.Rows.Has(rowKey)
        throw Error("UI action has no registered layout row: " rowKey " (" label ")")
    y := IvoryUI.Rows[rowKey]
    ctrl := IvoryPageAdd(page, "button", group.x+7, group.bodyY+y, 210, 23, label, "", callback)
    item := IvoryUI.Items[ctrl.Hwnd]
    item.group := groupKey
    item.tab := tab
    item.row := y
    item.advanced := InStr(label,"Prediction Curves") > 0
    group.controls.Push(ctrl)
    IvoryUI.Rows[rowKey] := y+30
    return ctrl
}

IvoryRevealSetting(mapKey) {
    global VALUE_CONTROLS, ACTIVE_PAGE
    if !VALUE_CONTROLS.Has(mapKey)
        return
    ctrl := VALUE_CONTROLS[mapKey]
    item := IvoryUI.Items[ctrl.Hwnd]
    if IvoryItemAdvanced(item) && !CfgBool("App","AdvancedUI",false)
        SetCfg("App","AdvancedUI",1,false)
    if IvoryUI.Groups.Has(item.group)
        IvoryUI.Groups[item.group].selected := item.tab
    if item.page = "extras" {
        IvoryUI.Groups["extras:0"].selected := item.tab
        IvoryUI.Groups["extras:1"].selected := item.tab
    }
    if IvoryUI.Groups.Has(item.group) {
        group := IvoryUI.Groups[item.group]
        if item.row < group.scroll[item.tab] || item.row+item.h > group.scroll[item.tab]+group.bodyH
            group.scroll[item.tab] := Max(0, Min(item.row, IvoryContentHeight(group)-group.bodyH))
    }
    IvoryApplyTabs(item.page)
    ctrl.Focus()
}

IvoryThemeMenu(ctrl, *) {
    IvoryUI.ShowChoices(ctrl, ["Ivory", "Pink", "Rose", "Orange", "Gold", "Green", "Mint", "Teal", "Cyan", "Blue", "Lavender", "Purple"], IvorySetTheme)
}

IvorySetTheme(name) {
    global CONFIG_PATH
    colors := Map("Ivory",0xFFFFFF,"Pink",0xFF9DB4,"Rose",0xF38BA8,"Orange",0xFF9E64,"Gold",0xF9E2AF,
        "Green",0x89D9A0,"Mint",0x8FD7AE,"Teal",0x50C9BA,"Cyan",0x79F8FB,"Blue",0x3264FF,"Lavender",0xCBA6F7,"Purple",0xBE95FF)
    IvoryUI.Theme := name
    IvoryUI.Accent := colors.Has(name) ? colors[name] : 0xFFFFFF
    IniWrite(name, CONFIG_PATH, "App", "InterfaceTheme")
    for _, item in IvoryUI.Items
        IvoryUI.Redraw(item.ctrl)
}

IvoryBuildConfigPage() {
    global ConfigDropdown, ConfigDescription, ConfigCount
    page := "config"
    IvoryPageAdd(page, "label", 24, 89, 210, 18, "CONFIG FOLDER")
    ConfigCount := IvoryPageAdd(page, "label", 307, 89, 172, 18, "Scanning presets...")
    IvoryUI.Items[ConfigCount.Hwnd].color := 0xA6A6AA
    ConfigDropdown := IvoryPageAdd(page, "config-picker", 24, 111, 456, 28,
        "Select a configuration...", "", IvoryConfigOpenDropdown)
    IvoryGroup(page, 0, ["Profiles"])
    IvoryGroup(page, 1, ["Recovery"])
    IvoryAction(page, 0, "Profiles", "Load Selected Config", IvoryConfigLoadSelected)
    IvoryAction(page, 0, "Profiles", "Set Selected as Startup", IvoryConfigUseSelectedAtStartup)
    IvorySetting(page, 0, "Profiles", "Auto Load Config on Startup", "App", "AutoLoadConfig", "bool")
    IvoryAction(page, 1, "Recovery", "Compare Two Configs", OpenConfigDifferenceViewer)
    IvoryAction(page, 0, "Profiles", "Save Current Config", IvoryConfigSaveCurrent)
    IvoryAction(page, 0, "Profiles", "Refresh Config List", (*) => IvoryConfigRefreshDropdown())
    IvoryAction(page, 0, "Profiles", "Import Native INI", IvoryConfigImport)
    IvoryAction(page, 0, "Profiles", "Open Config Folder", IvoryConfigOpenFolder)
    IvoryAction(page, 0, "Profiles", "Export Current Config", ExportProfile)
    IvoryAction(page, 1, "Recovery", "Backup Config Now", (*) => BackupAndStatus())
    IvoryAction(page, 1, "Recovery", "Open Backups Folder", (*) => Run('explorer.exe "' BACKUP_DIR '"'))
    IvoryAction(page, 1, "Recovery", "Restore All-Disabled Default", RestoreDefaults)
    IvoryAction(page, 1, "Recovery", "Open Profiles Folder", (*) => Run('explorer.exe "' PROFILE_DIR '"'))
    IvoryPageAdd(page, "label", 30, 417, 206, 20, "SELECTED CONFIG")
    ConfigDescription := IvoryPageAdd(page, "label", 30, 444, 206, 23,
        "Choose a configuration")
    helper := IvoryPageAdd(page, "label", 30, 474, 206, 20, "Click Load to apply.")
    IvoryUI.Items[helper.Hwnd].color := 0xA6A6AA
    IvoryUI.Items[ConfigDescription.Hwnd].color := 0xA6A6AA
    global ConfigStartupLabel
    ConfigStartupLabel := IvoryPageAdd(page, "label", 266, 374, 206, 23,
        "Startup: disabled")
    helper := IvoryPageAdd(page, "label", 266, 407, 206, 23,
        "Settings replaced on load")
    IvoryUI.Items[helper.Hwnd].color := 0xA6A6AA
    IvoryUI.Items[ConfigStartupLabel.Hwnd].color := 0xA6A6AA
    IvoryConfigRefreshDropdown()
}

IvoryBuildDebugPage() {
    global UI, WORKERS, LOG_PATH
    page := "debug"
    IvoryGroup(page, 0, ["Workers"])
    IvoryGroup(page, 1, ["Tools"])
    y := 119
    for module, _ in WORKERS {
        UI["Debug_" module] := IvoryLabel(page, 25, y, 218, 22, "")
        y += 27
    }
    UI["DebugRoblox"] := IvoryLabel(page, 25, y+10, 218, 22, "")
    UI["DebugConfig"] := IvoryLabel(page, 25, y+39, 218, 22, "")
    IvoryAction(page, 1, "Tools", "Restart All Enabled Workers", ResetInputEngine)
    IvoryAction(page, 1, "Tools", "Validate Installation", ValidateInstallation)
    IvoryAction(page, 1, "Tools", "Effective Settings / Diagnostics", OpenEffectiveDiagnostics)
    IvoryAction(page, 1, "Tools", "Create Support Bundle", CreateSupportBundle)
    IvoryAction(page, 1, "Tools", "Open Log File", (*) => Run('notepad.exe "' LOG_PATH '"'))
}
