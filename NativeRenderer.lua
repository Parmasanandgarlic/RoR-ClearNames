ClearNames = ClearNames or {}
ClearNames.NativeRenderer = ClearNames.NativeRenderer or {}

local visibilityKeys = {
    "friendlyplayers", "enemyplayers", "friendlynpcs", "enemynpcs",
    "yourname", "petname", "targetname", "yourtitle", "friendlytitles",
    "enemytitles", "npctitles", "targettitle", "yourguild", "friendlyguilds",
    "enemyguilds", "targetguild"
}

local function namesSettings()
    if SystemData and SystemData.Settings then return SystemData.Settings.Names end
    return nil
end

function ClearNames.NativeRenderer.CaptureOriginal()
    if ClearNames.OriginalNamesSettings then return true end
    local src = namesSettings()
    if not src then return false end
    local copy = { font = src.font }
    local _, key
    for _, key in ipairs(visibilityKeys) do copy[key] = src[key] end
    ClearNames.OriginalNamesSettings = copy
    return true
end

function ClearNames.NativeRenderer.ApplyFonts(nameFont, titleFont)
    if type(nameFont) ~= "string" or type(titleFont) ~= "string" then return false end
    if type(SetNamesAndTitlesFont) ~= "function" then return false end
    SetNamesAndTitlesFont(nameFont, titleFont)
    if ClearNames.Settings then
        ClearNames.Settings.nameFont = nameFont
        ClearNames.Settings.titleFont = titleFont
    end
    return true
end

function ClearNames.NativeRenderer.ApplyVisibility(values)
    local dst = namesSettings()
    if not dst or type(values) ~= "table" then return false end
    local _, key
    for _, key in ipairs(visibilityKeys) do
        if values[key] ~= nil then dst[key] = values[key] end
    end
    return true
end

function ClearNames.NativeRenderer.RestoreOriginal()
    local original = ClearNames.OriginalNamesSettings
    if not original then return false end
    ClearNames.NativeRenderer.ApplyVisibility(original)
    local suffix = ""
    if original.font == 1 then suffix = "_old" end
    if type(SetNamesAndTitlesFont) == "function" then
        SetNamesAndTitlesFont("font_name_plate_names" .. suffix, "font_name_plate_titles" .. suffix)
    end
    if namesSettings() then namesSettings().font = original.font end
    return true
end
