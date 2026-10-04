"""Metadata extraction and post-processor configuration service."""

from typing import Any, Dict, Optional


class MetadataService:
    """Manages metadata policies and formatting for audio and video files."""

    @staticmethod
    def prepare_audio_metadata(info: Dict[str, Any]) -> Dict[str, str]:
        """
        Extract authentic audio metadata without fabricating nonexistent tags.
        """
        metadata: Dict[str, str] = {}

        title = info.get("title") or info.get("track")
        if title:
            metadata["title"] = str(title)

        artist = info.get("artist") or info.get("creator") or info.get("uploader") or info.get("channel")
        if artist:
            metadata["artist"] = str(artist)

        album = info.get("album")
        if album:
            metadata["album"] = str(album)

        return metadata
