"""Environment detection service checking yt-dlp, FFmpeg, FFprobe, and cookies."""

import shutil
import subprocess
from dataclasses import dataclass
from typing import Any, Dict, Optional

from app.utils.logger import get_logger
from app.utils.paths import get_cookies_path

logger = get_logger()


@dataclass
class ToolStatus:
    name: str
    available: bool
    version: str = ""
    path: str = ""
    status_text: str = ""
    error_message: str = ""


@dataclass
class EnvironmentStatus:
    yt_dlp: ToolStatus
    ffmpeg: ToolStatus
    ffprobe: ToolStatus
    cookies_found: bool
    cookies_path: str = ""
    all_critical_ready: bool = True

    def to_dict(self) -> Dict[str, Any]:
        return {
            "yt_dlp": {
                "available": self.yt_dlp.available,
                "version": self.yt_dlp.version,
                "path": self.yt_dlp.path,
                "status_text": self.yt_dlp.status_text,
                "error_message": self.yt_dlp.error_message,
            },
            "ffmpeg": {
                "available": self.ffmpeg.available,
                "version": self.ffmpeg.version,
                "path": self.ffmpeg.path,
                "status_text": self.ffmpeg.status_text,
                "error_message": self.ffmpeg.error_message,
            },
            "ffprobe": {
                "available": self.ffprobe.available,
                "version": self.ffprobe.version,
                "path": self.ffprobe.path,
                "status_text": self.ffprobe.status_text,
                "error_message": self.ffprobe.error_message,
            },
            "cookies_found": self.cookies_found,
            "cookies_path": self.cookies_path,
            "all_critical_ready": self.all_critical_ready,
        }


class EnvironmentService:
    """Detects availability and versions of yt-dlp, FFmpeg, FFprobe, and cookies.txt."""

    @staticmethod
    def check_yt_dlp() -> ToolStatus:
        """Check for yt-dlp Python package or executable."""
        try:
            import yt_dlp
            try:
                from yt_dlp.version import __version__ as yt_ver
                version = str(yt_ver)
            except Exception:
                version = str(getattr(yt_dlp, "__version__", "unknown"))
            return ToolStatus(
                name="yt-dlp",
                available=True,
                version=version,
                path=yt_dlp.__file__,
                status_text="Ready"
            )
        except ImportError:
            # Check executable as fallback
            exe = shutil.which("yt-dlp")
            if exe:
                try:
                    res = subprocess.run([exe, "--version"], capture_output=True, text=True, timeout=5)
                    ver = res.stdout.strip()
                    return ToolStatus(name="yt-dlp", available=True, version=ver, path=exe, status_text="Ready")
                except Exception as e:
                    logger.warning("yt-dlp executable found but failed check: %s", e)

            return ToolStatus(
                name="yt-dlp",
                available=False,
                status_text="Not Found",
                error_message="yt-dlp is not installed in the Python environment."
            )

    @staticmethod
    def check_ffmpeg() -> ToolStatus:
        """Check for ffmpeg executable in PATH."""
        exe = shutil.which("ffmpeg")
        if not exe:
            return ToolStatus(
                name="FFmpeg",
                available=False,
                status_text="Not Found",
                error_message="FFmpeg was not found in your Windows PATH. Post-processing and stream merging may fail."
            )

        try:
            res = subprocess.run([exe, "-version"], capture_output=True, text=True, timeout=5)
            first_line = res.stdout.splitlines()[0] if res.stdout else ""
            version_part = first_line.split("Copyright")[0].strip() if "Copyright" in first_line else first_line
            return ToolStatus(
                name="FFmpeg",
                available=True,
                version=version_part,
                path=exe,
                status_text="Ready"
            )
        except Exception as e:
            logger.warning("FFmpeg command failed: %s", e)
            return ToolStatus(
                name="FFmpeg",
                available=False,
                path=exe,
                status_text="Error",
                error_message=str(e)
            )

    @staticmethod
    def check_ffprobe() -> ToolStatus:
        """Check for ffprobe executable in PATH."""
        exe = shutil.which("ffprobe")
        if not exe:
            return ToolStatus(
                name="FFprobe",
                available=False,
                status_text="Not Found",
                error_message="FFprobe was not found in your Windows PATH."
            )

        try:
            res = subprocess.run([exe, "-version"], capture_output=True, text=True, timeout=5)
            first_line = res.stdout.splitlines()[0] if res.stdout else ""
            version_part = first_line.split("Copyright")[0].strip() if "Copyright" in first_line else first_line
            return ToolStatus(
                name="FFprobe",
                available=True,
                version=version_part,
                path=exe,
                status_text="Ready"
            )
        except Exception as e:
            return ToolStatus(
                name="FFprobe",
                available=False,
                path=exe,
                status_text="Error",
                error_message=str(e)
            )

    @classmethod
    def get_status(cls) -> EnvironmentStatus:
        """Perform full environment detection."""
        ytdlp_stat = cls.check_yt_dlp()
        ffmpeg_stat = cls.check_ffmpeg()
        ffprobe_stat = cls.check_ffprobe()

        cookies_file = get_cookies_path()
        cookies_found = cookies_file is not None
        cookies_str = str(cookies_file) if cookies_file else ""

        all_ready = ytdlp_stat.available and ffmpeg_stat.available

        logger.info(
            "Environment check: yt-dlp=%s, ffmpeg=%s, ffprobe=%s, cookies=%s",
            ytdlp_stat.status_text,
            ffmpeg_stat.status_text,
            ffprobe_stat.status_text,
            "Found" if cookies_found else "Not configured"
        )

        return EnvironmentStatus(
            yt_dlp=ytdlp_stat,
            ffmpeg=ffmpeg_stat,
            ffprobe=ffprobe_stat,
            cookies_found=cookies_found,
            cookies_path=cookies_str,
            all_critical_ready=all_ready
        )
