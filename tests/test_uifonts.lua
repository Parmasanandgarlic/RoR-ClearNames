local calls = {}

local function originalLabelSetFont(windowName, fontName, lineSpacing)
    table.insert(calls, { window = windowName, font = fontName, spacing = lineSpacing })
    return true
end

LabelSetFont = originalLabelSetFont
DoesWindowExist = function(windowName)
    return windowName == "TargetWindowName" or windowName == "GroupWindowPlayer1Name"
end
WindowUtils = { FONT_DEFAULT_TEXT_LINESPACING = 7 }
ClearNames = { Settings = { uiFontMode = "readable" } }

dofile("UIFonts.lua")

assert(ClearNames.UIFonts.Resolve("font_default_text", "readable") == "font_clear_medium_bold")
assert(ClearNames.UIFonts.Resolve("font_heading_unitframe_large_name", "large") == "font_clear_large_bold")
assert(ClearNames.UIFonts.Resolve("third_party_custom_font", "readable") == "third_party_custom_font")

assert(ClearNames.UIFonts.InstallHook() == true)
local wrapper = LabelSetFont
assert(wrapper == ClearNames.UIFonts.WrappedLabelSetFont)
assert(ClearNames.UIFonts.InstallHook() == true)
assert(LabelSetFont == wrapper)

LabelSetFont("DynamicLabel", "font_default_text", 4)
assert(calls[#calls].font == "font_clear_medium_bold")
assert(calls[#calls].spacing == 4)
assert(ClearNames.UIFonts.mappedCalls == 1)

assert(ClearNames.UIFonts.SetMode("off") == true)
LabelSetFont("PassThrough", "font_default_text", 5)
assert(calls[#calls].font == "font_default_text")

assert(ClearNames.UIFonts.SetMode("readable") == true)
local foundTarget = false
local foundGroup = false
for _, call in ipairs(calls) do
    if call.window == "TargetWindowName" and call.font == "font_clear_medium_bold" then foundTarget = true end
    if call.window == "GroupWindowPlayer1Name" and call.font == "font_clear_medium_bold" then foundGroup = true end
end
assert(foundTarget == true)
assert(foundGroup == true)

local modeBeforeInvalid = ClearNames.Settings.uiFontMode
assert(ClearNames.UIFonts.SetMode("banana") == false)
assert(ClearNames.Settings.uiFontMode == modeBeforeInvalid)

ClearNames.UIFonts.RemoveHook()
assert(LabelSetFont == originalLabelSetFont)
assert(ClearNames.UIFonts.delegate == nil)

assert(ClearNames.UIFonts.SetMode("readable") == true)
local clearNamesWrapper = LabelSetFont
local function thirdPartyHook(windowName, fontName, lineSpacing)
    return clearNamesWrapper(windowName, fontName, lineSpacing)
end
LabelSetFont = thirdPartyHook
ClearNames.UIFonts.RemoveHook()
assert(LabelSetFont == thirdPartyHook)

local before = #calls
LabelSetFont("AfterThirdParty", "font_default_text", 6)
assert(#calls == before + 1)
assert(calls[#calls].font == "font_default_text")

print("uifonts-runtime-ok")
