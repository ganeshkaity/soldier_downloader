"""HistoryItem model representing stored records in local SQLite database."""

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional
from app.utils.formatters import format_bytes, format_duration


@dataclass
class HistoryItem:
    id: int
    video_id: str
    title: str
    url: str
    media_type: str
    output_format: str
    quality: str
    file_path: str
    file_size: int
    status: str
    date_time: str
    duration: int = 0
    thumbnail_url: str = ""
    error_message: str = ""

    @property
    def file_exists(self) -> bool:
        if not self.file_path:
            return False
        return Path(self.file_path).is_file()

    @property
    def file_size_str(self) -> str:
        return format_bytes(self.file_size)

    @property
    def duration_str(self) -> str:
        return format_duration(self.duration)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "video_id": self.video_id,
            "title": self.title,
            "url": self.url,
            "media_type": self.media_type,
            "output_format": self.output_format,
            "quality": self.quality,
            "file_path": self.file_path,
            "file_size": self.file_size,
            "file_size_str": self.file_size_str,
            "status": self.status,
            "date_time": self.date_time,
            "duration": self.duration,
            "duration_str": self.duration_str,
            "thumbnail_url": self.thumbnail_url,
            "error_message": self.error_message,
            "file_exists": self.file_exists,
        }
