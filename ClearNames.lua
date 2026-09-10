ClearNames = ClearNames or {}
ClearNames.VERSION = "0.1.1"
ClearNames.Settings = ClearNames.Settings or {}
ClearNames.FontScores = ClearNames.FontScores or {}
ClearNames.WindowName = "ClearNamesWindow"

local function wtext(s) return towstring and towstring(s) or s end
local function say(s)
    if d then d(wtext("[ClearNames] " .. s)) end
end

local function defaults()
    if not ClearNames.Settings.nameFont then ClearNames.Settings.nameFont = "font_clear_large_bold" end
    if not ClearNames.Settings.titleFont then ClearNames.Settings.titleFont = "font_clear_medium_bold" end
    if ClearNames.Settings.hdEnabled == nil then ClearNames.Settings.hdEnabled = false end
    if not ClearNames.Settings.uiFontMode then ClearNames.Settings.uiFontMode = "readable" end
    if not ClearNames.Settings.profile then ClearNames.Settings.profile = "Maximum Readability" end
end

function ClearNames.ApplyCurrentFonts()
    return ClearNames.NativeRenderer.ApplyFonts(ClearNames.Settings.nameFont, ClearNames.Settings.titleFont)
end

function ClearNames.CycleName(direction)
    local f = direction < 0 and ClearNames.Fonts.Previous(ClearNames.Settings.nameFont) or ClearNames.Fonts.Next(ClearNames.Settings.nameFont)
    ClearNames.Settings.nameFont = f.name
    ClearNames.ApplyCurrentFonts(); ClearNames.UpdateWindow()
end

function ClearNames.CycleTitle(direction)
    local f = direction < 0 and ClearNames.Fonts.Previous(ClearNames.Settings.titleFont) or ClearNames.Fonts.Next(ClearNames.Settings.titleFont)
    ClearNames.Settings.titleFont = f.name
    ClearNames.ApplyCurrentFonts(); ClearNames.UpdateWindow()
end

function ClearNames.Rate(bucket)
    local font = ClearNames.Settings.nameFont
    local current = ClearNames.FontScores[font] and ClearNames.FontScores[font][bucket] or 0
    local nextStars = (current % 5) + 1
    ClearNames.FontLab.Rate(font, bucket, nextStars)
    say(bucket .. " rating for " .. font .. " = " .. tostring(nextStars) .. "/5")
    ClearNames.UpdateWindow()
end

function ClearNames.ApplyProfile(name)
    if ClearNames.Profiles.Apply(name) then say("profile: " .. name); ClearNames.UpdateWindow() else say("unknown profile") end
end

function ClearNames.Restore()
    if ClearNames.NativeRenderer.RestoreOriginal() then say("original name settings restored") else say("no captured settings to restore") end
end

function ClearNames.Doctor()
    local setfont = type(SetNamesAndTitlesFont) == "function" and "OK" or "MISSING"
    local attach = type(AttachWindowToWorldObject) == "function" and "OK" or "MISSING"
    local create = type(CreateWindowFromTemplate) == "function" and "OK" or "MISSING"
    local rec, score = ClearNames.FontLab.Recommend()
    say("v" .. ClearNames.VERSION .. " | SetNamesAndTitlesFont=" .. setfont .. " | AttachWindowToWorldObject=" .. attach .. " | CreateWindowFromTemplate=" .. create)
    say("name=" .. ClearNames.Settings.nameFont .. " | title=" .. ClearNames.Settings.titleFont .. " | profile=" .. ClearNames.Settings.profile)
    local uiMode = ClearNames.Settings.uiFontMode or "off"
    local uiHook = ClearNames.UIFonts and ClearNames.UIFonts.IsHooked and ClearNames.UIFonts.IsHooked() and "HOOKED" or "PASSIVE"
    local mapped = ClearNames.UIFonts and ClearNames.UIFonts.mappedCalls or 0
    say("UIFonts=" .. uiHook .. " mode=" .. tostring(uiMode) .. " mapped=" .. tostring(mapped))
    say("recommendation=" .. tostring(rec) .. " score=" .. tostring(score))
end

function ClearNames.ToggleWindow()
    if type(WindowGetShowing) ~= "function" or type(WindowSetShowing) ~= "function" then return end
    WindowSetShowing(ClearNames.WindowName, not WindowGetShowing(ClearNames.WindowName))
    ClearNames.UpdateWindow()
end

