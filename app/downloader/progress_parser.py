"""Parser for yt-dlp progress hooks and post-processing event tracking."""

import time
from typing import Any, Dict, Optional, Tuple

from app.constants import DownloadStatus
from app.utils.formatters import format_bytes, format_duration, format_eta, format_speed


class ProgressParser:
    """Parses raw progress hook dictionaries from yt-dlp into standardized UI metrics."""

    def __init__(self):
        self.last_update_time = 0.0
        self.downloaded_bytes = 0
        self.total_bytes = 0
        self.speed = 0.0
        self.eta = 0.0
        self.percent = 0.0
        self.status = DownloadStatus.QUEUED

    def parse_hook(self, d: Dict[str, Any]) -> Tuple[float, str, str, int, int, str]:
        """
        Parse hook dict and return:
        (percent, speed_str, eta_str, downloaded_bytes, total_bytes, status_text)
        """
        hook_status = d.get("status")
        now = time.time()

        if hook_status == "downloading":
            self.status = DownloadStatus.DOWNLOADING
            downloaded = d.get("downloaded_bytes") or 0
            total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0

            self.downloaded_bytes = downloaded
            self.total_bytes = total

            if total > 0:
                self.percent = min(100.0, max(0.0, (downloaded / total) * 100.0))
            else:
                self.percent = 0.0

            # Speed
            raw_speed = d.get("speed")
            if raw_speed and raw_speed > 0:
                self.speed = float(raw_speed)

            # ETA
            raw_eta = d.get("eta")
            if raw_eta is not None and raw_eta >= 0:
                self.eta = float(raw_eta)

            status_text = DownloadStatus.DOWNLOADING

        elif hook_status == "finished":
            self.status = DownloadStatus.MERGING
            self.percent = 100.0
            status_text = "Processing..."
        elif hook_status == "error":
            self.status = DownloadStatus.FAILED
            status_text = DownloadStatus.FAILED
        else:
            status_text = str(hook_status or "Processing")

        speed_str = format_speed(self.speed) if self.status == DownloadStatus.DOWNLOADING else "—"
        eta_str = format_eta(self.eta) if self.status == DownloadStatus.DOWNLOADING else "—"

        return (
            self.percent,
            speed_str,
            eta_str,
            self.downloaded_bytes,
            self.total_bytes,
            status_text
        )
