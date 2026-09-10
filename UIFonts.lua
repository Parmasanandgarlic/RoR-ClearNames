ClearNames = ClearNames or {}
ClearNames.UIFonts = ClearNames.UIFonts or {}
ClearNames.UIFonts.delegate = ClearNames.UIFonts.delegate or nil
ClearNames.UIFonts.hooked = false
ClearNames.UIFonts.active = false
ClearNames.UIFonts.mappedCalls = ClearNames.UIFonts.mappedCalls or 0
ClearNames.UIFonts.registeredRefreshEvents = ClearNames.UIFonts.registeredRefreshEvents or {}

local validModes = {
    off = true,
    readable = true,
    large = true,
}

local readableMap = {
    font_clear_tiny = "font_clear_small_bold",
    font_clear_small = "font_clear_small_bold",
    font_clear_medium = "font_clear_medium_bold",
    font_clear_large = "font_clear_large_bold",
    font_default_text_small = "font_clear_medium_bold",
    font_default_text = "font_clear_medium_bold",
    font_default_text_no_outline = "font_clear_medium_bold",
    font_default_text_large = "font_clear_medium_bold",
    font_chat_text = "font_clear_medium_bold",
    font_chat_text_no_outline = "font_clear_medium_bold",
    font_chat_text_bold = "font_clear_medium_bold",
    font_heading_target_mouseover_name = "font_clear_medium_bold",
    font_heading_unitframe_large_name = "font_clear_medium_bold",
    font_heading_rank = "font_clear_medium_bold",
}

local largeMap = {
    font_clear_tiny = "font_clear_medium_bold",
    font_clear_small = "font_clear_medium_bold",
    font_clear_medium = "font_clear_large_bold",
    font_clear_large = "font_clear_large_bold",
    font_default_text_small = "font_clear_medium_bold",
    font_default_text = "font_clear_large_bold",
    font_default_text_no_outline = "font_clear_large_bold",
    font_default_text_large = "font_clear_large_bold",
    font_chat_text = "font_clear_large_bold",
    font_chat_text_no_outline = "font_clear_large_bold",
    font_chat_text_bold = "font_clear_large_bold",
    font_heading_target_mouseover_name = "font_clear_large_bold",
    font_heading_unitframe_large_name = "font_clear_large_bold",
    font_heading_rank = "font_clear_medium_bold",
}

local refreshEventKeys = {
    "LOADING_END",
    "GROUP_UPDATED",
    "GROUP_PLAYER_ADDED",
}

local knownLabels = {
    { name = "PlayerWindowPlayerName", font = "font_heading_unitframe_large_name" },
    { name = "PlayerWindowLevelText", font = "font_heading_rank" },
    { name = "TargetWindowName", font = "font_heading_unitframe_large_name" },
    { name = "FriendlyTargetWindowName", font = "font_heading_unitframe_large_name" },
    { name = "MouseOverTargetUnitWindowName", font = "font_heading_target_mouseover_name" },
}

local function normalizedMode(mode)
    local value = string.lower(tostring(mode or ""))
    if validModes[value] then return value end
    return nil
end

local function activeMode()
    local mode = ClearNames.Settings and normalizedMode(ClearNames.Settings.uiFontMode) or nil
    return mode or "off"
end

local function defaultLineSpacing()
    if WindowUtils and WindowUtils.FONT_DEFAULT_TEXT_LINESPACING ~= nil then
        return WindowUtils.FONT_DEFAULT_TEXT_LINESPACING
    end
    return 0
end

function ClearNames.UIFonts.Resolve(fontName, mode)
    local selected = normalizedMode(mode) or activeMode()
    if selected == "off" then return fontName end
    local map = selected == "large" and largeMap or readableMap
    local mapped = map[fontName]
    return mapped or fontName
end

function ClearNames.UIFonts.IsHooked()
    return type(LabelSetFont) == "function" and LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont
end

function ClearNames.UIFonts.WrappedLabelSetFont(windowName, fontName, lineSpacing)
    local delegate = ClearNames.UIFonts.delegate
    if type(delegate) ~= "function" then return false end

    local resolved = fontName
    if ClearNames.UIFonts.active then
        resolved = ClearNames.UIFonts.Resolve(fontName, activeMode())
        if resolved ~= fontName then
            ClearNames.UIFonts.mappedCalls = ClearNames.UIFonts.mappedCalls + 1
        end
    end

    return delegate(windowName, resolved, lineSpacing)
