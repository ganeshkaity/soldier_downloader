"""Unit tests for semantic format selectors and postprocessor builders."""

import pytest
from app.models.download_config import DownloadConfig
from app.services.format_service import FormatService


def test_best_video_selector():
    cfg = DownloadConfig(
        url="https://youtube.com/watch?v=test",
        video_id="test",
        title="Test Video",
        media_type="video",
        quality_mode="Best",
        output_format="MP4",
    )
    selector = FormatService.build_format_selector(cfg)
    assert selector == "bestvideo+bestaudio/best"


def test_1080p_resolution_selector():
    cfg = DownloadConfig(
        url="https://youtube.com/watch?v=test",
        video_id="test",
        title="Test Video",
        media_type="video",
        quality_mode="1080p",
        output_format="MP4",
    )
    selector = FormatService.build_format_selector(cfg)
    assert "height<=?1080" in selector


def test_audio_format_selector():
    cfg = DownloadConfig(
        url="https://youtube.com/watch?v=test",
        video_id="test",
        title="Test Audio",
        media_type="audio",
        output_format="MP3",
    )
    selector = FormatService.build_format_selector(cfg)
    assert selector == "bestaudio/best"

    pps = FormatService.build_postprocessors(cfg)
    # Check that FFmpegExtractAudio is configured with mp3
    extract_audio_pp = [p for p in pps if p.get("key") == "FFmpegExtractAudio"]
    assert len(extract_audio_pp) == 1
    assert extract_audio_pp[0]["preferredcodec"] == "mp3"


def test_explicit_format_ids():
    cfg = DownloadConfig(
        url="https://youtube.com/watch?v=test",
        video_id="test",
        title="Custom Format Video",
        media_type="video",
        video_format_id="137",
        audio_format_id="140",
    )
    selector = FormatService.build_format_selector(cfg)
    assert selector == "137+140"
