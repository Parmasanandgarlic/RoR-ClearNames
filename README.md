# ClearNames 0.2.1

ClearNames is a readability-first addon for **Return of Reckoning**. It addresses three separate text paths: the game's native world-name renderer, optional constant-screen-scale HD labels for NPCs exposed through target/mouseover state, and selected 2D UI fonts that can become hard to read under ReShade/post-processing.

The addon keeps RoR's native renderer as the universal fallback. It does not replace the whole UI, redefine core font assets, change global UI scale, or claim to bypass ReShade's rendering pipeline.

## Install

1. Close the game.
2. Copy the **ClearNames** folder to your WAR installation under `Interface\AddOns\ClearNames`.
3. Start Return of Reckoning and enable **ClearNames** in the addon manager if required.
4. `LibSlash` is optional. If installed, use `/clearnames` or `/cn`. Without LibSlash, the addon still applies its saved/default settings at startup; the font-lab UI can be opened from `/script ClearNames.ToggleWindow()`.

## Primary commands

- `/clearnames lab` — open/close the font laboratory.
- `/clearnames doctor` — report engine API availability, UI-font hook state, active UI mode, mapped-call count, and HD-label state.
- `/clearnames restore` — restore the name/title visibility settings captured before ClearNames first changed them this session.
- `/clearnames profile Maximum Readability`
- `/clearnames profile PvE`
- `/clearnames profile RvR`
- `/clearnames profile Immersive`
- `/clearnames profile Screenshot`
- `/clearnames font font_alert_outline_large` — set an exact native overhead-name font.
- `/clearnames hd on|off` — enable/disable constant-scale HD NPC labels for current hostile/friendly/mouseover targets. The setting persists.
- `/clearnames ui off|readable|large` — control selected 2D UI font hardening. The setting persists.

## ReShade / UI font readability

New installs default to:

```text
/clearnames ui readable
```

`readable` is the recommended ReShade-friendly mode. It prioritizes RoR's built-in **MyriadPro bold, outlined** clear-font resources for a conservative font allowlist, but 0.2.1 now also requires the requesting UI window to be explicitly safe before remapping occurs.

This is intentionally narrower than 0.2.0. The global-by-font behavior in 0.2.0 could affect unrelated fixed-size HUD/addon labels that happened to use the same stock font resources. In 0.2.1, unknown/custom windows, the stock player HUD, and group-member frames pass through unchanged. The main dynamic coverage is chat-window UI plus the known target/mouseover name labels.

`large` uses the same safe window scope but promotes eligible text to larger bold resources. It is intentionally more aggressive; start with `readable`.

ClearNames still installs a reversible wrapper around RoR's `LabelSetFont()` API, but the wrapper now checks **both** the window identity and the font resource before remapping. Unknown/custom windows are forwarded untouched even when they use `font_default_text`, `font_clear_*`, or another otherwise eligible stock resource.

The bounded static refresh now covers only the hostile target name, friendly target name, and mouseover target name. It deliberately does not rewrite the stock `PlayerWindow` or group frames. Sparse RoR refresh events remain in use; there is no UI polling loop.

This improves source typography that ReShade ultimately processes; it is **not** a replacement for a shader-side UI/nametag exclusion.

## Why distant native nameplates can still look blurry

RoR's stock `SetNamesAndTitlesFont()` renderer is owned by the game engine. The addon API lets ClearNames choose the name/title font, but the client still controls the native world-name distance scaling/rasterization.

That means changing the font can improve legibility, but it cannot force every native ambient NPC nameplate to stay at a constant screen-space size or bypass blur introduced by ReShade/post-processing.

A top/bottom spatial UIMask also cannot reliably protect moving world-space nameplates in the center of the scene. If your ReShade setup provides a dedicated **nametag/UI filter**, use that for universal native-nameplate exclusion from effects such as depth of field, AA, bloom, sharpening, or other post-processing. ClearNames complements that shader-side fix; it does not replace it.

## Distance-locked NPC labels

HD labels are separate from the native name renderer and remain **opt-in**. Check their state with:

```text
/clearnames doctor
```

If it reports `HDLabels=OFF`, enable them with:

```text
/clearnames hd on
```

When HD labels are enabled, ClearNames listens to RoR's normal `PLAYER_TARGET_UPDATED` flow for `selfhostiletarget`, `selffriendlytarget`, and `mouseovertarget`. It waits one frame so the stock `TargetInfo` subsystem can publish target state first, then reads `UnitIsNPC`, `UnitEntityId`, and `UnitName` without consuming `GetUpdatedTargets()` itself.

For a valid NPC world object, ClearNames attaches its own UI label using `AttachWindowToWorldObject()` and explicitly keeps that window at scale `1.0`. It deliberately does **not** call `MoveWindowToWorldObject()`, the path associated with scaled attachment.

This gives fixed-screen-scale labels for NPCs whose live world-object IDs RoR exposes through target/mouseover state. It does **not** provide a complete iterator over every ambient NPC in the scene, so it cannot replace every native nameplate automatically.

If the target stops being a valid NPC, changes object ID, or HD mode is disabled, the associated label is released. Duplicate target slots pointing at the same NPC share one label, and all attached windows are torn down on addon shutdown.

## Font lab

Use the left/right controls to cycle overhead name and title fonts independently. For the current **name** font, click Near / Mid / Far / Extreme to rate each candidate from 1 through 5. Ratings persist in `ClearNames.FontScores`.

Recommended practical test: choose a fixed NPC group, keep the same camera zoom, and compare fonts at approximately the same distance bands. This helps identify the strongest native fallback even though the engine still owns distance scaling.

## Engine boundary

ClearNames uses three complementary paths:

1. **Native world-name path:** universal ambient names using the selected built-in font through `SetNamesAndTitlesFont()`.
2. **HD target path:** fixed-screen-scale labels for NPC world-object IDs available from target/mouseover state.
3. **2D UI-font path:** window-scoped `LabelSetFont()` remapping for selected safe UI surfaces.

RoR still owns native world-name distance scaling, and ClearNames does not receive arbitrary target distance or a complete visible-NPC iterator. ReShade still owns its own post-processing pipeline.

## Recovery

- If any UI treatment looks wrong, run `/clearnames ui off`.
- If an overhead font/profile looks wrong, run `/clearnames restore`.
- Use `/clearnames hd off` to immediately tear down all ClearNames HD labels.
- If slash commands are unavailable, `/script ClearNames.UIFonts.SetMode("off")` disables UI-font remapping and `/script ClearNames.Restore()` restores captured native-name settings.

ClearNames has no permanent manifest-level `OnUpdate` loop. HD mode registers a one-frame `OnUpdate` callback only after a relevant target event and unregisters it immediately after synchronization; UI-font refreshes use sparse game events instead of polling.
