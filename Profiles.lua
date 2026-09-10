ClearNames = ClearNames or {}
ClearNames.Profiles = ClearNames.Profiles or {}

ClearNames.Profiles.Definitions = {
    ["Maximum Readability"] = {
        friendlyplayers=true, enemyplayers=true, friendlynpcs=true, enemynpcs=true,
        friendlytitles=false, enemytitles=false, npctitles=false,
        friendlyguilds=false, enemyguilds=false, yourguild=false, targetguild=false,
    },
    ["PvE"] = {
        friendlyplayers=false, enemyplayers=true, friendlynpcs=true, enemynpcs=true,
        friendlytitles=false, enemytitles=false, npctitles=true,
        friendlyguilds=false, enemyguilds=false,
    },
    ["RvR"] = {
        friendlyplayers=true, enemyplayers=true, friendlynpcs=false, enemynpcs=false,
        friendlytitles=false, enemytitles=false, npctitles=false,
        friendlyguilds=false, enemyguilds=false,
    },
    ["Immersive"] = {
        friendlyplayers=true, enemyplayers=true, friendlynpcs=true, enemynpcs=true,
        friendlytitles=true, enemytitles=true, npctitles=true,
        friendlyguilds=true, enemyguilds=true,
    },
    ["Screenshot"] = {
        friendlyplayers=true, enemyplayers=true, friendlynpcs=true, enemynpcs=true,
        friendlytitles=true, enemytitles=true, npctitles=true,
        friendlyguilds=true, enemyguilds=true,
    },
}

function ClearNames.Profiles.Apply(name)
    local profile = ClearNames.Profiles.Definitions[name]
    if not profile then return false end
    ClearNames.NativeRenderer.CaptureOriginal()
    ClearNames.NativeRenderer.ApplyVisibility(profile)
    if ClearNames.Settings then ClearNames.Settings.profile = name end
    return true
end
