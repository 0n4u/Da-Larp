#Include %A_LineFile%\..\SettingsSchema.ahk
#Include %A_LineFile%\..\ConfigIdentity.ahk

OpenPredictionCurveEditor(section, *) {
    global MainGui
    panel := Gui("+Owner" MainGui.Hwnd " -MaximizeBox", "Da Larp / " section " prediction")
    panel.BackColor := "1E1E1E"
    panel.SetFont("s9 cFFFFFF", "Segoe UI")
    panel.Add("Text", "x16 y12 w470 h24", section " / X and Y prediction curves")
    panel.SetFont("s8 cA6A6AA", "Segoe UI")
    panel.Add("Text", "x16 y38 w470 h34", "Lead is scaled at slow, medium and fast movement speeds. Separate acceleration gains prevent vertical overshoot.")
    panel.SetFont("s9 cFFFFFF", "Segoe UI")
    specs := [["CurveLowX","X / Slow",0,200],["CurveMidX","X / Medium",0,200],
        ["CurveHighX","X / Fast",0,200],["AccelerationGainX","X / Accel",0,100],
        ["CurveLowY","Y / Slow",0,200],["CurveMidY","Y / Medium",0,200],
        ["CurveHighY","Y / Fast",0,200],["AccelerationGainY","Y / Accel",0,100]]
    sliders := Map()
    for index, spec in specs {
        column := index <= 4 ? 0 : 1
        slot := column ? index-4 : index
        x := 16+column*245, y := 83+(slot-1)*66
        panel.Add("Text", "x" x " y" y " w215 h18", spec[2])
        current := SettingsSchema.Resolve(section, spec[1], Cfg(section, spec[1], SettingsSchema.Default(section,spec[1])))
        slider := panel.Add("Slider", "x" x " y" (y+21) " w214 h22 Range" spec[3] "-" spec[4], Round(current*100))
        sliders[spec[1]] := slider
        slider.OnEvent("Change", PredictionEditorPreview.Bind(panel,sliders))
    }
    panel.Add("Text", "x16 y351 w462 h48 vCurvePreview", "")
    panel.Add("Button", "x275 y410 w96 h29", "Cancel").OnEvent("Click", (*) => panel.Destroy())
    panel.Add("Button", "x383 y410 w96 h29 Default", "Save curves").OnEvent("Click", PredictionEditorSave.Bind(panel,sliders,section))
    PredictionEditorPreview(panel,sliders)
    panel.Show("w495 h455")
}

PredictionEditorPreview(panel, sliders, *) {
    if sliders.Count < 8
        return
    lowX := sliders["CurveLowX"].Value/100, midX := sliders["CurveMidX"].Value/100
    highX := sliders["CurveHighX"].Value/100
    lowY := sliders["CurveLowY"].Value/100, midY := sliders["CurveMidY"].Value/100
    highY := sliders["CurveHighY"].Value/100
    bar := (value) => SubStr("████████████████████", 1, Round(value*10))
    previewX := Format("X   {:.2f} / {:.2f} / {:.2f}       {}", lowX, midX, highX, bar(highX))
    previewY := Format("Y   {:.2f} / {:.2f} / {:.2f}       {}", lowY, midY, highY, bar(highY))
    panel["CurvePreview"].Text := previewX "`n" previewY
}

PredictionEditorSave(panel,sliders,section,*) {
    changes := []
    for key, slider in sliders
        changes.Push(Map("section",section,"key",key,"value",Format("{:.2f}",slider.Value/100)))
    if !ApplySettingsTransaction(changes,section " prediction curves") {
        MsgBox("Could not save prediction settings; previous settings were preserved.", "Da Larp", "Icon!")
        return
    }
    panel.Destroy()
    SetStatus(StrLower(section) " prediction curves saved", "ok")
}

OpenConfigDifferenceViewer(*) {
    global ConfigCatalog, ConfigSelection, MainGui
    if ConfigCatalog.Length < 2 {
        SetStatus("at least two configurations are needed to compare", "error")
        return
    }
    catalog := ConfigIdentitySnapshot(ConfigCatalog)
    labels := []
    for item in catalog
        labels.Push(item.label)
    panel := Gui("+Owner" MainGui.Hwnd " +Resize", "Da Larp / compare configurations")
    panel.BackColor := "1E1E1E"
    panel.SetFont("s9 cFFFFFF", "Segoe UI")
    panel.Add("Text", "x14 y10 w350 h20", "LEFT CONFIGURATION")
    panel.Add("Text", "x384 y10 w350 h20", "RIGHT CONFIGURATION")
    left := panel.Add("DropDownList", "x14 y32 w344 Choose" Max(1,ConfigSelection), labels)
    right := panel.Add("DropDownList", "x384 y32 w344 Choose" (ConfigSelection=1?2:1), labels)
    panel.Add("Text", "x14 y68 w700 h22", "Only changed settings are listed. No configuration is modified.")
    table := panel.Add("ListView", "x14 y95 w714 h430 Grid", ["Section", "Setting", "Left", "Right"])
    table.ModifyCol(1,110), table.ModifyCol(2,155), table.ModifyCol(3,210), table.ModifyCol(4,210)
    left.OnEvent("Change", ConfigDiffPopulate.Bind(catalog,left,right,table))
    right.OnEvent("Change", ConfigDiffPopulate.Bind(catalog,left,right,table))
    panel.OnEvent("Size", ConfigDiffResize.Bind(table))
    panel.Show("w744 h548")
    ConfigDiffPopulate(catalog,left,right,table)
}

