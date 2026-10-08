ConfigUniqueLabel(label, used) {
    original := label, serial := 2
    loop {
        exists := false
        for previous, _ in used {
            if StrLower(previous) = StrLower(label) {
                exists := true
                break
            }
        }
        if !exists
            break
        label := original " (" serial++ ")"
    }
    used[StrLower(label)] := true
    return label
}

ConfigIdentitySnapshot(catalog) {
    snapshot := []
    for item in catalog
        snapshot.Push({label:item.label,path:item.path})
    return snapshot
}
