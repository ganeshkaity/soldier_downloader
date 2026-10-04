"""DownloadItem model representing an active, queued, or completed queue entry."""

import time
import uuid
from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from app.constants import DownloadStatus
from app.models.download_config import DownloadConfig
from app.utils.formatters import format_bytes


@dataclass
class DownloadItem:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    video_id: str = ""
    url: str = ""
    title: str = ""
    media_type: str = "video"
    quality: str = "Best"
    format: str = "MP4"
    status: str = DownloadStatus.QUEUED
    progress_percent: float = 0.0
    speed_str: str = "—"
    eta_str: str = "—"
    downloaded_bytes: int = 0
    total_bytes: int = 0
    destination_file: str = ""
    thumbnail_url: str = ""
    error_message: str = ""
    created_at: float = field(default_factory=time.time)
    completed_at: Optional[float] = None
    config: Optional[DownloadConfig] = None

    @property
    def downloaded_str(self) -> str:
        return format_bytes(self.downloaded_bytes)

    @property
    def total_str(self) -> str:
        return format_bytes(self.total_bytes) if self.total_bytes > 0 else "—"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "video_id": self.video_id,
            "url": self.url,
            "title": self.title,
            "media_type": self.media_type,
            "quality": self.quality,
            "format": self.format,
            "status": self.status,
            "progress_percent": round(self.progress_percent, 1),
            "speed_str": self.speed_str,
            "eta_str": self.eta_str,
            "downloaded_bytes": self.downloaded_bytes,
            "total_bytes": self.total_bytes,
            "downloaded_str": self.downloaded_str,
            "total_str": self.total_str,
            "destination_file": self.destination_file,
            "thumbnail_url": self.thumbnail_url,
            "error_message": self.error_message,
            "created_at": self.created_at,
            "completed_at": self.completed_at or 0.0,
            "config": self.config.to_dict() if self.config else {},
        }
