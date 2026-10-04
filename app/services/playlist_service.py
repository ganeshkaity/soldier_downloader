"""Playlist extraction and entry manipulation service."""

from typing import Any, Dict, List, Optional
import yt_dlp

from app.models.playlist_info import PlaylistInfo
from app.models.video_info import VideoInfo
from app.services.yt_dlp_service import YtDlpService
from app.utils.logger import get_logger

logger = get_logger()


class PlaylistService:
    """Extracts playlist information and lightweight entry models."""

    @classmethod
    def extract_playlist(cls, url: str) -> PlaylistInfo:
        """
        Extract playlist metadata and flat entries without downloading or extracting
        heavy format objects for every entry.
        Must be called outside GUI thread.
        """
        opts = YtDlpService.get_base_ydl_opts({
            "extract_flat": "in_advance",
            "skip_download": True,
        })

        try:
            with yt_dlp.YoutubeDL(opts) as ydl:
                data = ydl.extract_info(url, download=False)
                if not data:
                    raise ValueError("No playlist data returned from URL.")

                playlist_id = str(data.get("id", ""))
                title = str(data.get("title", "Untitled Playlist"))
                playlist_url = str(data.get("webpage_url") or url)

                entries_data = data.get("entries", [])
                entries: List[VideoInfo] = []

                thumbnail_url = str(data.get("thumbnail") or "")

                for entry in entries_data:
                    if not entry:
                        continue
                    v_id = str(entry.get("id", ""))
                    if not v_id:
                        continue

                    v_title = str(entry.get("title", "Untitled Video"))
                    v_duration = int(entry.get("duration") or 0)
                    v_channel = str(entry.get("uploader") or entry.get("channel") or "Unknown")
                    
                    # Resolve thumbnail
                    v_thumb = ""
                    thumbnails = entry.get("thumbnails", [])
                    if thumbnails:
                        v_thumb = thumbnails[-1].get("url", "")
                    elif entry.get("thumbnail"):
                        v_thumb = entry.get("thumbnail")
                    else:
                        v_thumb = f"https://i.ytimg.com/vi/{v_id}/hqdefault.jpg"

                    if not thumbnail_url and v_thumb:
                        thumbnail_url = v_thumb

                    v_url = f"https://www.youtube.com/watch?v={v_id}"

                    entries.append(VideoInfo(
                        video_id=v_id,
                        title=v_title,
                        url=v_url,
                        duration=v_duration,
                        channel=v_channel,
                        thumbnail_url=v_thumb,
                    ))

                logger.info("Playlist '%s' extracted with %d entries", title, len(entries))

                return PlaylistInfo(
                    playlist_id=playlist_id,
                    title=title,
                    url=playlist_url,
                    thumbnail_url=thumbnail_url,
                    entry_count=len(entries),
                    entries=entries,
                )

        except Exception as e:
            logger.error("Failed to extract playlist for %s: %s", url, e, exc_info=True)
            raise

    @staticmethod
    def calculate_range_selection(total: int, start: int, end: int) -> List[int]:
        """
        Calculate 0-based indices for a 1-based [start, end] range.
        Ensures 1 <= start <= end <= total.
        """
        if total <= 0:
            return []
        
        valid_start = max(1, min(start, total))
        valid_end = max(valid_start, min(end, total))

        return list(range(valid_start - 1, valid_end))

    @staticmethod
    def calculate_first_n_selection(total: int, n: int) -> List[int]:
        """Calculate 0-based indices for first N items."""
        count = max(0, min(n, total))
        return list(range(count))
