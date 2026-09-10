# ClearNames 0.1.0

ClearNames is a readability-first overhead-name addon for **Return of Reckoning**. It keeps the game's native world-name renderer as the reliable path, adds a curated font laboratory, visibility profiles, persistent distance ratings, diagnostics, and a guarded experimental HD-label path for world objects whose `worldObjNum` is explicitly known.

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
- `/clearnames hd on|off` — enable/disable the **experimental** HD-label subsystem.

## Font lab

Use the left/right controls to cycle name and title fonts independently. For the current **name** font, click the Near / Mid / Far / Extreme buttons to cycle each rating from 1 through 5. Ratings persist in `ClearNames.FontScores`. The lab reports the best measured candidate; before you have measurements it falls back to a structural readability score based on glyph height, outline, texture atlas size, weight, and face.

Recommended practical test: choose a fixed NPC group, remain at the same camera zoom, and rate every candidate at approximately the same four distance bands. This makes your personal ranking much more meaningful than a generic hard-coded preference.

## Engine boundary

`SetNamesAndTitlesFont()` changes the engine-owned world name/title font globally. WAR/RoR does not expose a general addon iterator for every visible world object's `worldObjNum`, so ClearNames deliberately does **not** claim it can replace every ambient nameplate with a custom UI object.

The experimental renderer uses `AttachWindowToWorldObject()` only when an explicit `worldObjNum` is supplied. It is disabled by default, refuses invalid object numbers, and tears down attached windows when disabled or the addon shuts down. It should be treated as an integration surface for known targets/party/warband objects, not as a universal nameplate replacement.

## Recovery

If a font/profile looks wrong, run `/clearnames restore`. If slash commands are unavailable, execute `/script ClearNames.Restore()` and then disable the addon. ClearNames intentionally has no manifest-level `OnUpdate` loop, so the native optimizer adds no permanent frame polling burden.
