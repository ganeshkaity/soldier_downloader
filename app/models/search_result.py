"""SearchResult model representing items returned from YouTube search."""

from dataclasses import dataclass
from typing import Any, Dict, Optional
from app.utils.formatters import format_count, format_duration


@dataclass
class SearchResult:
    video_id: str
    title: str
    url: str
    channel: str = "Unknown"
    duration: int = 0
    thumbnail_url: str = ""
    view_count: Optional[int] = None
    upload_date: Optional[str] = None

    @property
    def duration_str(self) -> str:
        return format_duration(self.duration)

    @property
    def view_count_str(self) -> str:
        return format_count(self.view_count)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "video_id": self.video_id,
            "title": self.title,
            "url": self.url,
            "channel": self.channel,
            "duration": self.duration,
            "duration_str": self.duration_str,
            "thumbnail_url": self.thumbnail_url,
            "view_count": self.view_count or 0,
            "view_count_str": self.view_count_str,
            "upload_date": self.upload_date or "",
        }
