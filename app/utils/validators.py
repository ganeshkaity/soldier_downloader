"""URL validation and extraction utilities for YouTube media."""

import re
from typing import Optional, Tuple
from urllib.parse import parse_qs, urlparse

# Regular expressions for matching various YouTube URL formats
YOUTUBE_WATCH_REGEX = re.compile(
    r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|live\/)|youtu\.be\/)([\w-]{11})',
    re.IGNORECASE
)

YOUTUBE_SHORTS_REGEX = re.compile(
    r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/shorts\/([\w-]{11})',
    re.IGNORECASE
)

YOUTUBE_PLAYLIST_REGEX = re.compile(
    r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/(?:playlist\?|watch\?.*)list=([a-zA-Z0-9_-]+)',
    re.IGNORECASE
)

RAW_VIDEO_ID_REGEX = re.compile(r'^[\w-]{11}$')


def is_youtube_url(url: str) -> bool:
    """Return True if string is a valid YouTube URL or raw ID."""
    if not url or not url.strip():
        return False
    u = url.strip()
    return bool(
        YOUTUBE_WATCH_REGEX.search(u)
        or YOUTUBE_SHORTS_REGEX.search(u)
        or YOUTUBE_PLAYLIST_REGEX.search(u)
        or RAW_VIDEO_ID_REGEX.match(u)
    )


def is_youtube_shorts(url: str) -> bool:
    """Return True if URL is a YouTube Shorts URL."""
    if not url:
        return False
    return bool(YOUTUBE_SHORTS_REGEX.search(url.strip()))


def is_youtube_playlist(url: str) -> bool:
    """Return True if URL contains a playlist parameter."""
    if not url:
        return False
    return bool(YOUTUBE_PLAYLIST_REGEX.search(url.strip()))


def extract_video_id(url: str) -> Optional[str]:
    """Extract 11-character video ID from URL or raw ID string."""
    if not url:
        return None
    u = url.strip()
    
    shorts_match = YOUTUBE_SHORTS_REGEX.search(u)
    if shorts_match:
        return shorts_match.group(1)
        
    watch_match = YOUTUBE_WATCH_REGEX.search(u)
    if watch_match:
        return watch_match.group(1)
        
    if RAW_VIDEO_ID_REGEX.match(u):
        return u
        
    return None


def extract_playlist_id(url: str) -> Optional[str]:
    """Extract playlist ID from URL."""
    if not url:
        return None
    match = YOUTUBE_PLAYLIST_REGEX.search(url.strip())
    if match:
        return match.group(1)
    return None


def normalize_youtube_url(url_or_id: str) -> str:
    """Normalize video ID or short URL into a standard canonical YouTube URL."""
    if not url_or_id:
        return ""
    u = url_or_id.strip()
    
    # Check if playlist
    if is_youtube_playlist(u):
        pl_id = extract_playlist_id(u)
        if pl_id:
            return f"https://www.youtube.com/playlist?list={pl_id}"
            
    # Check if shorts
    if is_youtube_shorts(u):
        v_id = extract_video_id(u)
        if v_id:
            return f"https://www.youtube.com/shorts/{v_id}"
            
    # Check if video
    v_id = extract_video_id(u)
    if v_id:
        return f"https://www.youtube.com/watch?v={v_id}"
        
    return u


def classify_input(text: str) -> Tuple[str, str]:
    """
    Classify a string into ('url'|'search', normalized_content).
    Returns (item_type, resolved_query_or_url).
    """
    cleaned = text.strip()
    if not cleaned:
        return ("empty", "")
        
    if is_youtube_url(cleaned):
        return ("url", normalize_youtube_url(cleaned))
        
    # Check if it looks like a generic web URL
    parsed = urlparse(cleaned)
    if parsed.scheme in ("http", "https") and parsed.netloc:
        return ("url", cleaned)
        
    return ("search", cleaned)
