"""Format selection, conversion strategies, and yt-dlp option builders."""

from typing import Any, Dict, List, Optional
from app.models.download_config import DownloadConfig
from app.models.format_info import FormatInfo
from app.utils.logger import get_logger

logger = get_logger()

# Map resolution labels to pixel heights
RESOLUTION_HEIGHT_MAP = {
    "2160p": 2160,
    "1440p": 1440,
    "1080p": 1080,
    "720p": 720,
    "480p": 480,
    "360p": 360,
}


class FormatService:
    """Provides semantic format selectors and post-processing pipeline configurations."""

    @staticmethod
    def parse_format_dict(raw: Dict[str, Any]) -> FormatInfo:
        """Parse raw yt-dlp format dictionary into structured FormatInfo model."""
        fid = str(raw.get("format_id", ""))
        ext = raw.get("ext", "")
        vcodec = raw.get("vcodec", "none") or "none"
        acodec = raw.get("acodec", "none") or "none"
        height = int(raw.get("height") or 0)
        width = int(raw.get("width") or 0)
        fps = raw.get("fps")
        filesize = raw.get("filesize") or raw.get("filesize_approx")
        tbr = raw.get("tbr")
        abr = raw.get("abr")
        vbr = raw.get("vbr")
        note = raw.get("format_note", "")

        has_v = vcodec != "none" and height > 0
        has_a = acodec != "none"

        if has_v and has_a:
            fmt_type = "combined"
            resolution = f"{height}p" if height > 0 else (raw.get("resolution") or "combined")
        elif has_v:
            fmt_type = "video"
            resolution = f"{height}p" if height > 0 else (raw.get("resolution") or "video only")
        elif has_a:
            fmt_type = "audio"
            resolution = f"{int(abr)} kbps" if abr else "audio only"
        else:
            fmt_type = "other"
            resolution = raw.get("resolution") or "other"

        return FormatInfo(
            format_id=fid,
            format_type=fmt_type,
            ext=ext,
            resolution=resolution,
            height=height,
            width=width,
            fps=int(fps) if fps else None,
            vcodec=vcodec,
            acodec=acodec,
            filesize=int(filesize) if filesize else None,
            tbr=float(tbr) if tbr else None,
            abr=float(abr) if abr else None,
            vbr=float(vbr) if vbr else None,
            note=note,
        )

    @classmethod
    def build_format_selector(cls, config: DownloadConfig) -> str:
        """
        Build the optimal yt-dlp format string based on media type,
        requested quality, and explicit format selections.
        """
        if config.media_type == "audio":
            return "bestaudio/best"

        # Explicit custom format selection
        if config.video_format_id:
            if config.audio_format_id:
                return f"{config.video_format_id}+{config.audio_format_id}"
            # Single stream selected; if it's video-only, automatically pair with best audio
            return f"{config.video_format_id}+bestaudio/best"

        # Quality presets
        q = config.quality_mode
        if q == "Best" or q not in RESOLUTION_HEIGHT_MAP:
            # Best video + best audio fallback to best
            return "bestvideo+bestaudio/best"

        # Resolution capped preset (e.g., 1080p, 720p)
        max_h = RESOLUTION_HEIGHT_MAP[q]
        return f"bestvideo[height<=?{max_h}]+bestaudio/best[height<=?{max_h}]/best"

    @classmethod
    def build_postprocessors(cls, config: DownloadConfig) -> List[Dict[str, Any]]:
        """
        Build yt-dlp postprocessors for audio extraction, conversion, metadata, and artwork.
        """
        postprocessors: List[Dict[str, Any]] = []

        if config.media_type == "audio":
            target_codec = config.output_format.lower()
            if target_codec in ["best", "best audio"]:
                # If best audio is requested, extract audio preserving source container/codec
                postprocessors.append({
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "best",
                })
            else:
                postprocessors.append({
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": target_codec,
                    "preferredquality": "0",  # Highest VBR quality
                })

            # Embed metadata
            if config.embed_metadata:
                postprocessors.append({"key": "FFmpegMetadata"})

            # Embed thumbnail into audio
            if config.embed_thumbnail:
                postprocessors.append({"key": "EmbedThumbnail"})

        else:
            # Video downloads
            if config.embed_metadata:
                postprocessors.append({"key": "FFmpegMetadata"})

            # NOTE: Rule 14 specifies: Do NOT embed thumbnails into video downloads by default.
            if config.embed_thumbnail:
                postprocessors.append({"key": "EmbedThumbnail"})

        return postprocessors

    @classmethod
    def get_merge_output_format(cls, config: DownloadConfig) -> Optional[str]:
        """Return the target container for merging separate video/audio streams."""
        if config.media_type == "video":
            container = config.output_format.lower()
            if container in ["mp4", "mkv", "webm"]:
                return container
            return "mp4"
        return None
