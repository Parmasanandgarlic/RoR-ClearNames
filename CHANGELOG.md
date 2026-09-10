# Changelog

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
