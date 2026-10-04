"""Unit tests for persistent settings management."""

import pytest
from app.settings.settings_manager import SettingsManager


def test_settings_default_values(tmp_path):
    settings_file = tmp_path / "settings.json"
    mgr = SettingsManager(file_path=settings_file)

    assert mgr.get("concurrent_downloads") == 5
    assert mgr.get("default_video_quality") == "Best"
    assert mgr.get("duplicate_mode") == "Skip"
    assert mgr.get("minimize_to_tray") is True


def test_settings_save_and_reload(tmp_path):
    settings_file = tmp_path / "settings.json"
    mgr = SettingsManager(file_path=settings_file)

    mgr.set("concurrent_downloads", 8)
    mgr.set("default_video_quality", "1080p")
    mgr.set("duplicate_mode", "Overwrite")

    # Create new instance reading the same file
    mgr2 = SettingsManager(file_path=settings_file)
    assert mgr2.get("concurrent_downloads") == 8
    assert mgr2.get("default_video_quality") == "1080p"
    assert mgr2.get("duplicate_mode") == "Overwrite"


def test_settings_clamping_and_validation(tmp_path):
    settings_file = tmp_path / "settings.json"
    mgr = SettingsManager(file_path=settings_file)

    # Concurrency must be clamped to [1, 10]
    mgr.set("concurrent_downloads", 999)
    assert mgr.get("concurrent_downloads") == 5

    mgr.set("concurrent_downloads", -5)
    assert mgr.get("concurrent_downloads") == 5

    # Invalid duplicate mode falls back
    mgr.set("duplicate_mode", "InvalidMode")
    assert mgr.get("duplicate_mode") == "Skip"
