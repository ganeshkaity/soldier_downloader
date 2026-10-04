"""Format representation model for audio/video streams."""

from dataclasses import dataclass
from typing import Any, Dict, Optional
from app.utils.formatters import format_bytes


@dataclass
class FormatInfo:
    format_id: str
    format_type: str            # "video", "audio", "combined"
    ext: str
    resolution: str             # "1080p", "720p", "audio only", etc.
    height: int
    width: int
    fps: Optional[int] = None
    vcodec: str = "none"
    acodec: str = "none"
    filesize: Optional[int] = None
    tbr: Optional[float] = None
    abr: Optional[float] = None
    vbr: Optional[float] = None
    note: str = ""

    @property
    def has_video(self) -> bool:
        return self.vcodec != "none" and self.vcodec != "" and self.height > 0

    @property
    def has_audio(self) -> bool:
        return self.acodec != "none" and self.acodec != ""

    @property
    def filesize_str(self) -> str:
        if self.filesize and self.filesize > 0:
            return format_bytes(self.filesize)
        return "Unknown size"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "format_id": self.format_id,
            "format_type": self.format_type,
            "ext": self.ext,
            "resolution": self.resolution,
            "height": self.height,
            "width": self.width,
            "fps": self.fps or 0,
            "vcodec": self.vcodec,
            "acodec": self.acodec,
            "filesize": self.filesize or 0,
            "filesize_str": self.filesize_str,
            "tbr": round(self.tbr, 1) if self.tbr else 0.0,
            "abr": round(self.abr, 1) if self.abr else 0.0,
            "vbr": round(self.vbr, 1) if self.vbr else 0.0,
            "note": self.note,
            "has_video": self.has_video,
            "has_audio": self.has_audio,
        }
