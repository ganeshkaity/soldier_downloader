"""Persistent application settings manager for Soldier Downloader."""

import json
from pathlib import Path
from typing import Any, Dict, Optional

from app.constants import (
    CLOSE_BEHAVIORS,
    DEFAULT_CONCURRENT_DOWNLOADS,
    DEFAULT_DOWNLOAD_DIR,
    DUPLICATE_BEHAVIORS,
    MAX_CONCURRENT_DOWNLOADS,
    MIN_CONCURRENT_DOWNLOADS,
)
from app.utils.logger import get_logger
from app.utils.paths import get_local_appdata_dir

logger = get_logger()

DEFAULT_SETTINGS: Dict[str, Any] = {
    "download_dir": DEFAULT_DOWNLOAD_DIR,
    "concurrent_downloads": DEFAULT_CONCURRENT_DOWNLOADS,
    "default_video_quality": "Best",
    "default_audio_format": "MP3",
    "duplicate_mode": "Skip",
    "filename_sanitization": True,
    "yt_dlp_update_check": True,
    "minimize_to_tray": True,
    "start_minimized": False,
    "close_behavior": "Minimize to tray",
    "debug_mode": False,
}


class SettingsManager:
    """Manages loading, validating, and saving application settings."""

    def __init__(self, file_path: Optional[Path] = None):
        self.file_path = file_path or (get_local_appdata_dir() / "settings.json")
        self._settings: Dict[str, Any] = dict(DEFAULT_SETTINGS)
        self.load()

    def load(self) -> None:
        """Load settings from JSON file, falling back to defaults for missing keys."""
        if self.file_path.exists():
            try:
                with open(self.file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, dict):
                        self._settings.update(data)
                        self._validate()
                        logger.info("Settings loaded from %s", self.file_path)
                        return
            except Exception as e:
                logger.warning("Failed to parse settings file: %s. Using defaults.", e)
        
        # Save defaults if file doesn't exist
        self.save()

    def save(self) -> None:
        """Write current settings to disk."""
        try:
            self.file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
            logger.info("Settings saved successfully")
        except Exception as e:
            logger.error("Failed to save settings: %s", e, exc_info=True)

    def _validate(self) -> None:
        """Ensure settings values fall within allowed ranges and types."""
        # Concurrent downloads limit
        conc = self._settings.get("concurrent_downloads", DEFAULT_CONCURRENT_DOWNLOADS)
        if not isinstance(conc, int) or conc < MIN_CONCURRENT_DOWNLOADS or conc > MAX_CONCURRENT_DOWNLOADS:
            self._settings["concurrent_downloads"] = DEFAULT_CONCURRENT_DOWNLOADS

        # Duplicate mode
        dup = self._settings.get("duplicate_mode", "Skip")
        if dup not in DUPLICATE_BEHAVIORS:
            self._settings["duplicate_mode"] = "Skip"

        # Close behavior
        close = self._settings.get("close_behavior", "Minimize to tray")
        if close not in CLOSE_BEHAVIORS:
            self._settings["close_behavior"] = "Minimize to tray"

        # Ensure download directory is string
        if not self._settings.get("download_dir"):
            self._settings["download_dir"] = DEFAULT_DOWNLOAD_DIR

    def get(self, key: str, default: Any = None) -> Any:
        """Get a setting value by key."""
        return self._settings.get(key, default)

    def set(self, key: str, value: Any) -> None:
        """Update a setting and persist to disk."""
        self._settings[key] = value
        self._validate()
        self.save()

    def update_multiple(self, values: Dict[str, Any]) -> None:
        """Update multiple settings at once and save."""
        self._settings.update(values)
        self._validate()
        self.save()

    def all_settings(self) -> Dict[str, Any]:
        """Return a copy of all current settings."""
        return dict(self._settings)

    def reset_to_defaults(self) -> None:
        """Reset all settings back to default values."""
        self._settings = dict(DEFAULT_SETTINGS)
        self.save()
