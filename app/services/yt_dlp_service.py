"""Wrapper around yt-dlp Python API for extraction and error handling."""

import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import yt_dlp
from yt_dlp.utils import DownloadError, ExtractorError, GeoRestrictedError

from app.models.format_info import FormatInfo
from app.models.video_info import VideoInfo
from app.services.format_service import FormatService
from app.utils.logger import get_logger
from app.utils.paths import get_cookies_path, get_temp_dir

logger = get_logger()


def translate_error(error: Exception) -> Tuple[str, str]:
    """
    Translate technical exceptions into a user-friendly message and technical detail.
    Returns (friendly_message, technical_details).
    """
    err_str = str(error)
    details = f"{type(error).__name__}: {err_str}"

    err_lower = err_str.lower()
    if "private video" in err_lower or "sign in" in err_lower:
        return (
            "This video is private or requires sign-in.\n"
            "If you have access, ensure your cookies.txt is placed in the project root.",
            details
        )
    if "age" in err_lower and "restricted" in err_lower:
        return (
            "This video is age-restricted.\n"
            "YouTube requires an authenticated session to verify age. Provide a valid cookies.txt.",
            details
        )
    if "geo" in err_lower or "country" in err_lower or "region" in err_lower:
        return (
            "This video is not available in your geographical region or country.",
            details
        )
    if "video unavailable" in err_lower or "not exist" in err_lower or "does not exist" in err_lower:
        return (
            "This video is unavailable or has been removed by the uploader.",
            details
        )
    if (
        "network" in err_lower
        or "timeout" in err_lower
        or "timed out" in err_lower
        or "connection" in err_lower
        or "urlopen" in err_lower
        or "getaddrinfo" in err_lower
        or "name or service not known" in err_lower
        or "dns" in err_lower
    ):
        return (
            "Network connection failed. Please check your internet connection and retry.",
            details
        )
    if "ffmpeg" in err_lower or "ffprobe" in err_lower:
        return (
            "FFmpeg error occurred during post-processing.\n"
            "Ensure FFmpeg is installed and accessible on your Windows PATH.",
            details
        )
    if "disk" in err_lower or "space" in err_lower:
        return (
            "Insufficient disk space to complete this download.",
            details
        )

    return (
        "YouTube could not provide this media right now.\n"
        "The video might be temporarily restricted or the format changed.",
        details
    )


class YtDlpService:
    """Provides methods for extracting metadata, available streams, and formats."""

    translate_error = staticmethod(translate_error)

    @staticmethod
    def get_base_ydl_opts(custom_opts: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Build standard base options for yt-dlp."""
        opts: Dict[str, Any] = {
            "quiet": True,
            "no_warnings": True,
            "nocheckcertificate": False,
            "cachedir": str(get_temp_dir() / "ytdlp_cache"),
            "extract_flat": False,
        }

        # Apply cookies if present
        cookies_file = get_cookies_path()
        if cookies_file and cookies_file.is_file() and cookies_file.stat().st_size > 0:
            opts["cookiefile"] = str(cookies_file)

        if custom_opts:
            opts.update(custom_opts)

        return opts

    @classmethod
    def extract_video_info(cls, url: str) -> VideoInfo:
        """
        Extract detailed metadata and available formats for a single video.
        Must be called outside the GUI thread.
        """
        opts = cls.get_base_ydl_opts({
            "extract_flat": False,
            "skip_download": True,
        })

        try:
            with yt_dlp.YoutubeDL(opts) as ydl:
                info = ydl.extract_info(url, download=False)
                if info is None:
                    raise ValueError("yt-dlp returned no information for the given URL.")

                # If a playlist URL was passed, select the first entry or use root info
                if "entries" in info and info["entries"]:
                    entries = list(info["entries"])
                    if entries:
                        info = entries[0]

                video_id = str(info.get("id", ""))
                title = str(info.get("title", "Untitled Video"))
                duration = int(info.get("duration") or 0)
                channel = str(info.get("uploader") or info.get("channel") or "Unknown Channel")
                thumbnail_url = str(info.get("thumbnail") or "")
                view_count = info.get("view_count")
                upload_date = str(info.get("upload_date") or "")
                description = str(info.get("description") or "")
                is_short = "/shorts/" in url or (duration > 0 and duration <= 60 and info.get("aspect_ratio", 1.0) < 1.0)

                # Parse formats
                raw_formats = info.get("formats", [])
                parsed_formats: List[FormatInfo] = []
                for rf in raw_formats:
                    try:
                        parsed_formats.append(FormatService.parse_format_dict(rf))
                    except Exception as fe:
                        logger.debug("Failed parsing format dict: %s", fe)

                # Estimate size from best formats
                estimated_size = info.get("filesize") or info.get("filesize_approx")
                if not estimated_size and parsed_formats:
                    sizes = [f.filesize for f in parsed_formats if f.filesize]
                    if sizes:
                        estimated_size = max(sizes)

                return VideoInfo(
                    video_id=video_id,
                    title=title,
                    url=url,
                    duration=duration,
                    channel=channel,
                    thumbnail_url=thumbnail_url,
                    view_count=int(view_count) if view_count else None,
                    upload_date=upload_date,
                    description=description,
                    is_short=is_short,
                    formats=parsed_formats,
                    estimated_size=int(estimated_size) if estimated_size else None,
                )

        except Exception as e:
            logger.error("Failed to extract video info for %s: %s", url, e, exc_info=True)
            raise
