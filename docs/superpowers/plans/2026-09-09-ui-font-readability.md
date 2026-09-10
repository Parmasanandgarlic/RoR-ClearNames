# ClearNames UI Font Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reversible, conservative system-wide UI font readability layer to ClearNames 0.2.0 without regressing the existing overhead-name and HD NPC-label functionality.

**Architecture:** Create `UIFonts.lua` as an isolated subsystem that wraps `LabelSetFont`, remaps only a strict allowlist of stock low-readability fonts, and refreshes a bounded registry of already-created stock HUD labels. Integrate it into existing settings/commands/doctor lifecycle and keep all behavior event-driven with no permanent UI polling.

**Tech Stack:** Return of Reckoning Lua/XML addon APIs; Python static regression tests.

**Spec:** `docs/superpowers/specs/2026-09-09-ui-font-readability-design.md`

## Global Constraints

- Release version is `0.2.0` in both `ClearNames.lua` and `ClearNames.mod`.
- Preserve every existing 0.1.1 feature and HD-label invariant.
- UI modes are exactly `off`, `readable`, and `large`.
- New installs/default migrations use `readable`.
- Unknown/custom fonts must pass through unchanged.
- The hook must be idempotent and reversible.
- Removal must not overwrite a later third-party `LabelSetFont` hook.
- Static refresh targets are bounded and missing windows are ignored.
- Do not redefine core font assets or change global interface scale.
- Do not introduce a manifest-level/permanent `OnUpdate` loop.

---

### Task 1: Lock the UI-font contracts with failing regression tests

**Files:**
- Modify: `tests/verify_addon.py`

**Interfaces:**
- Consumes: current ClearNames source tree.
- Produces: static contract tests for `UIFonts.lua`, lifecycle integration, manifest/versioning, and preserved HD behavior.

- [ ] **Step 1: Add failing tests**

Add tests asserting:

```python
def test_ui_fonts_module_is_loaded_before_main():
    manifest = read("ClearNames.mod")
    assert '<File name="UIFonts.lua" />' in manifest
    assert manifest.index('<File name="UIFonts.lua" />') < manifest.index('<File name="ClearNames.lua" />')


def test_ui_font_modes_and_mapping_contract_exist():
    source = read("UIFonts.lua")
    assert 'off = true' in source
    assert 'readable = true' in source
    assert 'large = true' in source
    assert 'font_heading_unitframe_large_name' in source
    assert 'font_heading_target_mouseover_name' in source
    assert 'font_clear_medium_bold' in source
    assert 'font_clear_large_bold' in source


def test_unknown_fonts_pass_through():
    source = read("UIFonts.lua")
    assert 'return mapped or fontName' in source


def test_hook_is_reversible_idempotent_and_third_party_safe():
    source = read("UIFonts.lua")
    assert 'LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont' in source
    assert 'LabelSetFont = ClearNames.UIFonts.WrappedLabelSetFont' in source
    assert 'if LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont then' in source
    assert 'LabelSetFont = ClearNames.UIFonts.delegate' in source


def test_static_refresh_is_bounded_to_known_hud_labels():
    source = read("UIFonts.lua")
    assert 'PlayerWindowPlayerName' in source
    assert 'PlayerWindowLevelText' in source
    assert 'TargetWindowName' in source
    assert 'FriendlyTargetWindowName' in source
    assert 'MouseOverTargetUnitWindowName' in source
    assert 'GroupWindowPlayer' in source
    assert 'OnUpdate' not in source


def test_ui_command_default_and_doctor_are_integrated():
    source = read("ClearNames.lua")
    assert 'uiFontMode = "readable"' in source
    assert 'cmd == "ui"' in source
    assert 'ClearNames.UIFonts.SetMode' in source
    assert 'UIFonts=' in source
    assert 'mapped=' in source


def test_version_is_0_2_0_everywhere():
    source = read("ClearNames.lua")
    manifest = read("ClearNames.mod")
    assert 'ClearNames.VERSION = "0.2.0"' in source
    assert '<UiMod name="ClearNames" version="0.2.0"' in manifest
```

Keep all existing 0.1.1 HD-label tests unchanged except the version assertion, which becomes 0.2.0.

- [ ] **Step 2: Run the tests and verify RED**

Run:

```bash
pytest -q tests/verify_addon.py
```

Expected: failures because `UIFonts.lua`, the new manifest entry, commands, defaults, diagnostics, and 0.2.0 version do not exist yet; existing HD tests remain green.

- [ ] **Step 3: Commit the RED test state**

Commit message:

```text
test: define UI font readability contracts
```

