"""PlaylistInfo model representing playlist metadata and its entries."""

from dataclasses import dataclass, field
from typing import Any, Dict, List
from app.models.video_info import VideoInfo


@dataclass
class PlaylistInfo:
    playlist_id: str
    title: str
    url: str
    thumbnail_url: str = ""
    entry_count: int = 0
    entries: List[VideoInfo] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "playlist_id": self.playlist_id,
            "title": self.title,
            "url": self.url,
            "thumbnail_url": self.thumbnail_url,
            "entry_count": self.entry_count,
            "entries": [entry.to_dict() for entry in self.entries],
        }
