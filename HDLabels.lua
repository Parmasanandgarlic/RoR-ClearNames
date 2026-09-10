ClearNames = ClearNames or {}
ClearNames.HDLabels = ClearNames.HDLabels or {}
ClearNames.HDLabels.enabled = false
ClearNames.HDLabels.windows = ClearNames.HDLabels.windows or {}
ClearNames.HDLabels.unitObjects = ClearNames.HDLabels.unitObjects or {}
ClearNames.HDLabels.pendingUnits = ClearNames.HDLabels.pendingUnits or {}
ClearNames.HDLabels.counter = ClearNames.HDLabels.counter or 0
ClearNames.HDLabels.flushScheduled = false

local trackedUnits = {
    selfhostiletarget = true,
    selffriendlytarget = true,
    mouseovertarget = true,
}

local function targetInfoCall(methodName, unitId)
    if type(TargetInfo) ~= "table" then return nil end
    local ok, value = pcall(function()
        if methodName == "UnitEntityId" and type(TargetInfo.UnitEntityId) == "function" then
            return TargetInfo:UnitEntityId(unitId)
        elseif methodName == "UnitName" and type(TargetInfo.UnitName) == "function" then
            return TargetInfo:UnitName(unitId)
        elseif methodName == "UnitIsNPC" and type(TargetInfo.UnitIsNPC) == "function" then
            return TargetInfo:UnitIsNPC(unitId)
        end
        return nil
    end)
    if not ok then return nil end
    return value
end

local function worldObjectStillReferenced(worldObjNum)
    local _, current
    for _, current in pairs(ClearNames.HDLabels.unitObjects) do
        if current == worldObjNum then return true end
    end
    return false
end

function ClearNames.HDLabels.IsSupported()
    return type(AttachWindowToWorldObject) == "function"
        and type(CreateWindowFromTemplate) == "function"
        and type(LabelSetText) == "function"
        and type(WindowSetScale) == "function"
        and type(TargetInfo) == "table"
end

function ClearNames.HDLabels.CancelPendingTargetSync()
    ClearNames.HDLabels.pendingUnits = {}
    if ClearNames.HDLabels.flushScheduled and type(WindowUnregisterCoreEventHandler) == "function" then
        WindowUnregisterCoreEventHandler("Root", "OnUpdate")
    end
    ClearNames.HDLabels.flushScheduled = false
end

function ClearNames.HDLabels.SetEnabled(enabled)
    ClearNames.HDLabels.enabled = enabled == true
    if not ClearNames.HDLabels.enabled then
        ClearNames.HDLabels.CancelPendingTargetSync()
        ClearNames.HDLabels.unitObjects = {}
        ClearNames.HDLabels.DetachAll()
    else
        ClearNames.HDLabels.QueueTargetSync("selfhostiletarget")
        ClearNames.HDLabels.QueueTargetSync("selffriendlytarget")
        ClearNames.HDLabels.QueueTargetSync("mouseovertarget")
    end
    if ClearNames.Settings then ClearNames.Settings.hdEnabled = ClearNames.HDLabels.enabled end
    return ClearNames.HDLabels.enabled
end

function ClearNames.HDLabels.Attach(worldObjNum, text)
    if not ClearNames.HDLabels.enabled then return false end
    if not ClearNames.HDLabels.IsSupported() then return false end
    if type(worldObjNum) ~= "number" or worldObjNum <= 0 then return false end

    local existing = ClearNames.HDLabels.windows[worldObjNum]
    if existing then
        LabelSetText(existing .. "Text", text or L"")
        WindowSetScale(existing, 1.0)
        if type(WindowSetShowing) == "function" then WindowSetShowing(existing, true) end
        return true
    end

    ClearNames.HDLabels.counter = ClearNames.HDLabels.counter + 1
    local windowName = "ClearNamesHDLabel" .. tostring(ClearNames.HDLabels.counter)
    CreateWindowFromTemplate(windowName, "ClearNamesHDLabelTemplate", "Root")

    if type(DoesWindowExist) == "function" and not DoesWindowExist(windowName) then return false end

    LabelSetText(windowName .. "Text", text or L"")
    WindowSetScale(windowName, 1.0)
    if type(WindowSetShowing) == "function" then WindowSetShowing(windowName, true) end

    local ok = pcall(AttachWindowToWorldObject, windowName, worldObjNum)
    if not ok then
        if type(DestroyWindow) == "function" then DestroyWindow(windowName) end
        return false
    end

    ClearNames.HDLabels.windows[worldObjNum] = windowName
    return true
