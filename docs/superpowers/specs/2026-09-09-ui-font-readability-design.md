# ClearNames UI Font Readability Design

## Goal

Extend ClearNames 0.1.1 into 0.2.0 so ordinary Return of Reckoning UI text can be made more resilient to ReShade/post-processing while preserving all existing world-name and HD NPC-label behavior.

## Architecture

Add a dedicated `UIFonts.lua` subsystem. It owns a reversible wrapper around the global `LabelSetFont` API, maps only a conservative allowlist of known low-readability stock fonts to outlined/bold built-in alternatives, and exposes three modes: `off`, `readable`, and `large`. Unknown fonts always pass through unchanged.

The wrapper must chain to the `LabelSetFont` function that existed when ClearNames installed its hook. It must never recurse, double-wrap itself, or overwrite a later third-party hook on shutdown. If another addon replaces `LabelSetFont` after ClearNames, ClearNames leaves that later global function in place and disables its own remapping within any retained delegation chain.

Static XML labels that already exist before the wrapper is installed are refreshed through a small, explicit registry of high-value stock HUD labels. Initial coverage includes the player name/level, hostile target name, friendly target name, mouseover target name, and the five default group-member name labels. Missing windows are ignored. Late-created stock labels are refreshed sparsely on `LOADING_END`, `GROUP_UPDATED`, and `GROUP_PLAYER_ADDED`; no every-frame UI scan is permitted.

## Modes

- `off`: no font remapping. Restore the bounded stock HUD labels and remove ClearNames' global wrapper when ClearNames still owns it. If another addon replaced the global function after ClearNames, leave that function untouched and make any retained ClearNames delegation pass through unchanged.
- `readable`: prioritize MyriadPro bold/outlined stock resources at equal or slightly larger effective sizes. This is the recommended ReShade profile.
- `large`: use the same high-contrast family while stepping small/default text upward where a bounded stock equivalent exists; cap common body text at `font_clear_large_bold` to reduce clipping risk.

## Mapping policy

Only explicit stock resources are remapped. Decorative headings, map-special fonts, icon fonts, unknown third-party fonts, and arbitrary custom addon resources are untouched.

Readable mode maps these families conservatively:

- `font_clear_tiny` -> `font_clear_small_bold`
- `font_clear_small` -> `font_clear_small_bold`
- `font_clear_medium` -> `font_clear_medium_bold`
- `font_clear_large` -> `font_clear_large_bold`
- `font_default_text_small` -> `font_clear_medium_bold`
- `font_default_text` -> `font_clear_medium_bold`
- `font_default_text_no_outline` -> `font_clear_medium_bold`
- `font_default_text_large` -> `font_clear_medium_bold`
- `font_chat_text` -> `font_clear_medium_bold`
- `font_chat_text_no_outline` -> `font_clear_medium_bold`
- `font_chat_text_bold` -> `font_clear_medium_bold`
- `font_heading_target_mouseover_name` -> `font_clear_medium_bold`
- `font_heading_unitframe_large_name` -> `font_clear_medium_bold`
- `font_heading_rank` -> `font_clear_medium_bold`

Large mode uses the same allowlist but promotes tiny/small/default body text to `font_clear_medium_bold` and medium/large body text to `font_clear_large_bold`; target/player name resources map to `font_clear_large_bold`.

## Runtime behavior

`ClearNames.UIFonts.SetMode(mode)` validates the mode and persists it to `ClearNames.Settings.uiFontMode`. Readable/large modes install the hook, register sparse refresh events, and refresh known static labels. Off mode first restores known labels, unregisters refresh events, and removes ClearNames' global wrapper when safe. Invalid modes return `false` and do not mutate state.

`ClearNames.UIFonts.Resolve(fontName, mode)` is pure: it returns the mapped font or the original input.

`ClearNames.UIFonts.InstallHook()` records the current `LabelSetFont` as its delegate exactly once for that installation cycle, then assigns `LabelSetFont = ClearNames.UIFonts.WrappedLabelSetFont`. Repeated calls are idempotent. If a retained delegate indicates another addon replaced ClearNames after installation, ClearNames does not seize the global back.

`ClearNames.UIFonts.RemoveHook()` unregisters sparse refresh events and disables remapping. It restores the recorded delegate only if the current global function is still ClearNames' wrapper. If another addon has replaced the global, ClearNames leaves it untouched and retains the delegate required for a downstream wrapper chain to remain callable in pass-through mode.

`ClearNames.UIFonts.RefreshKnown()` applies the active mode to known stock label names only when `DoesWindowExist` is available and reports them present. It does not enumerate arbitrary windows or install polling.

## Integration

Default `uiFontMode` is `readable` for new installs. Existing saved settings without the field receive that default.

Commands:

- `/clearnames ui off`
- `/clearnames ui readable`
- `/clearnames ui large`

`/clearnames doctor` reports UI font mode, hook state, and mapped-call count.

`ClearNames.OnInitialize()` installs/applies the saved UI font mode after defaults are loaded. `ClearNames.OnShutdown()` removes the UI-font hook after tearing down HD labels.

## Safety constraints

- Preserve all 0.1.1 overhead-name, profile, font-lab, and HD NPC-label features.
- Do not redefine core font assets.
- Do not globally change interface scale.
- Do not add a manifest-level or permanent `OnUpdate` loop.
- Unknown/custom fonts pass through unchanged.
- Never restore over a later third-party `LabelSetFont` hook.
- Missing stock windows are ignored without error.
- Late-created stock UI refresh is limited to sparse, explicit RoR events.
- No dependency on ReShade itself.

## Verification

Regression tests must prove manifest integrity, version synchronization, existing HD-label invariants, presence of the three UI modes, explicit allowlist mapping, pass-through behavior for unknown fonts, reversible/idempotent hook structure, third-party-hook-safe removal, bounded static refresh targets, sparse refresh-event registration/teardown, no UI polling loop, command integration, persisted default, and doctor diagnostics. An executable Lua harness must exercise activation, remapping, `off`, static refresh, event registration, invalid-mode rejection, normal teardown, and later third-party wrapping.