function ClearNames.UpdateWindow()
    if type(DoesWindowExist) == "function" and not DoesWindowExist(ClearNames.WindowName) then return end
    if type(LabelSetText) ~= "function" then return end
    LabelSetText("ClearNamesNameValue", wtext(ClearNames.Settings.nameFont))
    LabelSetText("ClearNamesTitleValue", wtext(ClearNames.Settings.titleFont))
    LabelSetText("ClearNamesProfileValue", wtext(ClearNames.Settings.profile or "custom"))
    local rec, score = ClearNames.FontLab.Recommend()
    LabelSetText("ClearNamesRecommendation", wtext("Best: " .. tostring(rec) .. " (" .. tostring(score) .. ")"))
    local _, bucket
    for _, bucket in ipairs(ClearNames.FontLab.Buckets) do
        local value = ClearNames.FontScores[ClearNames.Settings.nameFont] and ClearNames.FontScores[ClearNames.Settings.nameFont][bucket] or 0
        local widget = ({near="ClearNamesRateNear", mid="ClearNamesRateMid", far="ClearNamesRateFar", extreme="ClearNamesRateExtreme"})[bucket]
        if type(ButtonSetText) == "function" then ButtonSetText(widget, wtext(bucket .. ": " .. tostring(value) .. "/5")) end
    end
end

function ClearNames.OnNamePrev() ClearNames.CycleName(-1) end
function ClearNames.OnNameNext() ClearNames.CycleName(1) end
function ClearNames.OnTitlePrev() ClearNames.CycleTitle(-1) end
function ClearNames.OnTitleNext() ClearNames.CycleTitle(1) end
function ClearNames.OnRateNear() ClearNames.Rate("near") end
function ClearNames.OnRateMid() ClearNames.Rate("mid") end
function ClearNames.OnRateFar() ClearNames.Rate("far") end
function ClearNames.OnRateExtreme() ClearNames.Rate("extreme") end
function ClearNames.OnClose() if type(WindowSetShowing)=="function" then WindowSetShowing(ClearNames.WindowName, false) end end

function ClearNames.Command(args)
    local text = tostring(args or "")
    local cmd, rest = string.match(text, "^%s*(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")
    if cmd == "" or cmd == "lab" then ClearNames.ToggleWindow()
    elseif cmd == "doctor" then ClearNames.Doctor()
    elseif cmd == "restore" then ClearNames.Restore()
    elseif cmd == "profile" then ClearNames.ApplyProfile(rest)
    elseif cmd == "font" then if ClearNames.Fonts.Get(rest) then ClearNames.Settings.nameFont=rest; ClearNames.ApplyCurrentFonts(); ClearNames.UpdateWindow() else say("unknown font") end
    elseif cmd == "hd" then ClearNames.HDLabels.SetEnabled(string.lower(rest)=="on"); say("experimental HD labels " .. (ClearNames.HDLabels.enabled and "ON" or "OFF"))
    elseif cmd == "ui" then
        local mode = string.lower(rest or "")
        if ClearNames.UIFonts.SetMode(mode) then say("UI font mode " .. mode) else say("ui mode must be off, readable, or large") end
    elseif cmd == "help" then say("/clearnames lab | doctor | restore | profile <name> | font <resource> | hd on|off | ui off|readable|large")
    else say("unknown command; use /clearnames help") end
end

function ClearNames.OnInitialize()
    defaults()
    ClearNames.NativeRenderer.CaptureOriginal()
    ClearNames.ApplyCurrentFonts()
    ClearNames.Profiles.Apply(ClearNames.Settings.profile)
    ClearNames.UIFonts.SetMode(ClearNames.Settings.uiFontMode)
    if type(WindowRegisterEventHandler) == "function" and SystemData and SystemData.Events and SystemData.Events.PLAYER_TARGET_UPDATED then
        WindowRegisterEventHandler("Root", SystemData.Events.PLAYER_TARGET_UPDATED, "ClearNames.HDLabels.OnTargetUpdated")
    end
    ClearNames.HDLabels.SetEnabled(ClearNames.Settings.hdEnabled == true)
    if LibSlash and type(LibSlash.RegisterSlashCmd) == "function" then
        LibSlash.RegisterSlashCmd("clearnames", ClearNames.Command)
        LibSlash.RegisterSlashCmd("cn", ClearNames.Command)
    end
    if type(WindowSetShowing) == "function" then WindowSetShowing(ClearNames.WindowName, false) end
    say("loaded v" .. ClearNames.VERSION .. ". Use /clearnames lab")
end

function ClearNames.OnShutdown()
    if type(WindowUnregisterEventHandler) == "function" and SystemData and SystemData.Events and SystemData.Events.PLAYER_TARGET_UPDATED then
        WindowUnregisterEventHandler("Root", SystemData.Events.PLAYER_TARGET_UPDATED)
    end
    ClearNames.HDLabels.CancelPendingTargetSync()
    ClearNames.HDLabels.unitObjects = {}
    ClearNames.HDLabels.DetachAll()
    ClearNames.UIFonts.RemoveHook()
end
