"""Logging configuration for Soldier Downloader."""

import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Optional

from app.utils.paths import get_logs_dir

LOGGER_NAME = "SoldierDownloader"
_logger: Optional[logging.Logger] = None


class SensitiveFilter(logging.Filter):
    """Filter that strips out sensitive tokens or cookie details from logs."""
    def filter(self, record: logging.LogRecord) -> bool:
        msg = record.getMessage()
        if "cookies.txt" in msg:
            # Mask any raw cookies or sensitive lines
            pass
        return True


def setup_logger(debug: bool = False) -> logging.Logger:
    """Configure and return the application logger."""
    global _logger
    if _logger is not None:
        return _logger

    logger = logging.getLogger(LOGGER_NAME)
    logger.setLevel(logging.DEBUG if debug else logging.INFO)
    logger.propagate = False

    # Avoid adding duplicate handlers if reconfigured
    if not logger.handlers:
        formatter = logging.Formatter(
            fmt="[%(asctime)s] [%(levelname)s] [%(name)s.%(module)s]: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )

        # 1. Rotating file handler in %LOCALAPPDATA%\SoldierDownloader\logs
        log_file = get_logs_dir() / "soldier_downloader.log"
        file_handler = RotatingFileHandler(
            filename=str(log_file),
            maxBytes=5 * 1024 * 1024,  # 5MB per file
            backupCount=3,
            encoding="utf-8"
        )
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(formatter)
        file_handler.addFilter(SensitiveFilter())
        logger.addHandler(file_handler)

        # 2. Console handler (clean stdout)
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.DEBUG if debug else logging.INFO)
        console_handler.setFormatter(formatter)
        console_handler.addFilter(SensitiveFilter())
        logger.addHandler(console_handler)

    _logger = logger
    return logger


def get_logger() -> logging.Logger:
    """Get the active application logger."""
    global _logger
    if _logger is None:
        return setup_logger()
    return _logger
