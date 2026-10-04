"""Application-wide constants for Soldier Downloader."""

import os
from pathlib import Path

APP_NAME = "Soldier Downloader"
APP_VERSION = "0.1.0"
APP_DESCRIPTION = "Local YouTube media downloader for Windows"

# Concurrency limits
DEFAULT_CONCURRENT_DOWNLOADS = 5
MIN_CONCURRENT_DOWNLOADS = 1
MAX_CONCURRENT_DOWNLOADS = 10

# Default paths
DEFAULT_DOWNLOAD_DIR = str(Path.home() / "Downloads" / "Soldiers")

# Presets and options
VIDEO_QUALITY_PRESETS = [
    "Best",
    "2160p",
    "1440p",
    "1080p",
    "720p",
    "480p",
    "360p",
]

AUDIO_FORMAT_OPTIONS = [
    "Best Audio",
    "MP3",
    "M4A",
    "FLAC",
    "OPUS",
    "WAV",
    "AAC",
    "VORBIS",
    "ALAC",
]

VIDEO_CONTAINER_OPTIONS = [
    "MP4",
    "WebM",
    "MKV",
]

DUPLICATE_BEHAVIORS = [
    "Skip",        # Default: skip downloading if already exists
    "Ask",         # Ask user
    "Overwrite",   # Overwrite existing file
]

CLOSE_BEHAVIORS = [
    "Minimize to tray",
    "Exit application",
    "Ask",
]

# Download item lifecycle statuses
class DownloadStatus:
    QUEUED = "Queued"
    PREPARING = "Preparing"
    EXTRACTING = "Extracting"
    DOWNLOADING = "Downloading"
    MERGING = "Merging"
    CONVERTING = "Converting"
    EMBEDDING_METADATA = "Embedding Metadata"
    COMPLETED = "Completed"
    CANCELLED = "Cancelled"
    FAILED = "Failed"

# Search max results
DEFAULT_SEARCH_LIMIT = 20
