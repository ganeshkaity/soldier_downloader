"""Search service querying YouTube via yt-dlp search."""

from typing import List
import yt_dlp

from app.constants import DEFAULT_SEARCH_LIMIT
from app.models.search_result import SearchResult
from app.services.yt_dlp_service import YtDlpService
from app.utils.logger import get_logger

logger = get_logger()


class SearchService:
    """Performs YouTube text searches without downloading media."""

    @classmethod
    def search(cls, query: str, limit: int = DEFAULT_SEARCH_LIMIT) -> List[SearchResult]:
        """
        Execute search query and return list of SearchResult models.
        Must be executed outside the GUI thread.
        """
        cleaned_query = query.strip()
        if not cleaned_query:
            return []

        search_target = f"ytsearch{limit}:{cleaned_query}"
        opts = YtDlpService.get_base_ydl_opts({
            "extract_flat": True,
            "skip_download": True,
        })

        results: List[SearchResult] = []
        try:
            with yt_dlp.YoutubeDL(opts) as ydl:
                data = ydl.extract_info(search_target, download=False)
                if not data or "entries" not in data:
                    return []

                for entry in data.get("entries", []):
                    if not entry:
                        continue
                    video_id = str(entry.get("id", ""))
                    if not video_id:
                        continue

                    title = str(entry.get("title", "Untitled"))
                    channel = str(entry.get("uploader") or entry.get("channel") or "Unknown")
                    duration = int(entry.get("duration") or 0)
                    view_count = entry.get("view_count")
                    upload_date = str(entry.get("upload_date") or "")
                    
                    # Resolve thumbnail
                    thumbnails = entry.get("thumbnails", [])
                    thumbnail_url = ""
                    if thumbnails:
                        thumbnail_url = thumbnails[-1].get("url", "")
                    elif entry.get("thumbnail"):
                        thumbnail_url = entry.get("thumbnail")
                    else:
                        thumbnail_url = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

                    url = f"https://www.youtube.com/watch?v={video_id}"

                    results.append(SearchResult(
                        video_id=video_id,
                        title=title,
                        url=url,
                        channel=channel,
                        duration=duration,
                        thumbnail_url=thumbnail_url,
                        view_count=int(view_count) if view_count else None,
                        upload_date=upload_date,
                    ))

            logger.info("Search '%s' returned %d results", cleaned_query, len(results))
            return results

        except Exception as e:
            logger.error("Failed executing search for '%s': %s", cleaned_query, e, exc_info=True)
            raise
