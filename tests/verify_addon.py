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


def test_version_is_0_1_1_everywhere():
    source = read("ClearNames.lua")
    manifest = read("ClearNames.mod")
    assert 'ClearNames.VERSION = "0.1.1"' in source
    assert '<UiMod name="ClearNames" version="0.1.1"' in manifest
