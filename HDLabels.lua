ClearNames = ClearNames or {}
ClearNames.HDLabels = ClearNames.HDLabels or {}
ClearNames.HDLabels.enabled = false
ClearNames.HDLabels.windows = ClearNames.HDLabels.windows or {}
ClearNames.HDLabels.counter = ClearNames.HDLabels.counter or 0

function ClearNames.HDLabels.IsSupported()
    return type(AttachWindowToWorldObject) == "function" and type(CreateWindowFromTemplate) == "function"
end

function ClearNames.HDLabels.SetEnabled(enabled)
    ClearNames.HDLabels.enabled = enabled == true
    if not ClearNames.HDLabels.enabled then ClearNames.HDLabels.DetachAll() end
    if ClearNames.Settings then ClearNames.Settings.hdEnabled = ClearNames.HDLabels.enabled end
    return ClearNames.HDLabels.enabled
end

function ClearNames.HDLabels.Attach(worldObjNum, text)
    if not ClearNames.HDLabels.enabled then return false end
    if not ClearNames.HDLabels.IsSupported() then return false end
    if type(worldObjNum) ~= "number" or worldObjNum <= 0 then return false end
    ClearNames.HDLabels.counter = ClearNames.HDLabels.counter + 1
    local windowName = "ClearNamesHDLabel" .. tostring(ClearNames.HDLabels.counter)
    CreateWindowFromTemplate(windowName, "ClearNamesHDLabelTemplate", "Root")
    LabelSetText(windowName .. "Text", text or L"")
    AttachWindowToWorldObject(windowName, worldObjNum)
    ClearNames.HDLabels.windows[worldObjNum] = windowName
    return true
end

function ClearNames.HDLabels.Detach(worldObjNum)
    local windowName = ClearNames.HDLabels.windows[worldObjNum]
    if not windowName then return false end
    if type(DetachWindowFromWorldObject) == "function" then DetachWindowFromWorldObject(windowName) end
    if type(DestroyWindow) == "function" then DestroyWindow(windowName) end
    ClearNames.HDLabels.windows[worldObjNum] = nil
    return true
end

function ClearNames.HDLabels.DetachAll()
    local ids, id = {}, nil
    for id, _ in pairs(ClearNames.HDLabels.windows) do table.insert(ids, id) end
    local _, worldObjNum
    for _, worldObjNum in ipairs(ids) do ClearNames.HDLabels.Detach(worldObjNum) end
end
