# ClearNames 0.1.1

ClearNames is a readability-first overhead-name addon for **Return of Reckoning**. It keeps the game's native world-name renderer as the universal fallback, adds a curated font laboratory, visibility profiles, persistent distance ratings, diagnostics, and an optional constant-screen-scale HD label path for NPCs exposed by RoR as your hostile target, friendly target, or mouseover target.

## Install

1. Close the game.
2. Copy the **ClearNames** folder to your WAR installation under `Interface\AddOns\ClearNames`.
3. Start Return of Reckoning and enable **ClearNames** in the addon manager if required.
4. `LibSlash` is optional. If installed, use `/clearnames` or `/cn`. Without LibSlash, the addon still applies its saved/default font and profile at startup; the UI can be opened from `/script ClearNames.ToggleWindow()`.

## Primary commands

- `/clearnames lab` — open/close the font laboratory.
- `/clearnames doctor` — report engine API availability and current state.
- `/clearnames restore` — restore the name/title visibility settings captured before ClearNames first changed them this session.
- `/clearnames profile Maximum Readability`
- `/clearnames profile PvE`
- `/clearnames profile RvR`
- `/clearnames profile Immersive`
- `/clearnames profile Screenshot`
- `/clearnames font font_alert_outline_large` — set an exact native name font.
- `/clearnames hd on|off` — enable/disable constant-scale HD NPC labels for current hostile/friendly/mouseover targets. The setting persists.

## Font lab

Use the left/right controls to cycle name and title fonts independently. For the current **name** font, click the Near / Mid / Far / Extreme buttons to cycle each rating from 1 through 5. Ratings persist in `ClearNames.FontScores`. The lab reports the best measured candidate; before you have measurements it falls back to a structural readability score based on glyph height, outline, texture atlas size, weight, and face.

Recommended practical test: choose a fixed NPC group, remain at the same camera zoom, and rate every candidate at approximately the same four distance bands. This makes your personal ranking much more meaningful than a generic hard-coded preference.

## Distance-locked NPC labels

RoR's stock `SetNamesAndTitlesFont()` renderer is owned by the game engine. It applies one name font globally and the engine decides how the stock world text scales with distance. Addons do not receive a general iterator over every ambient NPC in the scene, so ClearNames cannot truthfully replace every stock nameplate with a custom constant-size label.

When **HD labels** are enabled, ClearNames listens to RoR's normal `PLAYER_TARGET_UPDATED` flow for `selfhostiletarget`, `selffriendlytarget`, and `mouseovertarget`. It waits one frame so the stock `TargetInfo` subsystem can publish the target state first, then reads `UnitIsNPC`, `UnitEntityId`, and `UnitName` without calling the consumptive `GetUpdatedTargets()` API itself.

For a valid NPC world object, ClearNames attaches its own label using `AttachWindowToWorldObject()` and explicitly keeps the UI window at scale `1.0`. It deliberately does **not** call `MoveWindowToWorldObject()`, which is the engine path associated with scaled attachment. The result is a fixed-screen-scale label for NPCs whose live world-object ID is exposed through target/mouseover state, while ordinary ambient names continue using the native renderer.

If the target stops being a valid NPC, changes object ID, or HD mode is disabled, the associated label is released. Duplicate target slots pointing at the same NPC share one label, and all attached windows are torn down on addon shutdown.

HD mode remains opt-in because RoR does not expose enough information for a universal ambient-name replacement and the stock ambient label can still coexist with the attached label. Enable it once with `/clearnames hd on`; the saved setting is then reused on later sessions.

## Engine boundary

`SetNamesAndTitlesFont()` changes the engine-owned world name/title font globally. RoR exposes only the global name/title font choice and visibility toggles for the native 3D-world renderer; it does not expose independent per-NPC font selection or arbitrary target distance to addons.

ClearNames therefore uses two complementary paths:

1. **Native path:** reliable, universal ambient names using the selected built-in font.
2. **HD target path:** fixed-screen-scale labels for live NPC world-object IDs available from target/mouseover state.

If `TargetInfo`, world-object attachment, or required window APIs are unavailable, the HD path fails closed and the native names remain untouched.

## Recovery

If a font/profile looks wrong, run `/clearnames restore`. If slash commands are unavailable, execute `/script ClearNames.Restore()` and then disable the addon. Use `/clearnames hd off` to immediately tear down all ClearNames HD labels.

ClearNames has no permanent manifest-level `OnUpdate` loop. HD mode registers a one-frame `OnUpdate` callback only after a relevant target event, then unregisters it immediately after synchronization.
