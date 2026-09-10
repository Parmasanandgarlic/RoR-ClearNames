ClearNames = ClearNames or {}
ClearNames.Fonts = ClearNames.Fonts or {}

ClearNames.Fonts.Catalog = {
    { name="font_name_plate_names",       face="MyriadPro-Bold",    height=26, texsize=512, outline=true,  bold=true,  family="native" },
    { name="font_name_plate_names_old",   face="AgeOfReckoning",    height=20, texsize=512, outline=true,  bold=false, family="native" },
    { name="font_clear_medium_bold",      face="MyriadPro-Bold",    height=20, texsize=256, outline=true,  bold=true,  family="clear" },
    { name="font_clear_large_bold",       face="MyriadPro-Bold",    height=24, texsize=256, outline=true,  bold=true,  family="clear" },
    { name="font_alert_outline_medium",   face="CaslonAntiqueVL",   height=30, texsize=256, outline=true,  bold=false, family="alert" },
    { name="font_alert_outline_large",    face="CaslonAntiqueVL",   height=36, texsize=256, outline=true,  bold=false, family="alert" },
    { name="font_alert_outline_huge",     face="CaslonAntiqueVL",   height=42, texsize=256, outline=true,  bold=false, family="alert" },
    { name="font_alert_outline_giant",    face="CaslonAntiqueVL",   height=48, texsize=256, outline=true,  bold=false, family="alert" },
    { name="font_alert_outline_gigantic", face="CaslonAntiqueVL",   height=60, texsize=256, outline=true,  bold=false, family="alert" },
    { name="font_default_text_huge",      face="AgeOfReckoning",    height=30, texsize=512, outline=true,  bold=false, family="war" },
    { name="font_default_text_giant",     face="AgeOfReckoning",    height=48, texsize=256, outline=true,  bold=false, family="war" },
    { name="font_heading_medium",         face="CaslonAntiqueVL",   height=40, texsize=256, outline=false, bold=false, family="heading" },
    { name="font_heading_large",          face="CaslonAntiqueVL",   height=48, texsize=256, outline=false, bold=false, family="heading" },
    { name="font_heading_huge",           face="CaslonAntiqueVL",   height=72, texsize=512, outline=false, bold=false, family="heading" },
}

function ClearNames.Fonts.Get(name)
    local i, f
    for i, f in ipairs(ClearNames.Fonts.Catalog) do
        if f.name == name then return f, i end
    end
    return nil, nil
end

function ClearNames.Fonts.Next(name)
    local _, i = ClearNames.Fonts.Get(name)
    if not i then return ClearNames.Fonts.Catalog[1] end
    i = i + 1
    if i > #ClearNames.Fonts.Catalog then i = 1 end
    return ClearNames.Fonts.Catalog[i]
end

function ClearNames.Fonts.Previous(name)
    local _, i = ClearNames.Fonts.Get(name)
    if not i then return ClearNames.Fonts.Catalog[1] end
    i = i - 1
    if i < 1 then i = #ClearNames.Fonts.Catalog end
    return ClearNames.Fonts.Catalog[i]
end

function ClearNames.Fonts.StructuralScore(font)
    if not font then return 0 end
    local score = math.min(font.height or 0, 60) / 10
    if font.texsize and font.texsize >= 512 then score = score + 1.5 end
    if font.outline then score = score + 2 end
    if font.bold then score = score + 2 end
    if font.face == "MyriadPro-Bold" then score = score + 1.5 end
    return score
end

function ClearNames.Fonts.BestStructural()
    local best, bestScore = nil, -1
    local _, f, s
    for _, f in ipairs(ClearNames.Fonts.Catalog) do
        s = ClearNames.Fonts.StructuralScore(f)
        if s > bestScore then best, bestScore = f, s end
    end
    return best, bestScore
end
