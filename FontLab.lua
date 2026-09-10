ClearNames = ClearNames or {}
ClearNames.FontLab = ClearNames.FontLab or {}
ClearNames.FontLab.Buckets = { "near", "mid", "far", "extreme" }
ClearNames.FontLab.slotA = "font_clear_large_bold"
ClearNames.FontLab.slotB = "font_alert_outline_large"
ClearNames.FontLab.activeSlot = "A"

local function ensureScores()
    ClearNames.FontScores = ClearNames.FontScores or {}
    return ClearNames.FontScores
end

function ClearNames.FontLab.SetSlots(a, b)
    if ClearNames.Fonts.Get(a) then ClearNames.FontLab.slotA = a end
    if ClearNames.Fonts.Get(b) then ClearNames.FontLab.slotB = b end
end

function ClearNames.FontLab.Swap()
    ClearNames.FontLab.slotA, ClearNames.FontLab.slotB = ClearNames.FontLab.slotB, ClearNames.FontLab.slotA
    return ClearNames.FontLab.slotA, ClearNames.FontLab.slotB
end

function ClearNames.FontLab.Activate(slot)
    if slot ~= "A" and slot ~= "B" then return false end
    ClearNames.FontLab.activeSlot = slot
    local font = slot == "A" and ClearNames.FontLab.slotA or ClearNames.FontLab.slotB
    local title = ClearNames.Settings and ClearNames.Settings.titleFont or "font_clear_medium_bold"
    return ClearNames.NativeRenderer.ApplyFonts(font, title)
end

function ClearNames.FontLab.Rate(fontName, bucket, stars)
    if not ClearNames.Fonts.Get(fontName) then return false end
    local valid = false
    local _, b
    for _, b in ipairs(ClearNames.FontLab.Buckets) do if b == bucket then valid = true end end
    if not valid or type(stars) ~= "number" or stars < 1 or stars > 5 then return false end
    local scores = ensureScores()
    scores[fontName] = scores[fontName] or {}
    scores[fontName][bucket] = stars
    return true
end

function ClearNames.FontLab.Aggregate(fontName)
    local entry = ensureScores()[fontName]
    if not entry then return nil end
    local total, count = 0, 0
    local _, bucket
    for _, bucket in ipairs(ClearNames.FontLab.Buckets) do
        if entry[bucket] then total, count = total + entry[bucket], count + 1 end
    end
    if count == 0 then return nil end
    return total / count
end

function ClearNames.FontLab.Recommend()
    local best, bestScore = nil, -1
    local name, _
    for name, _ in pairs(ensureScores()) do
        local score = ClearNames.FontLab.Aggregate(name)
        if score and score > bestScore then best, bestScore = name, score end
    end
    if best then return best, bestScore end
    local font, structural = ClearNames.Fonts.BestStructural()
    return font and font.name or nil, structural
end
