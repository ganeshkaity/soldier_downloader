"""FFmpeg discovery and verification service."""

import os
import shutil
from typing import Optional
from app.utils.logger import get_logger

logger = get_logger()


class FFmpegService:
    """Provides path resolution and capability checks for FFmpeg."""

    @staticmethod
    def get_ffmpeg_path() -> Optional[str]:
        """Return the absolute path to ffmpeg.exe if found on PATH."""
        return shutil.which("ffmpeg")

    @staticmethod
    def get_ffprobe_path() -> Optional[str]:
        """Return the absolute path to ffprobe.exe if found on PATH."""
        return shutil.which("ffprobe")

    @classmethod
    def is_available(cls) -> bool:
        """Return True if both ffmpeg and ffprobe are available."""
        return cls.get_ffmpeg_path() is not None and cls.get_ffprobe_path() is not None
