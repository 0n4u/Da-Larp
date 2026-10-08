class SettingsSchema {
    static Entries := this.Build()
    static Build() {
        entries := Map()
        defaults := "
(
Meta.SchemaVersion=17
Meta.AppVersion=14.0-alpha.1
Meta.Game=Da Hood
General.Master=1
General.Profile=Default
Modules.Movement=0
Modules.GunSpam=0
Modules.Emote=0
Modules.SOCD=0
Modules.Triggerbot=0
Modules.Camlock=0
Modules.Aimlock=0
Modules.WallHop=0
Modules.KeyRepeat=0
Modules.Recoil=0
Modules.FOV=0
Modules.CameraTurn=0
Modules.WeaponDetection=0
Movement.Mode=hold
Movement.StepMode=cycle
Movement.Preset=Legit
Movement.Hotkey=x
Movement.StepMs=12
Movement.MiddleTaps=2
Movement.WheelUp=1
Movement.WheelDown=1
GunSpam.Preset=Legit
GunSpam.Hotkey=LButton
GunSpam.IntervalMs=4
GunSpam.ClickHoldMs=0
GunSpam.BypassCtrl=1
GunSpam.BypassAlt=1
Emote.Preset=Legit
Emote.Hotkey=MButton
Emote.MenuKey=.
Emote.SlotKey=1
Emote.PressCount=4
Emote.OpenMs=38
Emote.BetweenMs=72
Emote.FinalMs=165
SOCD.Preset=Legit
SOCD.Mode=last
SOCD.Left=a
SOCD.Right=d
SOCD.Up=w
SOCD.Down=s
Triggerbot.Origin=camera
Triggerbot.RequireStationary=0
Triggerbot.Preset=Legit
Triggerbot.Hotkey=RButton
Triggerbot.Mode=hold
Triggerbot.ScaleMode=auto
Triggerbot.ReferenceWidth=1920
Triggerbot.ReferenceHeight=1080
Triggerbot.AspectPreset=auto
Triggerbot.FovX=2
Triggerbot.FovY=2
Triggerbot.TargetColor=0x000000
Triggerbot.SecondaryColor=
Triggerbot.Tolerance=18
Triggerbot.ScanMs=4
Triggerbot.FireMode=edge
Triggerbot.ConfirmScans=3
Triggerbot.ConfirmMs=14
Triggerbot.RearmMs=30
Triggerbot.PostFireMs=1
Triggerbot.ClickHoldMs=9
Triggerbot.CooldownMs=50
Triggerbot.IgnoreHeldClick=1
Triggerbot.TertiaryColor=
Triggerbot.SecondaryTolerance=-1
Triggerbot.TertiaryTolerance=-1
Triggerbot.MinPixels=1
Triggerbot.ConfirmRadius=8
Triggerbot.VerifyBeforeFire=1
Camlock.Origin=camera
Camlock.Preset=Legit
Camlock.Hotkey=RButton
Camlock.Mode=hold
Camlock.ScaleMode=auto
Camlock.ReferenceWidth=1920
Camlock.ReferenceHeight=1080
Camlock.AspectPreset=auto
Camlock.FovMode=pixels
Camlock.CameraFov=80
Camlock.FovX=85
Camlock.FovY=65
Camlock.TargetColor=0x000000
Camlock.SecondaryColor=
Camlock.Tolerance=8
Camlock.ScanMs=5
Camlock.ResponseMs=5
Camlock.StrengthX=0.12
Camlock.StrengthY=0.11
Camlock.ResponseCurve=smooth
Camlock.PredictionEnabled=0
Camlock.LeadMsX=6
Camlock.LeadMsY=4
Camlock.VelocityBlend=0.22
Camlock.MaxLeadPx=8
Camlock.MaxStep=24
Camlock.Deadzone=1.5
Camlock.LockRadius=34
Camlock.LockHoldMs=85
Camlock.OffsetX=0
Camlock.OffsetY=5
Camlock.SecondaryOffsetX=0
Camlock.SecondaryOffsetY=0
Camlock.TertiaryColor=
Camlock.SecondaryTolerance=-1
Camlock.TertiaryTolerance=-1
Camlock.MinPixels=1
Camlock.AngularMotion=0
Camlock.TargetDot=0
Camlock.DotColor=0xFAB387
Camlock.DotSize=5
Camlock.TertiaryOffsetX=0
Camlock.TertiaryOffsetY=0
Camlock.SwitchDelayMs=90
Aimlock.Origin=camera
Aimlock.Preset=Legit
Aimlock.Hotkey=RButton
Aimlock.Mode=hold
Aimlock.ScaleMode=auto
Aimlock.ReferenceWidth=1920
Aimlock.ReferenceHeight=1080
Aimlock.AspectPreset=auto
Aimlock.FovMode=pixels
Aimlock.CameraFov=85
Aimlock.FovX=50
Aimlock.FovY=40
Aimlock.TargetColor=0x000000
Aimlock.SecondaryColor=
Aimlock.Tolerance=7
Aimlock.ScanMs=4
Aimlock.ResponseMs=4
Aimlock.StrengthX=0.28
Aimlock.StrengthY=0.26
Aimlock.ResponseCurve=smooth
Aimlock.PredictionEnabled=0
Aimlock.LeadMsX=5
Aimlock.LeadMsY=4
Aimlock.VelocityBlend=0.20
Aimlock.MaxLeadPx=8
Aimlock.MaxStep=46
Aimlock.Deadzone=0.75
Aimlock.LockRadius=24
Aimlock.LockHoldMs=65
Aimlock.OffsetX=0
Aimlock.OffsetY=5
Aimlock.SecondaryOffsetX=0
Aimlock.SecondaryOffsetY=0
Aimlock.TertiaryColor=
Aimlock.SecondaryTolerance=-1
Aimlock.TertiaryTolerance=-1
Aimlock.MinPixels=1
Aimlock.AngularMotion=0
Aimlock.TargetDot=0
Aimlock.DotColor=0xFAB387
Aimlock.DotSize=5
Aimlock.TertiaryOffsetX=0
Aimlock.TertiaryOffsetY=0
Aimlock.SwitchDelayMs=90
WallHop.Preset=Original Flick
WallHop.Hotkey=F6
WallHop.Direction=right
WallHop.DistancePx=35
WallHop.ReturnMs=4
WallHop.CooldownMs=120
KeyRepeat.Preset=Stomp Repeat
KeyRepeat.Hotkey=F7
KeyRepeat.Mode=hold
KeyRepeat.OutputKey=e
KeyRepeat.IntervalMs=120
KeyRepeat.HoldMs=8
Recoil.Preset=Gentle
Recoil.FireKey=LButton
Recoil.AimKey=RButton
Recoil.RequireAim=1
Recoil.PullX=0
Recoil.PullY=1
Recoil.IntervalMs=10
Recoil.MaxStep=12
FOV.OutlineStyle=solid
FOV.Origin=camera
FOV.Preset=Circle
FOV.Source=auto
FOV.Shape=circle
FOV.Color=0xFFFFFF
FOV.Opacity=255
FOV.Thickness=1
App.CPUFriendly=0
App.CaptureExcluded=0
App.TypingMode=0
App.TypingKey=RShift
App.TopBarEnabled=0
App.TopBarReserveSpace=0
App.CloseBehavior=tray
App.AutoRecover=0
App.DeveloperMode=0
App.StartWithWindows=0
App.RememberPosition=0
App.LastPage=config
App.HistoryLimit=20
App.AdvancedUI=0
App.DeferRestarts=0
App.SessionMode=0
App.AutoLastKnownGood=0
App.UiScale=100
App.Density=compact
App.AccentTheme=ivory
App.InstallMode=portable
App.InterfaceTheme=Rose
App.RecentColors=
App.AutoLoadConfig=0
App.StartupConfig=Default.ini
Window.X=-1
Window.Y=-1
CameraTurn.Preset=Half Turn
CameraTurn.Hotkey=F8
CameraTurn.Angle=180
CameraTurn.Direction=right
CameraTurn.Curve=eased
CameraTurn.DurationMs=180
CameraTurn.CooldownMs=250
CameraTurn.UnitsPer360=2000
CameraTurn.ReferenceSensitivity=0.2
CameraTurn.Sensitivity=0.2
CameraTurn.DpiScaling=0
CameraTurn.ReferenceDpi=1600
CameraTurn.Dpi=1600
WeaponDetection.Preset=Custom
WeaponDetection.Method=image
WeaponDetection.Action=block matched
WeaponDetection.Template1=assets/weapons/knife.png
WeaponDetection.Template2=assets/weapons/uzi.png
WeaponDetection.Color1=0x5A8EE9
WeaponDetection.Color2=
WeaponDetection.Tolerance=20
WeaponDetection.ScanMs=100
WeaponDetection.ConfirmScans=2
WeaponDetection.RegionX=0
WeaponDetection.RegionY=70
WeaponDetection.RegionW=100
WeaponDetection.RegionH=30
WeaponDetection.ScaleTemplates=1
WeaponDetection.ReferenceWidth=1920
WeaponDetection.ReferenceHeight=1080
Detection.BackgroundReject=1
Detection.BackgroundFillLimit=68
Detection.BackgroundMode=balanced
Detection.AdaptiveScan=1
)"
        for line in StrSplit(defaults,"`n","`r") {
            pos := InStr(line,"=")
            key := SubStr(line,1,pos-1), value := SubStr(line,pos+1)
            entries[key] := {type:"text", default:value, min:"", max:"", choices:[], advanced:false}
        }
        for section in ["Camlock","Aimlock"] {
            for spec in [["CurveLowX",0.60,0,2],["CurveMidX",1.0,0,2],["CurveHighX",1.15,0,2],
                ["CurveLowY",0.60,0,2],["CurveMidY",1.0,0,2],["CurveHighY",1.15,0,2],
                ["AccelerationGainX",0.15,0,1],["AccelerationGainY",0.12,0,1]]
                entries[section "." spec[1]] := {type:"float",default:spec[2],min:spec[3],max:spec[4],choices:[],advanced:true}
        }
        this.Define(entries,"Movement.Hotkey","key","","")
        this.Define(entries,"Movement.StepMs","int",1,100)
        this.Define(entries,"Movement.Mode","choice","","")
        this.Define(entries,"Movement.StepMode","choice","","")
        this.Define(entries,"Movement.MiddleTaps","int",0,8)
        this.Define(entries,"Movement.WheelUp","bool","","")
        this.Define(entries,"Movement.WheelDown","bool","","")
        this.Define(entries,"WallHop.Hotkey","key","","")
        this.Define(entries,"WallHop.Direction","choice","","")
        this.Define(entries,"WallHop.DistancePx","int",1,2000)
        this.Define(entries,"WallHop.ReturnMs","int",0,250)
        this.Define(entries,"WallHop.CooldownMs","int",20,1000)
        this.Define(entries,"KeyRepeat.Hotkey","key","","")
        this.Define(entries,"KeyRepeat.Mode","choice","","")
        this.Define(entries,"KeyRepeat.OutputKey","key","","")
        this.Define(entries,"KeyRepeat.IntervalMs","int",10,1000)
        this.Define(entries,"KeyRepeat.HoldMs","int",0,100)
        this.Define(entries,"Recoil.FireKey","key","","")
        this.Define(entries,"Recoil.AimKey","key","","")
        this.Define(entries,"Recoil.RequireAim","bool","","")
        this.Define(entries,"Recoil.PullX","float",-50,50)
        this.Define(entries,"Recoil.PullY","float",-50,50)
        this.Define(entries,"Recoil.IntervalMs","int",2,100)
        this.Define(entries,"Recoil.MaxStep","int",1,50)
        this.Define(entries,"FOV.Source","choice","","")
        this.Define(entries,"FOV.Origin","choice","","")
        this.Define(entries,"FOV.Shape","choice","","")
        this.Define(entries,"FOV.Color","color","","")
        this.Define(entries,"FOV.Opacity","int",128,255)
        this.Define(entries,"FOV.Thickness","int",1,8)
        this.Define(entries,"FOV.OutlineStyle","choice","","")
        this.Define(entries,"CameraTurn.Hotkey","key","","")
        this.Define(entries,"CameraTurn.Angle","float",1,360)
        this.Define(entries,"CameraTurn.Direction","choice","","")
        this.Define(entries,"CameraTurn.Curve","choice","","")
        this.Define(entries,"CameraTurn.DurationMs","int",20,2000)
        this.Define(entries,"CameraTurn.CooldownMs","int",20,3000)
        this.Define(entries,"CameraTurn.UnitsPer360","float",1,100000)
        this.Define(entries,"CameraTurn.ReferenceSensitivity","float",0.001,10)
        this.Define(entries,"CameraTurn.Sensitivity","float",0.001,10)
        this.Define(entries,"CameraTurn.DpiScaling","bool","","")
        this.Define(entries,"CameraTurn.ReferenceDpi","int",100,32000)
        this.Define(entries,"CameraTurn.Dpi","int",100,32000)
        this.Define(entries,"WeaponDetection.Method","choice","","")
        this.Define(entries,"WeaponDetection.Action","choice","","")
        this.Define(entries,"WeaponDetection.ScanMs","int",50,1000)
        this.Define(entries,"WeaponDetection.ConfirmScans","int",1,8)
        this.Define(entries,"WeaponDetection.RegionX","float",0,99.9)
        this.Define(entries,"WeaponDetection.RegionY","float",0,99.9)
        this.Define(entries,"WeaponDetection.RegionW","float",0.1,100)
        this.Define(entries,"WeaponDetection.RegionH","float",0.1,100)
        this.Define(entries,"WeaponDetection.Template1","text","","")
        this.Define(entries,"WeaponDetection.Template2","text","","")
        this.Define(entries,"WeaponDetection.ScaleTemplates","bool","","")
        this.Define(entries,"WeaponDetection.ReferenceWidth","int",320,10000)
        this.Define(entries,"WeaponDetection.ReferenceHeight","int",240,10000)
        this.Define(entries,"WeaponDetection.Color1","color","","")
        this.Define(entries,"WeaponDetection.Color2","color","","")
        this.Define(entries,"WeaponDetection.Tolerance","int",0,255)
        this.Define(entries,"GunSpam.Hotkey","key","","")
        this.Define(entries,"GunSpam.IntervalMs","int",1,100)
        this.Define(entries,"GunSpam.ClickHoldMs","int",0,50)
        this.Define(entries,"GunSpam.BypassCtrl","bool","","")
        this.Define(entries,"GunSpam.BypassAlt","bool","","")
        this.Define(entries,"Emote.Hotkey","key","","")
        this.Define(entries,"Emote.MenuKey","key","","")
        this.Define(entries,"Emote.SlotKey","key","","")
        this.Define(entries,"Emote.PressCount","int",1,8)
        this.Define(entries,"Emote.OpenMs","int",0,500)
        this.Define(entries,"Emote.BetweenMs","int",0,500)
        this.Define(entries,"Emote.FinalMs","int",0,1000)
        this.Define(entries,"SOCD.Mode","choice","","")
        this.Define(entries,"SOCD.Left","key","","")
        this.Define(entries,"SOCD.Right","key","","")
        this.Define(entries,"SOCD.Up","key","","")
        this.Define(entries,"SOCD.Down","key","","")
        this.Define(entries,"Triggerbot.Hotkey","key","","")
        this.Define(entries,"Triggerbot.FireMode","choice","","")
        this.Define(entries,"Triggerbot.ConfirmMs","int",0,250)
        this.Define(entries,"Triggerbot.CooldownMs","int",0,1000)
        this.Define(entries,"Triggerbot.IgnoreHeldClick","bool","","")
        this.Define(entries,"Triggerbot.RequireStationary","bool","","")
        this.Define(entries,"Triggerbot.Origin","choice","","")
        this.Define(entries,"Triggerbot.Mode","choice","","")
        this.Define(entries,"Triggerbot.FovX","int",1,300)
        this.Define(entries,"Triggerbot.FovY","int",1,300)
        this.Define(entries,"Triggerbot.TargetColor","color","","")
        this.Define(entries,"Triggerbot.SecondaryColor","color","","")
        this.Define(entries,"Triggerbot.TertiaryColor","color","","")
        this.Define(entries,"Triggerbot.Tolerance","int",0,255)
        this.Define(entries,"Triggerbot.SecondaryTolerance","int",-1,255)
        this.Define(entries,"Triggerbot.TertiaryTolerance","int",-1,255)
        this.Define(entries,"Triggerbot.MinPixels","int",1,9)
        this.Define(entries,"Triggerbot.ConfirmRadius","int",1,100)
        this.Define(entries,"Triggerbot.VerifyBeforeFire","bool","","")
        this.Define(entries,"Triggerbot.ScaleMode","choice","","")
        this.Define(entries,"Triggerbot.ScanMs","int",1,100)
        this.Define(entries,"Triggerbot.ConfirmScans","int",1,8)
        this.Define(entries,"Triggerbot.RearmMs","int",0,500)
        this.Define(entries,"Triggerbot.ClickHoldMs","int",0,100)
        this.Define(entries,"Triggerbot.PostFireMs","int",0,250)
        this.Define(entries,"Camlock.Hotkey","key","","")
        this.Define(entries,"Aimlock.Hotkey","key","","")
        this.Define(entries,"Camlock.Mode","choice","","")
        this.Define(entries,"Aimlock.Mode","choice","","")
        this.Define(entries,"Camlock.TargetColor","color","","")
        this.Define(entries,"Aimlock.TargetColor","color","","")
        this.Define(entries,"Camlock.SecondaryColor","color","","")
        this.Define(entries,"Aimlock.SecondaryColor","color","","")
        this.Define(entries,"Camlock.TertiaryColor","color","","")
        this.Define(entries,"Aimlock.TertiaryColor","color","","")
        this.Define(entries,"Camlock.Tolerance","int",0,255)
        this.Define(entries,"Aimlock.Tolerance","int",0,255)
        this.Define(entries,"Camlock.SecondaryTolerance","int",-1,255)
        this.Define(entries,"Aimlock.SecondaryTolerance","int",-1,255)
        this.Define(entries,"Camlock.TertiaryTolerance","int",-1,255)
        this.Define(entries,"Aimlock.TertiaryTolerance","int",-1,255)
        this.Define(entries,"Camlock.MinPixels","int",1,9)
        this.Define(entries,"Aimlock.MinPixels","int",1,9)
        this.Define(entries,"Camlock.FovMode","choice","","")
        this.Define(entries,"Aimlock.FovMode","choice","","")
        this.Define(entries,"Camlock.Origin","choice","","")
        this.Define(entries,"Aimlock.Origin","choice","","")
        this.Define(entries,"Camlock.CameraFov","float",40,120)
        this.Define(entries,"Aimlock.CameraFov","float",40,120)
        this.Define(entries,"Camlock.FovX","float",1,1000)
        this.Define(entries,"Aimlock.FovX","float",1,1000)
        this.Define(entries,"Camlock.FovY","float",1,1000)
        this.Define(entries,"Aimlock.FovY","float",1,1000)
        this.Define(entries,"Camlock.ScaleMode","choice","","")
        this.Define(entries,"Aimlock.ScaleMode","choice","","")
        this.Define(entries,"Camlock.OffsetX","int",-500,500)
        this.Define(entries,"Aimlock.OffsetX","int",-500,500)
        this.Define(entries,"Camlock.OffsetY","int",-500,500)
        this.Define(entries,"Aimlock.OffsetY","int",-500,500)
        this.Define(entries,"Camlock.SecondaryOffsetX","int",-500,500)
        this.Define(entries,"Aimlock.SecondaryOffsetX","int",-500,500)
        this.Define(entries,"Camlock.SecondaryOffsetY","int",-500,500)
        this.Define(entries,"Aimlock.SecondaryOffsetY","int",-500,500)
        this.Define(entries,"Camlock.TertiaryOffsetX","int",-500,500)
        this.Define(entries,"Aimlock.TertiaryOffsetX","int",-500,500)
        this.Define(entries,"Camlock.TertiaryOffsetY","int",-500,500)
        this.Define(entries,"Aimlock.TertiaryOffsetY","int",-500,500)
        this.Define(entries,"Camlock.AngularMotion","bool","","")
        this.Define(entries,"Aimlock.AngularMotion","bool","","")
        this.Define(entries,"Camlock.TargetDot","bool","","")
        this.Define(entries,"Aimlock.TargetDot","bool","","")
        this.Define(entries,"Camlock.DotColor","color","","")
        this.Define(entries,"Aimlock.DotColor","color","","")
        this.Define(entries,"Camlock.DotSize","int",2,16)
        this.Define(entries,"Aimlock.DotSize","int",2,16)
        this.Define(entries,"Camlock.StrengthX","float",0.01,2.0)
        this.Define(entries,"Aimlock.StrengthX","float",0.01,2.0)
        this.Define(entries,"Camlock.StrengthY","float",0.01,2.0)
        this.Define(entries,"Aimlock.StrengthY","float",0.01,2.0)
        this.Define(entries,"Camlock.ResponseCurve","choice","","")
        this.Define(entries,"Aimlock.ResponseCurve","choice","","")
        this.Define(entries,"Camlock.ResponseMs","float",1,50)
        this.Define(entries,"Aimlock.ResponseMs","float",1,50)
        this.Define(entries,"Camlock.PredictionEnabled","bool","","")
        this.Define(entries,"Aimlock.PredictionEnabled","bool","","")
        this.Define(entries,"Camlock.LeadMsX","float",0,100)
        this.Define(entries,"Aimlock.LeadMsX","float",0,100)
        this.Define(entries,"Camlock.LeadMsY","float",0,100)
        this.Define(entries,"Aimlock.LeadMsY","float",0,100)
        this.Define(entries,"Camlock.VelocityBlend","float",0.05,1.0)
        this.Define(entries,"Aimlock.VelocityBlend","float",0.05,1.0)
        this.Define(entries,"Camlock.MaxLeadPx","float",0,250)
        this.Define(entries,"Aimlock.MaxLeadPx","float",0,250)
        this.Define(entries,"Camlock.LockRadius","int",4,300)
        this.Define(entries,"Aimlock.LockRadius","int",4,300)
        this.Define(entries,"Camlock.LockHoldMs","int",0,500)
        this.Define(entries,"Aimlock.LockHoldMs","int",0,500)
        this.Define(entries,"Camlock.SwitchDelayMs","int",0,400)
        this.Define(entries,"Aimlock.SwitchDelayMs","int",0,400)
        this.Define(entries,"Camlock.Deadzone","float",0,50)
        this.Define(entries,"Aimlock.Deadzone","float",0,50)
        this.Define(entries,"Camlock.MaxStep","int",1,500)
        this.Define(entries,"Aimlock.MaxStep","int",1,500)
        this.Define(entries,"Camlock.ScanMs","int",1,100)
        this.Define(entries,"Aimlock.ScanMs","int",1,100)
        this.Define(entries,"General.Master","bool","","")
        this.Define(entries,"App.TopBarEnabled","bool","","")
        this.Define(entries,"App.AutoLoadConfig","bool","","")
        this.Define(entries,"App.TopBarReserveSpace","bool","","")
        this.Define(entries,"App.CPUFriendly","bool","","")
        this.Define(entries,"App.CaptureExcluded","bool","","")
        this.Define(entries,"App.TypingMode","bool","","")
        this.Define(entries,"App.TypingKey","key","","")
        this.Define(entries,"App.StartWithWindows","bool","","")
        this.Define(entries,"App.AutoRecover","bool","","")
        this.Define(entries,"App.RememberPosition","bool","","")
        this.Define(entries,"App.CloseBehavior","choice","","")
        this.Define(entries,"App.AdvancedUI","bool","","")
        this.Define(entries,"Detection.BackgroundReject","bool","","")
        this.Define(entries,"Detection.BackgroundFillLimit","int",40,95)
        this.Define(entries,"Detection.BackgroundMode","choice","","")
        this.Define(entries,"Detection.AdaptiveScan","bool","","")
        this.Define(entries,"App.DeferRestarts","bool","","")
        this.Define(entries,"App.SessionMode","bool","","")
        this.Define(entries,"App.DeveloperMode","bool","","")
        for key, choices in Map("FOV.Origin",["camera","cursor"],"FOV.Source",["auto","camlock","aimlock","triggerbot"],
            "WeaponDetection.Method",["image","color","both"],"WeaponDetection.Action",["block matched","allow matched"],
            "CameraTurn.Curve",["eased","linear"],"CameraTurn.Direction",["left","right"],
            "Detection.BackgroundMode",["balanced","strict"]) {
            entries[key].type := "choice"
            entries[key].choices := choices
        }
        for section in ["Camlock","Aimlock","Triggerbot"] {
            for key, choices in Map("Mode",["hold","toggle","always"],"Origin",["camera","cursor"],"ScaleMode",["auto","raw"]) {
                entries[section "." key].type := "choice"
                entries[section "." key].choices := choices
            }
        }
        for key, item in entries {
            if InStr(key,"Modules.") = 1
                item.type := "bool"
            if RegExMatch(key,"\.(Curve|Acceleration|SecondaryTolerance|TertiaryTolerance|TertiaryOffset|ReferenceWidth|ReferenceHeight|AngularMotion|SwitchDelayMs|VelocityBlend|MaxLeadPx|ConfirmRadius|VerifyBeforeFire|MinPixels)")
                item.advanced := true
        }
        return entries
    }
    static Define(entries,key,kind,minV,maxV) {
        if !entries.Has(key)
            return
        item := entries[key]
        item.type := kind, item.min := minV, item.max := maxV
    }
    static Get(section,key) {
        return this.Entries.Has(section "." key) ? this.Entries[section "." key] : 0
    }
    static Default(section,key,fallback := "") {
        item := this.Get(section,key)
        return IsObject(item) ? item.default : fallback
    }
    static IsAdvanced(section,key) {
        item := this.Get(section,key)
        return IsObject(item) && item.advanced
    }
    static Resolve(section,key,raw) {
        item := this.Get(section,key)
        if !IsObject(item)
            return raw
        if item.type = "int" || item.type = "float" {
            value := IsNumber(raw) ? raw+0 : item.default+0
            if item.min != ""
                value := Max(item.min,value)
            if item.max != ""
                value := Min(item.max,value)
            return item.type = "int" ? Round(value) : value
        }
        if item.type = "bool"
            return raw = "1" ? 1 : raw = "0" ? 0 : item.default+0
        if item.type = "color"
            return (raw = "" && item.default = "") || RegExMatch(raw,"i)^0x[0-9a-f]{6}$") ? raw : item.default
        if item.type = "key" {
            if raw = ""
                return ""
            try {
                if GetKeyName(raw) != ""
                    return raw
            }
            return item.default
        }
        if item.type = "choice" && item.choices.Length {
            value := StrLower(Trim(raw))
            if section = "FOV" && key = "Origin" && value = "camera pov"
                value := "camera"
            for allowed in item.choices {
                if value = allowed
                    return allowed
            }
            return item.default
        }
        return raw
    }

    static ValidateFile(path) {
        for combined, item in this.Entries {
            dot := InStr(combined,".")
            section := SubStr(combined,1,dot-1), key := SubStr(combined,dot+1)
            raw := IniRead(path,section,key,"__SCHEMA_MISSING__")
            if raw = "__SCHEMA_MISSING__"
                continue
            valid := true
            if item.type = "int" || item.type = "float"
                valid := IsNumber(raw) && (item.min = "" || raw+0 >= item.min)
                    && (item.max = "" || raw+0 <= item.max) && (item.type != "int" || raw+0 = Round(raw+0))
            else if item.type = "bool"
                valid := raw = "0" || raw = "1"
            else if item.type = "color"
                valid := (raw = "" && item.default = "") || !!RegExMatch(raw,"i)^0x[0-9a-f]{6}$")
            else if item.type = "key" && raw != "" {
                try valid := GetKeyName(raw) != ""
                catch
                    valid := false
            } else if item.type = "choice" && item.choices.Length {
                value := StrLower(Trim(raw))
                if section = "FOV" && key = "Origin" && value = "camera pov"
                    value := "camera"
                valid := false
                for choice in item.choices {
                    if value = choice
                        valid := true
                }
            }
            if !valid
                throw ValueError("Invalid setting " combined ": " raw)
        }
        return true
    }
}
