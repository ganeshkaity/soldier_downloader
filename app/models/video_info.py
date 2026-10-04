"""VideoInfo model representing parsed metadata and available streams."""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional
from app.models.format_info import FormatInfo
from app.utils.formatters import format_bytes, format_count, format_duration


@dataclass
class VideoInfo:
    video_id: str
    title: str
    url: str
    duration: int = 0
    channel: str = "Unknown"
    thumbnail_url: str = ""
    view_count: Optional[int] = None
    upload_date: Optional[str] = None
    description: Optional[str] = None
    is_short: bool = False
    formats: List[FormatInfo] = field(default_factory=list)
    estimated_size: Optional[int] = None

    @property
    def duration_str(self) -> str:
        return format_duration(self.duration)

    @property
    def view_count_str(self) -> str:
        return format_count(self.view_count)

    @property
    def estimated_size_str(self) -> str:
        if self.estimated_size and self.estimated_size > 0:
            return format_bytes(self.estimated_size)
        return "Unknown size"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "video_id": self.video_id,
            "title": self.title,
            "url": self.url,
            "duration": self.duration,
            "duration_str": self.duration_str,
            "channel": self.channel,
            "thumbnail_url": self.thumbnail_url,
            "view_count": self.view_count or 0,
            "view_count_str": self.view_count_str,
            "upload_date": self.upload_date or "",
            "description": self.description or "",
            "is_short": self.is_short,
            "estimated_size": self.estimated_size or 0,
            "estimated_size_str": self.estimated_size_str,
            "formats": [f.to_dict() for f in self.formats],
        }
