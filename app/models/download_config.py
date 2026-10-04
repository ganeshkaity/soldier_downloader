"""Download configuration model encapsulating user choices."""

from dataclasses import dataclass
from typing import Any, Dict, Optional
from app.constants import DEFAULT_DOWNLOAD_DIR


@dataclass
class DownloadConfig:
    url: str
    video_id: str = ""
    title: str = ""
    thumbnail_url: str = ""
    media_type: str = "video"           # "video" or "audio"
    quality_mode: str = "Best"          # "Best", "1080p", "720p", etc. or "Custom"
    output_format: str = "MP4"          # "MP4", "MKV", "MP3", "M4A", etc.
    format_selector: str = "bestvideo+bestaudio/best"
    video_format_id: Optional[str] = None
    audio_format_id: Optional[str] = None
    destination_dir: str = DEFAULT_DOWNLOAD_DIR
    filename: Optional[str] = None
    embed_metadata: bool = True
    embed_thumbnail: bool = False       # True for audio by default, False for video
    duplicate_mode: str = "Skip"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "url": self.url,
            "video_id": self.video_id,
            "title": self.title,
            "thumbnail_url": self.thumbnail_url,
            "media_type": self.media_type,
            "quality_mode": self.quality_mode,
            "output_format": self.output_format,
            "format_selector": self.format_selector,
            "video_format_id": self.video_format_id,
            "audio_format_id": self.audio_format_id,
            "destination_dir": self.destination_dir,
            "filename": self.filename,
            "embed_metadata": self.embed_metadata,
            "embed_thumbnail": self.embed_thumbnail,
            "duplicate_mode": self.duplicate_mode,
        }
