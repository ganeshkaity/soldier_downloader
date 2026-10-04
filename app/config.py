"""Runtime application configuration and CLI argument parser."""

import argparse
from dataclasses import dataclass
from typing import Optional


@dataclass
class AppConfig:
    debug: bool = False
    start_minimized: bool = False


_config: Optional[AppConfig] = None


def parse_args() -> AppConfig:
    """Parse command line arguments."""
    global _config
    parser = argparse.ArgumentParser(description="Soldier Downloader - Desktop YouTube Media Downloader")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging and diagnostic UI")
    parser.add_argument("--minimized", action="store_true", help="Start application minimized to system tray")
    args = parser.parse_args()

    _config = AppConfig(
        debug=args.debug,
        start_minimized=args.minimized
    )
    return _config


def get_config() -> AppConfig:
    """Get active runtime configuration."""
    global _config
    if _config is None:
        _config = AppConfig()
    return _config
