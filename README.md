# ClearNames 0.2.0

ClearNames is a readability-first addon for **Return of Reckoning**. It now addresses three separate text paths: the game's native world-name renderer, optional constant-screen-scale HD labels for NPCs exposed through target/mouseover state, and ordinary 2D UI fonts that can become hard to read under ReShade/post-processing.

The addon keeps RoR's native renderer as the universal fallback. It does not replace the whole UI, redefine core font assets, change global UI scale, or claim to bypass ReShade's rendering pipeline.

## Install

1. Close the game.
2. Copy the **ClearNames** folder to your WAR installation under `Interface\AddOns\ClearNames`.
3. Start Return of Reckoning and enable **ClearNames** in the addon manager if required.
4. `LibSlash` is optional. If installed, use `/clearnames` or `/cn`. Without LibSlash, the addon still applies its saved/default settings at startup; the font-lab UI can be opened from `/script ClearNames.ToggleWindow()`.

## Primary commands

- `/clearnames lab` — open/close the font laboratory.
- `/clearnames doctor` — report engine API availability, UI-font hook state, active UI mode, and mapped-call count.
- `/clearnames restore` — restore the name/title visibility settings captured before ClearNames first changed them this session.
- `/clearnames profile Maximum Readability`
- `/clearnames profile PvE`
- `/clearnames profile RvR`
- `/clearnames profile Immersive`
- `/clearnames profile Screenshot`
- `/clearnames font font_alert_outline_large` — set an exact native overhead-name font.
- `/clearnames hd on|off` — enable/disable constant-scale HD NPC labels for current hostile/friendly/mouseover targets. The setting persists.
- `/clearnames ui off|readable|large` — control 2D UI font hardening. The setting persists.

## ReShade / UI font readability

New installs default to:

```text
/clearnames ui readable
```

`readable` is the recommended ReShade-friendly mode. It prioritizes RoR's built-in **MyriadPro bold, outlined** clear-font resources for an explicit allowlist of common thin/small stock UI fonts. The goal is to improve glyph weight and edge definition without scaling the whole interface or indiscriminately enlarging every label.

Examples of stock resources remapped in `readable` mode include `font_default_text`, `font_default_text_small`, `font_clear_small`, `font_clear_medium`, `font_chat_text`, `font_heading_unitframe_large_name`, and `font_heading_target_mouseover_name`. Unknown fonts and arbitrary third-party/custom resources pass through unchanged.

`large` uses the same conservative allowlist but promotes more body/name text to `font_clear_large_bold`. It is intentionally more aggressive and may clip in unusually tight custom layouts, so start with `readable`.

ClearNames installs a reversible wrapper around RoR's `LabelSetFont()` API. It chains to whatever setter existed when ClearNames initialized, avoids wrapping itself twice, and does not overwrite a later third-party hook when shutting down. `/clearnames ui off` restores the bounded stock HUD labels ClearNames owns and removes its global wrapper when ClearNames still owns that wrapper.

Some important HUD text is assigned directly by XML before ClearNames can observe a `LabelSetFont()` call. ClearNames therefore performs a bounded refresh for known stock labels: player name/level, hostile target name, friendly target name, mouseover target name, and the five default party-member names. It refreshes these sparsely on initialization and on RoR `LOADING_END`, `GROUP_UPDATED`, and `GROUP_PLAYER_ADDED` events so party frames created later are also covered. There is no UI polling loop.

This improves the source typography that ReShade ultimately processes; it is **not** a replacement for UIMask/UI-filter shaders. The strongest setup is to use a shader-side UI exclusion where it works and let ClearNames make any remaining processed text intrinsically heavier and more legible.

## Font lab

Use the left/right controls to cycle overhead name and title fonts independently. For the current **name** font, click the Near / Mid / Far / Extreme buttons to cycle each rating from 1 through 5. Ratings persist in `ClearNames.FontScores`. The lab reports the best measured candidate; before you have measurements it falls back to a structural readability score based on glyph height, outline, texture atlas size, weight, and face.

Recommended practical test: choose a fixed NPC group, remain at the same camera zoom, and rate every candidate at approximately the same four distance bands. This makes your personal ranking more meaningful than a generic hard-coded preference.

## Distance-locked NPC labels

RoR's stock `SetNamesAndTitlesFont()` renderer is owned by the game engine. It applies one name font globally and the engine decides how the stock world text scales with distance. Addons do not receive a general iterator over every ambient NPC in the scene, so ClearNames cannot truthfully replace every stock nameplate with a custom constant-size label.

When **HD labels** are enabled, ClearNames listens to RoR's normal `PLAYER_TARGET_UPDATED` flow for `selfhostiletarget`, `selffriendlytarget`, and `mouseovertarget`. It waits one frame so the stock `TargetInfo` subsystem can publish the target state first, then reads `UnitIsNPC`, `UnitEntityId`, and `UnitName` without calling the consumptive `GetUpdatedTargets()` API itself.

For a valid NPC world object, ClearNames attaches its own label using `AttachWindowToWorldObject()` and explicitly keeps the UI window at scale `1.0`. It deliberately does **not** call `MoveWindowToWorldObject()`, which is the engine path associated with scaled attachment. The result is a fixed-screen-scale label for NPCs whose live world-object ID is exposed through target/mouseover state, while ordinary ambient names continue using the native renderer.

If the target stops being a valid NPC, changes object ID, or HD mode is disabled, the associated label is released. Duplicate target slots pointing at the same NPC share one label, and all attached windows are torn down on addon shutdown.

HD mode remains opt-in because RoR does not expose enough information for a universal ambient-name replacement and the stock ambient label can still coexist with the attached label. Enable it once with `/clearnames hd on`; the saved setting is then reused on later sessions.

## Engine boundary

ClearNames uses three complementary paths:

1. **Native world-name path:** reliable, universal ambient names using the selected built-in font through `SetNamesAndTitlesFont()`.
2. **HD target path:** fixed-screen-scale labels for live NPC world-object IDs available from target/mouseover state.
3. **2D UI-font path:** conservative `LabelSetFont()` remapping plus bounded stock-HUD refresh for UI text that is otherwise post-processed by ReShade.

RoR still owns native 3D name distance scaling, and ClearNames does not receive arbitrary target distance or a complete visible-NPC iterator. ReShade still owns its own post-processing pipeline.

## Recovery

- If the UI-font treatment is too strong, run `/clearnames ui readable` or `/clearnames ui off`.
- If an overhead font/profile looks wrong, run `/clearnames restore`.
- Use `/clearnames hd off` to immediately tear down all ClearNames HD labels.
- If slash commands are unavailable, `/script ClearNames.UIFonts.SetMode("off")` disables UI-font remapping and `/script ClearNames.Restore()` restores captured native-name settings.

ClearNames has no permanent manifest-level `OnUpdate` loop. HD mode registers a one-frame `OnUpdate` callback only after a relevant target event and unregisters it immediately after synchronization; UI-font refreshes use sparse game events instead of polling.