---

### Task 2: Implement the isolated UI font mapper and hook

**Files:**
- Create: `UIFonts.lua`
- Modify: `ClearNames.mod`

**Interfaces:**
- Produces: `ClearNames.UIFonts.Resolve(fontName, mode)`, `InstallHook()`, `RemoveHook()`, `SetMode(mode)`, `RefreshKnown()`, `WrappedLabelSetFont(windowName, fontName, lineSpacing)`, `IsHooked()`.

- [ ] **Step 1: Implement the minimal mapper and hook**

Create `UIFonts.lua` with:

```lua
ClearNames = ClearNames or {}
ClearNames.UIFonts = ClearNames.UIFonts or {}
ClearNames.UIFonts.delegate = ClearNames.UIFonts.delegate or nil
ClearNames.UIFonts.hooked = false
ClearNames.UIFonts.mappedCalls = 0

local validModes = { off = true, readable = true, large = true }

local readableMap = {
    font_clear_tiny = "font_clear_small_bold",
    font_clear_small = "font_clear_small_bold",
    font_clear_medium = "font_clear_medium_bold",
    font_clear_large = "font_clear_large_bold",
    font_default_text_small = "font_clear_medium_bold",
    font_default_text = "font_clear_medium_bold",
    font_default_text_no_outline = "font_clear_medium_bold",
    font_default_text_large = "font_clear_medium_bold",
    font_chat_text = "font_clear_medium_bold",
    font_chat_text_no_outline = "font_clear_medium_bold",
    font_chat_text_bold = "font_clear_medium_bold",
    font_heading_target_mouseover_name = "font_clear_medium_bold",
    font_heading_unitframe_large_name = "font_clear_medium_bold",
    font_heading_rank = "font_clear_medium_bold",
}

local largeMap = {
    font_clear_tiny = "font_clear_medium_bold",
    font_clear_small = "font_clear_medium_bold",
    font_clear_medium = "font_clear_large_bold",
    font_clear_large = "font_clear_large_bold",
    font_default_text_small = "font_clear_medium_bold",
    font_default_text = "font_clear_large_bold",
    font_default_text_no_outline = "font_clear_large_bold",
    font_default_text_large = "font_clear_large_bold",
    font_chat_text = "font_clear_large_bold",
    font_chat_text_no_outline = "font_clear_large_bold",
    font_chat_text_bold = "font_clear_large_bold",
    font_heading_target_mouseover_name = "font_clear_large_bold",
    font_heading_unitframe_large_name = "font_clear_large_bold",
    font_heading_rank = "font_clear_medium_bold",
}
```

`Resolve` selects the map for the active mode and uses `return mapped or fontName` for pass-through.

`WrappedLabelSetFont` resolves the font, increments `mappedCalls` only when the resolved resource differs, and calls the stored delegate.

`InstallHook` returns false if `LabelSetFont` is unavailable, returns true without mutation if already installed, otherwise stores the current global as `delegate` and installs the wrapper.

`RemoveHook` restores the delegate only inside `if LabelSetFont == ClearNames.UIFonts.WrappedLabelSetFont then`, then clears hook state without overwriting another addon's later replacement.

- [ ] **Step 2: Add bounded static refresh**

Create a known-label registry for:

```lua
{ "PlayerWindowPlayerName", "font_heading_unitframe_large_name" }
{ "PlayerWindowLevelText", "font_heading_rank" }
{ "TargetWindowName", "font_heading_unitframe_large_name" }
{ "FriendlyTargetWindowName", "font_heading_unitframe_large_name" }
{ "MouseOverTargetUnitWindowName", "font_heading_target_mouseover_name" }
```

In `RefreshKnown`, also loop `i = 1, 5` and refresh `"GroupWindowPlayer" .. i .. "Name"` with `font_heading_unitframe_large_name`.

For each label, use `DoesWindowExist` when available; skip missing windows. Call `delegate` directly with `WindowUtils.FONT_DEFAULT_TEXT_LINESPACING` when available, otherwise line spacing `0`. Do not register any update loop.

- [ ] **Step 3: Add mode application**

`SetMode(mode)` lowercases/validates exact modes, persists `ClearNames.Settings.uiFontMode`, installs the hook when mode is not `off`, leaves a previously installed wrapper in pass-through mode when switching to `off`, and calls `RefreshKnown()`.

- [ ] **Step 4: Load the module in the manifest**

Insert:

```xml
<File name="UIFonts.lua" />
```

before `ClearNames.lua`.

- [ ] **Step 5: Run tests**

Run:

```bash
pytest -q tests/verify_addon.py
```

Expected: Task 2-specific tests pass; integration/version tests remain red.

- [ ] **Step 6: Commit**

Commit message:

```text
feat: add reversible UI font mapper
```

---

### Task 3: Integrate settings, commands, diagnostics, and lifecycle

**Files:**
- Modify: `ClearNames.lua`

**Interfaces:**
- Consumes: `ClearNames.UIFonts` from Task 2.
- Produces: persisted default, `/clearnames ui ...`, diagnostics, initialization and shutdown lifecycle.

- [ ] **Step 1: Migrate defaults**

Inside `defaults()` add:

```lua
if not ClearNames.Settings.uiFontMode then ClearNames.Settings.uiFontMode = "readable" end
```

- [ ] **Step 2: Add command handling**

In `ClearNames.Command`, add a `ui` branch that lowercases `rest`, calls `ClearNames.UIFonts.SetMode`, reports the active mode on success, and reports `ui mode must be off, readable, or large` on failure.

Update help text to include `ui off|readable|large`.

- [ ] **Step 3: Expand doctor output**

Add diagnostics containing the exact text fragments `UIFonts=` and `mapped=`. Report the active mode, whether `ClearNames.UIFonts.IsHooked()` is true, and `mappedCalls`.

- [ ] **Step 4: Wire lifecycle**

After profile application in `OnInitialize`, call:

```lua
ClearNames.UIFonts.SetMode(ClearNames.Settings.uiFontMode)
```

In `OnShutdown`, after HD-label cleanup, call:

```lua
ClearNames.UIFonts.RemoveHook()
```

- [ ] **Step 5: Run tests**

Run:

```bash
pytest -q tests/verify_addon.py
```

Expected: all behavior tests except version/docs pass.

- [ ] **Step 6: Commit**

Commit message:

```text
feat: integrate UI readability controls
```

---

### Task 4: Release 0.2.0 and document the ReShade profile

**Files:**
- Modify: `ClearNames.lua`
- Modify: `ClearNames.mod`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Produces: synchronized release metadata and user-facing instructions.

- [ ] **Step 1: Bump version**

Set:

```lua
ClearNames.VERSION = "0.2.0"
```

and:

```xml
<UiMod name="ClearNames" version="0.2.0" date="09/09/2026">
```

- [ ] **Step 2: Update README**

Document:

- `/clearnames ui off|readable|large`
- `readable` as the recommended ReShade-friendly default
- bold/outlined font substitution rather than global UI scaling
- bounded static HUD refresh plus runtime `LabelSetFont` remapping
- third-party/unknown font pass-through
- `/clearnames ui off` recovery
- no claim that ClearNames bypasses or controls ReShade's rendering pipeline

- [ ] **Step 3: Update changelog**

Add a 0.2.0 section covering the reversible UI font mapper, ReShade-readable default, bounded stock HUD refresh, hook-safety behavior, and preserved 0.1.1 NPC-label work.

- [ ] **Step 4: Run full verification**

Run:

```bash
pytest -q tests/verify_addon.py
python - <<'PY'
import xml.etree.ElementTree as ET
ET.parse('ClearNames.mod')
ET.parse('ClearNames.xml')
print('xml-ok')
PY
```

Expected: all tests pass and `xml-ok` prints.

- [ ] **Step 5: Review diff for scope**

Confirm only the planned files changed, existing HD behavior remains present, no permanent update loop was added, and no unrelated addon behavior was removed.

- [ ] **Step 6: Commit**

Commit message:

```text
release: ClearNames 0.2.0 UI readability
```

---

### Task 5: Final verification and ship to main

**Files:** no new implementation files.

**Interfaces:** verified Git history and fast-forwarded `main`.

- [ ] **Step 1: Re-run the complete test command fresh**

```bash
pytest -q tests/verify_addon.py
```

Require zero failures.

- [ ] **Step 2: Verify branch relationship**

Confirm current `main` has not moved and the feature branch is ahead with `behind_by = 0`.

- [ ] **Step 3: Inspect commit status**

If repository status checks exist, require successful checks. If none are configured, record that fact explicitly.

- [ ] **Step 4: Fast-forward main without force**

Move `main` to the verified feature head with `force=false`.

- [ ] **Step 5: Verify identity**

Compare feature head against `main`; require `status=identical`.

- [ ] **Step 6: Report the remaining runtime limitation**

State clearly that source/static verification cannot substitute for launching the Return of Reckoning client, so visual clipping/compatibility with the user's specific addon stack and ReShade preset still requires an in-game check.