ConfigDiffResize(table,gui,minMax,width,height) {
    if minMax=-1
        return
    table.Move(,,Max(340,width-30),Max(180,height-120))
}

ConfigDiffEntries(path) {
    entries := Map()
    for section in GameplaySections() {
        pairs := IniRead(path,section,,"")
        for line in StrSplit(pairs,"`n","`r") {
            pos := InStr(line,"=")
            if pos<2
                continue
            key := Trim(SubStr(line,1,pos-1))
            entries[section "." key] := Trim(SubStr(line,pos+1))
        }
    }
    return entries
}

ConfigDiffPopulate(catalog,left,right,table,*) {
    if left.Value<1 || right.Value<1 || left.Value>catalog.Length || right.Value>catalog.Length
        return
    if !FileExist(catalog[left.Value].path) || !FileExist(catalog[right.Value].path) {
        table.Delete()
        table.Add("","Configuration removed","Reopen comparison to refresh","","")
        return
    }
    a := ConfigDiffEntries(catalog[left.Value].path)
    b := ConfigDiffEntries(catalog[right.Value].path)
    keys := Map()
    for key,_ in a
        keys[key] := true
    for key,_ in b
        keys[key] := true
    table.Delete()
    for combined,_ in keys {
        before := a.Has(combined) ? a[combined] : "(missing)"
        after := b.Has(combined) ? b[combined] : "(missing)"
        if before=after
            continue
        pos := InStr(combined,".")
        table.Add("",SubStr(combined,1,pos-1),SubStr(combined,pos+1),before,after)
    }
    table.ModifyCol(1,110), table.ModifyCol(2,155), table.ModifyCol(3,210), table.ModifyCol(4,210)
}

OpenEffectiveDiagnostics(*) {
    global MainGui
    panel := Gui("+Owner" MainGui.Hwnd " +Resize", "Da Larp / effective settings and diagnostics")
    panel.SetFont("s9", "Segoe UI")
    panel.Add("Text","x12 y10 w910 h36","Effective values apply validation/defaults to saved settings. Worker load time identifies an older runtime snapshot. Refresh reads files only; no input is sent.")
    table := panel.Add("ListView","x12 y52 w910 h470 Grid",["Section / Worker","Setting","Saved / Published","Effective / Age"])
    refresh := EffectiveDiagnosticsRefresh.Bind(table)
    panel.Add("Button","x12 y534 w130 h28","Refresh snapshot").OnEvent("Click",refresh)
    panel.OnEvent("Size",EffectiveDiagnosticsResize.Bind(table))
    panel.Show("w934 h574")
    refresh.Call()
}

EffectiveDiagnosticsResize(table,gui,minMax,width,height) {
    if minMax != -1
        table.Move(,,Max(500,width-24),Max(200,height-104))
}

EffectiveDiagnosticsRefresh(table,*) {
    global CONFIG_PATH, WORKERS
    table.Delete()
    for combined, item in SettingsSchema.Entries {
        dot := InStr(combined,".")
        section := SubStr(combined,1,dot-1), key := SubStr(combined,dot+1)
        saved := IniRead(CONFIG_PATH,section,key,"(missing)")
        raw := saved = "(missing)" ? item.default : saved
        table.Add("",section,key,saved,SettingsSchema.Resolve(section,key,raw))
    }
    now := DllCall("kernel32\GetTickCount64","UInt64")
    for worker, _ in WORKERS {
        path := A_ScriptDir "\state\" StrLower(worker) ".status.ini"
        if !FileExist(path) {
            table.Add("",worker,"Worker snapshot","not published","")
            continue
        }
        try {
            for section in StrSplit(IniRead(path),"`n","`r") {
                for pair in StrSplit(IniRead(path,section,,""),"`n","`r") {
                    pos := InStr(pair,"=")
                    if pos < 2
                        continue
                    key := SubStr(pair,1,pos-1), value := SubStr(pair,pos+1)
                    age := (key = "Updated" || key = "ConfigLoadedAt") && IsNumber(value)
                        ? (now >= value+0 ? (now-value) " ms ago" : "clock mismatch") : ""
                    if key = "ConfigModified"
                        age := value = FileGetTime(CONFIG_PATH) ? "matches saved file" : "saved file changed since worker load"
                    table.Add("",worker " / " section,key,value,age)
                }
            }
        } catch as err
            table.Add("",worker,"Snapshot read",err.Message,"")
    }
    table.ModifyCol(1,160), table.ModifyCol(2,190), table.ModifyCol(3,280), table.ModifyCol(4,250)
}
