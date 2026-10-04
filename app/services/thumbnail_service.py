"""Thumbnail retrieval and saving service."""

import os
import urllib.request
from pathlib import Path
from typing import Optional, Tuple
from urllib.parse import urlparse

from app.services.yt_dlp_service import YtDlpService
from app.utils.filename import resolve_unique_path, sanitize_filename
from app.utils.logger import get_logger
from app.utils.paths import get_default_download_dir

logger = get_logger()


class ThumbnailService:
    """Service to download standalone YouTube thumbnails."""

    @classmethod
    def download_thumbnail(
        cls,
        thumbnail_url: str,
        title: str,
        destination_dir: Optional[str] = None
    ) -> Tuple[bool, str]:
        """
        Download a thumbnail from URL and save it to the destination directory.
        Returns (success, saved_file_path_or_error).
        """
        if not thumbnail_url:
            return (False, "Thumbnail URL is missing.")

        save_dir = Path(destination_dir) if destination_dir else get_default_download_dir()
        save_dir.mkdir(parents=True, exist_ok=True)

        # Detect extension from URL or default to .jpg
        parsed = urlparse(thumbnail_url)
        path_lower = parsed.path.lower()
        if path_lower.endswith(".webp"):
            ext = ".webp"
        elif path_lower.endswith(".png"):
            ext = ".png"
        else:
            ext = ".jpg"

        clean_title = sanitize_filename(title or "thumbnail")
        target_path = resolve_unique_path(save_dir, clean_title, ext)

        try:
            req = urllib.request.Request(
                thumbnail_url,
                headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
            )
            with urllib.request.urlopen(req, timeout=15) as response, open(target_path, "wb") as out_file:
                out_file.write(response.read())

            logger.info("Thumbnail saved successfully to %s", target_path)
            return (True, str(target_path))

        except Exception as e:
            logger.error("Failed downloading thumbnail: %s", e, exc_info=True)
            return (False, f"Download failed: {str(e)}")
