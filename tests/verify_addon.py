from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_manifest_file_paths_exist():
    manifest = read("ClearNames.mod")
    paths = re.findall(r'<File name="([^"]+)"\s*/>', manifest)
    assert paths, "manifest must declare addon files"
    missing = [path for path in paths if not (ROOT / path).is_file()]
    assert missing == [], f"manifest references missing files: {missing}"


def test_target_info_dependency_is_declared():
    manifest = read("ClearNames.mod")
    assert '<Dependency name="EASystem_TargetInfo" />' in manifest


def test_hd_labels_use_published_target_state_only():
    source = read("HDLabels.lua")
    assert "TargetInfo:UnitEntityId" in source
    assert "TargetInfo:UnitName" in source
    assert "TargetInfo:UnitIsNPC" in source
    assert "TargetInfo:UpdateFromClient" not in source
    assert "GetUpdatedTargets" not in source


def test_hd_labels_defer_target_sync_one_frame_on_root():
    source = read("HDLabels.lua")
    assert "ClearNames.HDLabels.OnTargetUpdated" in source
    assert "ClearNames.HDLabels.FlushPendingTargetSync" in source
    assert 'WindowRegisterCoreEventHandler("Root", "OnUpdate", "ClearNames.HDLabels.FlushPendingTargetSync")' in source
    assert 'WindowUnregisterCoreEventHandler("Root", "OnUpdate")' in source


def test_one_shot_scheduler_requires_register_and_unregister():
    source = read("HDLabels.lua")
    assert 'type(WindowRegisterCoreEventHandler) ~= "function" or type(WindowUnregisterCoreEventHandler) ~= "function"' in source


def test_hd_labels_keep_constant_screen_scale():
    source = read("HDLabels.lua")
    assert "WindowSetScale(windowName, 1.0)" in source
    assert "MoveWindowToWorldObject" not in source


def test_target_event_bridge_is_registered_on_root():
    source = read("ClearNames.lua")
    assert "SystemData.Events.PLAYER_TARGET_UPDATED" in source
    assert 'WindowRegisterEventHandler("Root", SystemData.Events.PLAYER_TARGET_UPDATED, "ClearNames.HDLabels.OnTargetUpdated")' in source
    assert 'WindowUnregisterEventHandler("Root", SystemData.Events.PLAYER_TARGET_UPDATED)' in source


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
    assert 'ClearNames.UIFonts.delegate = nil' in source


def test_ui_font_remap_is_scoped_away_from_player_and_group_hud():
    source = read("UIFonts.lua")
    assert 'ClearNames.UIFonts.ShouldRemapWindow' in source
    assert 'string.match(windowName, "^ChatWindow")' in source
    assert 'string.match(windowName, "^EA_Chat")' in source
    assert 'TargetWindowName = true' in source
    assert '{ name = "PlayerWindowPlayerName"' not in source
    assert '{ name = "PlayerWindowLevelText"' not in source
    assert '"GroupWindowPlayer" .. i .. "Name"' not in source


def test_static_refresh_is_bounded_to_safe_target_labels():
    source = read("UIFonts.lua")
    assert 'TargetWindowName' in source
    assert 'FriendlyTargetWindowName' in source
    assert 'MouseOverTargetUnitWindowName' in source
    assert 'OnUpdate' not in source


def test_ui_refresh_is_sparse_event_driven_and_reversible():
    source = read("UIFonts.lua")
    assert 'ClearNames.UIFonts.RegisterRefreshEvents' in source
    assert 'ClearNames.UIFonts.UnregisterRefreshEvents' in source
    assert '"LOADING_END"' in source
    assert '"GROUP_UPDATED"' in source
    assert '"GROUP_PLAYER_ADDED"' in source
    assert 'SystemData.Events[key]' in source
    assert 'RegisterEventHandler' in source
    assert 'UnregisterEventHandler' in source
    assert 'ClearNames.UIFonts.OnUiRefreshEvent' in source
    assert 'OnUpdate' not in source


def test_ui_command_default_and_doctor_are_integrated():
    source = read("ClearNames.lua")
    assert 'uiFontMode = "readable"' in source
    assert 'cmd == "ui"' in source
    assert 'ClearNames.UIFonts.SetMode' in source
    assert 'UIFonts=' in source
    assert 'mapped=' in source


def test_doctor_reports_hd_label_state():
    source = read("ClearNames.lua")
    assert 'HDLabels=' in source
    assert 'hdEnabled' in source


def test_ui_font_lifecycle_is_wired_without_polling():
    source = read("ClearNames.lua")
    assert 'ClearNames.UIFonts.SetMode(ClearNames.Settings.uiFontMode)' in source
    assert 'ClearNames.UIFonts.RemoveHook()' in source
    manifest = read("ClearNames.mod")
    assert '<OnUpdate>' not in manifest


def test_version_is_0_2_1_everywhere():
    source = read("ClearNames.lua")
    manifest = read("ClearNames.mod")
    assert 'ClearNames.VERSION = "0.2.1"' in source
    assert '<UiMod name="ClearNames" version="0.2.1"' in manifest
