"""Unit tests for URL validation, categorization, and input classification."""

import pytest
from app.utils.validators import (
    classify_input,
    extract_playlist_id,
    extract_video_id,
    is_youtube_playlist,
    is_youtube_shorts,
    is_youtube_url,
    normalize_youtube_url,
)


def test_standard_watch_url():
    url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    assert is_youtube_url(url) is True
    assert is_youtube_shorts(url) is False
    assert is_youtube_playlist(url) is False
    assert extract_video_id(url) == "dQw4w9WgXcQ"
    assert normalize_youtube_url(url) == "https://www.youtube.com/watch?v=dQw4w9WgXcQ"


def test_short_url_youtu_be():
    url = "https://youtu.be/dQw4w9WgXcQ"
    assert is_youtube_url(url) is True
    assert extract_video_id(url) == "dQw4w9WgXcQ"
    assert normalize_youtube_url(url) == "https://www.youtube.com/watch?v=dQw4w9WgXcQ"


def test_youtube_shorts_url():
    url = "https://www.youtube.com/shorts/dQw4w9WgXcQ"
    assert is_youtube_url(url) is True
    assert is_youtube_shorts(url) is True
    assert extract_video_id(url) == "dQw4w9WgXcQ"
    assert normalize_youtube_url(url) == "https://www.youtube.com/shorts/dQw4w9WgXcQ"


def test_playlist_url():
    url = "https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"
    assert is_youtube_url(url) is True
    assert is_youtube_playlist(url) is True
    assert extract_playlist_id(url) == "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"


def test_raw_11_char_id():
    raw_id = "dQw4w9WgXcQ"
    assert is_youtube_url(raw_id) is True
    assert extract_video_id(raw_id) == "dQw4w9WgXcQ"


def test_classify_input():
    # URL input
    k1, val1 = classify_input("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert k1 == "url"
    assert "dQw4w9WgXcQ" in val1

    # Search query input
    k2, val2 = classify_input("Python programming tutorial for beginners")
    assert k2 == "search"
    assert val2 == "Python programming tutorial for beginners"

    # Empty
    k3, val3 = classify_input("   ")
    assert k3 == "empty"
