# Changelog

## 0.2.1 — 2026-09-09

- Fixed the 0.2.0 UI-font mapper so it no longer remaps any window merely because that window uses a known stock font resource.
- Added explicit safe-window scoping: chat UI plus known target/mouseover name labels remain eligible for readability remapping; unknown/custom HUD windows pass through unchanged.
- Removed stock `PlayerWindow` and group-member labels from the bounded static refresh path to avoid destabilizing fixed-size HP/player/group HUD layouts.
- Preserved the existing reversible/idempotent `LabelSetFont()` hook and later-third-party-hook safety behavior.
- Added regression coverage proving custom HP displays, stock player HUD labels, and group labels are not remapped, while chat and target-name surfaces still are.
- Expanded `/clearnames doctor` to report `HDLabels=ON|OFF` and clarify that the fixed-scale path covers target/mouseover NPCs only.
- Clarified that native ambient nameplate blur/distance scaling is engine/ReShade controlled and requires a shader-side nametag/UI exclusion for universal protection.

## 0.2.0 — 2026-09-09

- Added a dedicated `UIFonts.lua` subsystem for ordinary 2D Return of Reckoning UI text.
- Added persistent `/clearnames ui off|readable|large` modes, with `readable` as the default ReShade-friendly profile.
- Added conservative allowlist remapping from thin/small stock fonts to built-in MyriadPro bold/outlined clear-font resources; unknown and third-party custom fonts pass through unchanged.
- Added a reversible, idempotent `LabelSetFont()` wrapper that preserves the pre-existing setter and will not overwrite a later third-party hook during teardown.
- `/clearnames ui off` restores the bounded stock HUD labels and removes ClearNames' wrapper when ClearNames still owns the global function.
- Added bounded static refresh coverage for player name/level, hostile/friendly target names, mouseover name, and the five default group-member names.
- Added sparse `LOADING_END`, `GROUP_UPDATED`, and `GROUP_PLAYER_ADDED` refresh events so UI frames created after initialization are covered without polling.
- Expanded `/clearnames doctor` with UI-font mode, hook state, and mapped-call diagnostics.
- Added executable `texlua` regression coverage for mode mapping, unknown-font pass-through, hook idempotence, teardown, late third-party wrapping, static refresh, and sparse event registration.
- Preserved all 0.1.1 native overhead-name and fixed-scale target/mouseover NPC-label behavior.

## 0.1.1 — 2026-09-09

- Fixed the addon manifest so every declared Lua/XML file resolves to the files actually shipped in the repository.
- Added the stock `EASystem_TargetInfo` dependency required by automatic NPC target synchronization.
- Wired hostile target, friendly target, and mouseover target events into the HD-label subsystem.
- Deferred HD synchronization by one frame on the always-live `Root` window so stock `TargetInfo` publishes state before ClearNames reads it.
- HD labels now identify NPCs through `UnitIsNPC`, `UnitEntityId`, and `UnitName` without consuming `GetUpdatedTargets()`.
- Attached NPC labels explicitly remain at UI scale `1.0` and avoid `MoveWindowToWorldObject()` distance scaling.
- Added shared-object tracking so multiple target slots referencing the same NPC do not create duplicate ClearNames HD windows.
- Added fail-closed attachment/cleanup behavior for invalid or stale target state.
- Added a regression verifier covering manifest integrity, TargetInfo contracts, one-frame scheduling, fixed-scale attachment, event registration, and release version consistency.

## 0.1.0 — 2026-09-09

- Curated native overhead-font catalog with metadata and structural scoring.
- Independent name/title font cycling.
- Maximum Readability, PvE, RvR, Immersive, and Screenshot profiles.
- Original settings capture and restore path.
- Four-distance font lab ratings with persistent recommendation logic.
- `/clearnames doctor`, `lab`, `restore`, `profile`, `font`, `hd`, and `help` commands.
- Optional LibSlash integration and no mandatory external runtime dependency.
- Experimental, disabled-by-default world-object HD label attachment subsystem.
- No manifest `OnUpdate` loop.