end

function ClearNames.UIFonts.InstallHook()
    if type(LabelSetFont) ~= "function" then return false end

    if LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont then
        ClearNames.UIFonts.hooked = true
        return true
    end

    -- A retained delegate means another addon replaced our wrapper after installation.
    -- Do not seize the global function back from it; remain available in its chain.
    if ClearNames.UIFonts.delegate ~= nil then
        ClearNames.UIFonts.hooked = false
        return false
    end

    ClearNames.UIFonts.delegate = LabelSetFont
    LabelSetFont = ClearNames.UIFonts.WrappedLabelSetFont
    ClearNames.UIFonts.hooked = true
    return true
end

function ClearNames.UIFonts.OnUiRefreshEvent()
    if not ClearNames.UIFonts.active then return 0 end
    return ClearNames.UIFonts.RefreshKnown()
end

function ClearNames.UIFonts.RegisterRefreshEvents()
    if #ClearNames.UIFonts.registeredRefreshEvents > 0 then return true end
    if type(RegisterEventHandler) ~= "function" or type(UnregisterEventHandler) ~= "function" then return false end
    if not SystemData or not SystemData.Events then return false end

    local _, key
    for _, key in ipairs(refreshEventKeys) do
        local eventId = SystemData.Events[key]
        if eventId ~= nil then
            RegisterEventHandler(eventId, "ClearNames.UIFonts.OnUiRefreshEvent")
            table.insert(ClearNames.UIFonts.registeredRefreshEvents, eventId)
        end
    end
    return #ClearNames.UIFonts.registeredRefreshEvents > 0
end

function ClearNames.UIFonts.UnregisterRefreshEvents()
    if #ClearNames.UIFonts.registeredRefreshEvents == 0 then return true end
    if type(UnregisterEventHandler) ~= "function" then return false end

    local _, eventId
    for _, eventId in ipairs(ClearNames.UIFonts.registeredRefreshEvents) do
        UnregisterEventHandler(eventId, "ClearNames.UIFonts.OnUiRefreshEvent")
    end
    ClearNames.UIFonts.registeredRefreshEvents = {}
    return true
end

function ClearNames.UIFonts.RemoveHook()
    ClearNames.UIFonts.UnregisterRefreshEvents()
    ClearNames.UIFonts.active = false
    ClearNames.UIFonts.hooked = false

    if LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont then
        LabelSetFont = ClearNames.UIFonts.delegate
        ClearNames.UIFonts.delegate = nil
        return true
    end

    -- Another addon may have wrapped us and still delegate through our function.
    -- Keep our delegate alive so that chain remains functional, but remapping stays off.
    return false
end

local function refreshLabel(windowName, originalFont)
    if type(LabelSetFont) ~= "function" then return false end
    if type(DoesWindowExist) ~= "function" or not DoesWindowExist(windowName) then return false end

    local spacing = defaultLineSpacing()
    if LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont then
        LabelSetFont(windowName, originalFont, spacing)
    else
        local resolved = ClearNames.UIFonts.active and ClearNames.UIFonts.Resolve(originalFont, activeMode()) or originalFont
        if resolved ~= originalFont then
            ClearNames.UIFonts.mappedCalls = ClearNames.UIFonts.mappedCalls + 1
        end
        LabelSetFont(windowName, resolved, spacing)
    end
    return true
end

function ClearNames.UIFonts.RefreshKnown()
    local refreshed = 0
    local _, entry
    for _, entry in ipairs(knownLabels) do
        if refreshLabel(entry.name, entry.font) then refreshed = refreshed + 1 end
    end

    local i
    for i = 1, 5 do
        if refreshLabel("GroupWindowPlayer" .. i .. "Name", "font_heading_unitframe_large_name") then
            refreshed = refreshed + 1
        end
    end
    return refreshed
end

function ClearNames.UIFonts.SetMode(mode)
    local selected = normalizedMode(mode)
    if not selected then return false end

    ClearNames.Settings = ClearNames.Settings or {}
    ClearNames.Settings.uiFontMode = selected
    ClearNames.UIFonts.active = selected ~= "off"

    if selected == "off" then
        ClearNames.UIFonts.RefreshKnown()
        ClearNames.UIFonts.RemoveHook()
        return true
    end

    ClearNames.UIFonts.InstallHook()
    ClearNames.UIFonts.RegisterRefreshEvents()
    ClearNames.UIFonts.RefreshKnown()
    return true
end
