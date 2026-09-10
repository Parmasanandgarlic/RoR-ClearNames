local calls = {}
local registered = {}
local unregistered = {}

local function originalLabelSetFont(windowName, fontName, lineSpacing)
    table.insert(calls, { window = windowName, font = fontName, spacing = lineSpacing })
    return true
end

LabelSetFont = originalLabelSetFont
DoesWindowExist = function(windowName)
    return windowName == "TargetWindowName"
        or windowName == "GroupWindowPlayer1Name"
        or windowName == "PlayerWindowPlayerName"
end
WindowUtils = { FONT_DEFAULT_TEXT_LINESPACING = 7 }
SystemData = {
    Events = {
        LOADING_END = 101,
        GROUP_UPDATED = 102,
        GROUP_PLAYER_ADDED = 103,
    }
}
RegisterEventHandler = function(eventId, callback)
    table.insert(registered, { eventId = eventId, callback = callback })
end
UnregisterEventHandler = function(eventId, callback)
    table.insert(unregistered, { eventId = eventId, callback = callback })
end
ClearNames = { Settings = { uiFontMode = "readable" } }

dofile("UIFonts.lua")

assert(ClearNames.UIFonts.Resolve("font_default_text", "readable") == "font_clear_medium_bold")
assert(ClearNames.UIFonts.Resolve("font_heading_unitframe_large_name", "large") == "font_clear_large_bold")
assert(ClearNames.UIFonts.Resolve("third_party_custom_font", "readable") == "third_party_custom_font")

-- 0.2.1 safety boundary: remapping is opt-in by proven-safe window identity,
-- never merely because a fixed-size HUD happens to use a stock font resource.
assert(ClearNames.UIFonts.ShouldRemapWindow("CustomHPDisplayValue") == false)
assert(ClearNames.UIFonts.ShouldRemapWindow("PlayerWindowPlayerName") == false)
assert(ClearNames.UIFonts.ShouldRemapWindow("GroupWindowPlayer1Name") == false)
assert(ClearNames.UIFonts.ShouldRemapWindow("ChatWindowContextFontMenuItem1Label") == true)
assert(ClearNames.UIFonts.ShouldRemapWindow("EA_ChatDockingWindowLabel") == true)
assert(ClearNames.UIFonts.ShouldRemapWindow("TargetWindowName") == true)

assert(ClearNames.UIFonts.SetMode("readable") == true)
assert(#registered == 3)
local wrapper = LabelSetFont
assert(wrapper == ClearNames.UIFonts.WrappedLabelSetFont)
assert(ClearNames.UIFonts.InstallHook() == true)
assert(LabelSetFont == wrapper)
assert(ClearNames.UIFonts.RegisterRefreshEvents() == true)
assert(#registered == 3)

ClearNames.UIFonts.mappedCalls = 0

LabelSetFont("CustomHPDisplayValue", "font_default_text", 4)
assert(calls[#calls].font == "font_default_text")
assert(calls[#calls].spacing == 4)

LabelSetFont("PlayerWindowPlayerName", "font_heading_unitframe_large_name", 4)
assert(calls[#calls].font == "font_heading_unitframe_large_name")

LabelSetFont("GroupWindowPlayer1Name", "font_heading_unitframe_large_name", 4)
assert(calls[#calls].font == "font_heading_unitframe_large_name")
assert(ClearNames.UIFonts.mappedCalls == 0)

LabelSetFont("ChatWindowContextFontMenuItem1Label", "font_default_text", 4)
assert(calls[#calls].font == "font_clear_medium_bold")
assert(ClearNames.UIFonts.mappedCalls == 1)

LabelSetFont("TargetWindowName", "font_heading_unitframe_large_name", 4)
assert(calls[#calls].font == "font_clear_medium_bold")
assert(ClearNames.UIFonts.mappedCalls == 2)

local beforeRefresh = #calls
ClearNames.UIFonts.RefreshKnown()
assert(#calls > beforeRefresh)
for i = beforeRefresh + 1, #calls do
    assert(calls[i].window ~= "PlayerWindowPlayerName")
    assert(calls[i].window ~= "GroupWindowPlayer1Name")
end

assert(ClearNames.UIFonts.SetMode("off") == true)
assert(LabelSetFont == originalLabelSetFont)
assert(#unregistered == 3)
LabelSetFont("PassThrough", "font_default_text", 5)
assert(calls[#calls].font == "font_default_text")

assert(ClearNames.UIFonts.SetMode("readable") == true)
assert(#registered == 6)

local callsBeforeRefreshEvent = #calls
ClearNames.UIFonts.OnUiRefreshEvent()
assert(#calls > callsBeforeRefreshEvent)

local doesWindowExist = DoesWindowExist
DoesWindowExist = nil
local callsBeforeMissingWindowApi = #calls
assert(ClearNames.UIFonts.RefreshKnown() == 0)
assert(#calls == callsBeforeMissingWindowApi)
DoesWindowExist = doesWindowExist

local modeBeforeInvalid = ClearNames.Settings.uiFontMode
assert(ClearNames.UIFonts.SetMode("banana") == false)
assert(ClearNames.Settings.uiFontMode == modeBeforeInvalid)

ClearNames.UIFonts.RemoveHook()
assert(#unregistered == 6)
assert(LabelSetFont == originalLabelSetFont)
assert(ClearNames.UIFonts.delegate == nil)

assert(ClearNames.UIFonts.SetMode("readable") == true)
assert(#registered == 9)
local clearNamesWrapper = LabelSetFont
local function thirdPartyHook(windowName, fontName, lineSpacing)
    return clearNamesWrapper(windowName, fontName, lineSpacing)
end
LabelSetFont = thirdPartyHook
ClearNames.UIFonts.RemoveHook()
assert(#unregistered == 9)
assert(LabelSetFont == thirdPartyHook)

local before = #calls
LabelSetFont("AfterThirdParty", "font_default_text", 6)
assert(#calls == before + 1)
assert(calls[#calls].font == "font_default_text")

print("uifonts-runtime-ok")
