"""Path resolution and directory management for Soldier Downloader."""

import os
import sys
from pathlib import Path
from typing import Optional


def get_app_root() -> Path:
    """Return root directory of the application source or frozen bundle."""
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS)
    # File is in app/utils/paths.py -> root is 2 levels up
    return Path(__file__).resolve().parent.parent.parent


def get_local_appdata_dir() -> Path:
    """Return %LOCALAPPDATA%\\SoldierDownloader directory, creating it if needed."""
    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        base = Path(local_appdata) / "SoldierDownloader"
    else:
        base = Path.home() / ".soldier_downloader"
    base.mkdir(parents=True, exist_ok=True)
    return base


def get_logs_dir() -> Path:
    """Return logs directory in %LOCALAPPDATA%\\SoldierDownloader\\logs."""
    logs_dir = get_local_appdata_dir() / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    return logs_dir


def get_temp_dir() -> Path:
    """Return managed temporary working directory."""
    temp_dir = get_local_appdata_dir() / "temp"
    temp_dir.mkdir(parents=True, exist_ok=True)
    return temp_dir


def get_db_path() -> Path:
    """Return path to history SQLite database."""
    return get_local_appdata_dir() / "history.db"


def get_default_download_dir() -> Path:
    """Return default download directory %USERPROFILE%\\Downloads\\Soldiers."""
    dest = Path.home() / "Downloads" / "Soldiers"
    dest.mkdir(parents=True, exist_ok=True)
    return dest


def get_cookies_path() -> Optional[Path]:
    """Check for cookies.txt in the application root or local app data."""
    root_cookies = get_app_root() / "cookies.txt"
    if root_cookies.is_file() and root_cookies.stat().st_size > 0:
        return root_cookies
    
    appdata_cookies = get_local_appdata_dir() / "cookies.txt"
    if appdata_cookies.is_file() and appdata_cookies.stat().st_size > 0:
        return appdata_cookies
        
    return None


def resolve_qml_path(relative_path: str = "qml/Main.qml") -> str:
    """Resolve absolute path to QML file, supporting PyInstaller bundles."""
    full_path = get_app_root() / relative_path
    return str(full_path.resolve())
