"""Formatting utilities for file sizes, duration, transfer speed, and ETA."""

import math
from typing import Optional, Union


def format_bytes(num_bytes: Optional[Union[int, float]]) -> str:
    """Format bytes into human-readable string (B, KB, MB, GB)."""
    if num_bytes is None or num_bytes < 0:
        return "0 B"
    if num_bytes == 0:
        return "0 B"

    units = ["B", "KB", "MB", "GB", "TB"]
    i = int(math.floor(math.log(num_bytes, 1024)))
    i = min(i, len(units) - 1)
    p = math.pow(1024, i)
    s = round(num_bytes / p, 2)
    return f"{s} {units[i]}"


def format_speed(bytes_per_sec: Optional[Union[int, float]]) -> str:
    """Format speed in bytes/sec to human readable speed string (e.g., '12.4 MB/s')."""
    if not bytes_per_sec or bytes_per_sec <= 0:
        return "—"
    return f"{format_bytes(bytes_per_sec)}/s"


def format_duration(seconds: Optional[Union[int, float]]) -> str:
    """Format duration in seconds to MM:SS or HH:MM:SS."""
    if not seconds or seconds < 0:
        return "00:00"
    
    total_sec = int(round(seconds))
    hrs = total_sec // 3600
    mins = (total_sec % 3600) // 60
    secs = total_sec % 60
    
    if hrs > 0:
        return f"{hrs:02d}:{mins:02d}:{secs:02d}"
    return f"{mins:02d}:{secs:02d}"


def format_eta(seconds: Optional[Union[int, float]]) -> str:
    """Format ETA in seconds into a clean countdown string."""
    if seconds is None or seconds < 0:
        return "—"
    total_sec = int(round(seconds))
    if total_sec > 86400 * 3:
        return ">3 days"
    return format_duration(total_sec)


def format_count(count: Optional[Union[int, float]]) -> str:
    """Format large numbers such as view count (e.g., 1.5M, 230K)."""
    if count is None:
        return "—"
    n = float(count)
    if n >= 1_000_000_000:
        return f"{n / 1_000_000_000:.1f}B"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(int(n))