end

function ClearNames.HDLabels.Detach(worldObjNum)
    local windowName = ClearNames.HDLabels.windows[worldObjNum]
    if not windowName then return false end
    if type(DetachWindowFromWorldObject) == "function" then pcall(DetachWindowFromWorldObject, windowName) end
    if type(DestroyWindow) == "function" then pcall(DestroyWindow, windowName) end
    ClearNames.HDLabels.windows[worldObjNum] = nil
    return true
end

function ClearNames.HDLabels.ReleaseUnit(unitId)
    local previous = ClearNames.HDLabels.unitObjects[unitId]
    if not previous then return false end
    ClearNames.HDLabels.unitObjects[unitId] = nil
    if not worldObjectStillReferenced(previous) then ClearNames.HDLabels.Detach(previous) end
    return true
end

function ClearNames.HDLabels.SyncUnit(unitId)
    if not trackedUnits[unitId] then return false end
    if not ClearNames.HDLabels.enabled or not ClearNames.HDLabels.IsSupported() then
        ClearNames.HDLabels.ReleaseUnit(unitId)
        return false
    end

    local isNpc = targetInfoCall("UnitIsNPC", unitId)
    local worldObjNum = targetInfoCall("UnitEntityId", unitId)
    local name = targetInfoCall("UnitName", unitId)

    if isNpc ~= true or type(worldObjNum) ~= "number" or worldObjNum <= 0 or name == nil then
        ClearNames.HDLabels.ReleaseUnit(unitId)
        return false
    end

    local previous = ClearNames.HDLabels.unitObjects[unitId]
    if previous and previous ~= worldObjNum then
        ClearNames.HDLabels.unitObjects[unitId] = nil
        if not worldObjectStillReferenced(previous) then ClearNames.HDLabels.Detach(previous) end
    end

    if not ClearNames.HDLabels.Attach(worldObjNum, name) then return false end
    ClearNames.HDLabels.unitObjects[unitId] = worldObjNum
    return true
end

function ClearNames.HDLabels.QueueTargetSync(unitId)
    if not ClearNames.HDLabels.enabled or not trackedUnits[unitId] then return false end
    ClearNames.HDLabels.pendingUnits[unitId] = true
    if ClearNames.HDLabels.flushScheduled then return true end

    if type(WindowRegisterCoreEventHandler) ~= "function" then
        ClearNames.HDLabels.pendingUnits[unitId] = nil
        return ClearNames.HDLabels.SyncUnit(unitId)
    end

    ClearNames.HDLabels.flushScheduled = true
    WindowRegisterCoreEventHandler("Root", "OnUpdate", "ClearNames.HDLabels.FlushPendingTargetSync")
    return true
end

function ClearNames.HDLabels.FlushPendingTargetSync()
    if type(WindowUnregisterCoreEventHandler) == "function" then
        WindowUnregisterCoreEventHandler("Root", "OnUpdate")
    end
    ClearNames.HDLabels.flushScheduled = false

    local pending = ClearNames.HDLabels.pendingUnits
    ClearNames.HDLabels.pendingUnits = {}
    local unitId, _
    for unitId, _ in pairs(pending) do ClearNames.HDLabels.SyncUnit(unitId) end
end

function ClearNames.HDLabels.OnTargetUpdated(targetClassification)
    if not ClearNames.HDLabels.enabled then return end
    if trackedUnits[targetClassification] then ClearNames.HDLabels.QueueTargetSync(targetClassification) end
end

function ClearNames.HDLabels.DetachAll()
    local ids, id = {}, nil
    for id, _ in pairs(ClearNames.HDLabels.windows) do table.insert(ids, id) end
    local _, worldObjNum
    for _, worldObjNum in ipairs(ids) do ClearNames.HDLabels.Detach(worldObjNum) end
end
