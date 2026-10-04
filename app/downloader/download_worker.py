"""DownloadWorker executing single media download using yt-dlp in a background QThread."""

import os
import shutil
import time
from pathlib import Path
from typing import Any, Dict, Optional

from PySide6.QtCore import QObject, QThread, Signal

import yt_dlp
from app.constants import DownloadStatus
from app.downloader.progress_parser import ProgressParser
from app.models.download_config import DownloadConfig
from app.services.format_service import FormatService
from app.services.yt_dlp_service import YtDlpService, translate_error
from app.utils.filename import sanitize_filename
from app.utils.logger import get_logger
from app.utils.paths import get_cookies_path, get_temp_dir

logger = get_logger()


class DownloadCancelledException(Exception):
    """Raised when the user cancels an in-progress download."""
    pass


class DownloadWorker(QThread):
    """
    Independent worker thread for downloading a single YouTube video or audio.
    Maintains clean state, throttled progress updates, and clean cancellation.
    """

    # Signals: item_id, percent, speed_str, eta_str, downloaded_bytes, total_bytes, status_text
    progress_signal = Signal(str, float, str, str, int, int, str)
    status_signal = Signal(str, str)
    finished_signal = Signal(str, str, int)  # item_id, destination_file, file_size
    failed_signal = Signal(str, str, str)     # item_id, friendly_error, technical_details
    cancelled_signal = Signal(str)            # item_id

    def __init__(self, item_id: str, config: DownloadConfig, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.item_id = item_id
        self.config = config
        self._is_cancelled = False
        self._last_progress_emit = 0.0
        self._destination_file = ""
        self._progress_parser = ProgressParser()

    def cancel(self) -> None:
        """Signal this worker to stop downloading."""
        logger.info("Cancellation requested for worker [%s]", self.item_id)
        self._is_cancelled = True

    def _progress_hook(self, d: Dict[str, Any]) -> None:
        """Callback received from yt-dlp during download."""
        if self._is_cancelled:
            raise DownloadCancelledException("Download cancelled by user.")

        now = time.time()
        # Capture filename if available
        fn = d.get("filename")
        if fn and not self._destination_file:
            self._destination_file = str(fn)

        percent, speed_str, eta_str, down_b, total_b, status_text = self._progress_parser.parse_hook(d)

        # Throttle progress emissions to ~10 times per second to keep GUI light
        if now - self._last_progress_emit >= 0.1 or percent >= 100.0 or status_text != DownloadStatus.DOWNLOADING:
            self._last_progress_emit = now
            self.progress_signal.emit(
                self.item_id,
                percent,
                speed_str,
                eta_str,
                down_b,
                total_b,
                status_text
            )

    def _postprocessor_hook(self, d: Dict[str, Any]) -> None:
        """Callback received during post-processing (merging, converting, embedding)."""
        if self._is_cancelled:
            raise DownloadCancelledException("Download cancelled by user.")

        pp_status = d.get("status")
        postprocessor = d.get("postprocessor", "")

        if pp_status == "started":
            status_text = "Processing..."
            if "ExtractAudio" in postprocessor:
                status_text = DownloadStatus.CONVERTING
            elif "Metadata" in postprocessor:
                status_text = DownloadStatus.EMBEDDING_METADATA
            elif "Merger" in postprocessor:
                status_text = DownloadStatus.MERGING
            elif "EmbedThumbnail" in postprocessor:
                status_text = "Embedding Artwork..."

            self.status_signal.emit(self.item_id, status_text)
            self.progress_signal.emit(self.item_id, 100.0, "—", "—", 0, 0, status_text)

    def run(self) -> None:
        """Execute yt-dlp download in background thread."""
        logger.info("Starting download worker [%s] for %s", self.item_id, self.config.url)
        self.status_signal.emit(self.item_id, DownloadStatus.PREPARING)

        dest_dir = Path(self.config.destination_dir)
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Filename template:
        # Rule 23: Default filename: Original Video Title + extension
        # yt-dlp outtmpl: sanitized title
        clean_base = sanitize_filename(self.config.filename or self.config.title)
        outtmpl = str(dest_dir / f"{clean_base}.%(ext)s")

        format_selector = FormatService.build_format_selector(self.config)
        postprocessors = FormatService.build_postprocessors(self.config)
        merge_container = FormatService.get_merge_output_format(self.config)

        ydl_opts: Dict[str, Any] = {
            "outtmpl": outtmpl,
            "format": format_selector,
            "progress_hooks": [self._progress_hook],
            "postprocessor_hooks": [self._postprocessor_hook],
            "quiet": True,
            "no_warnings": True,
            "nocheckcertificate": False,
            "noplaylist": True,
            "cachedir": str(get_temp_dir() / "ytdlp_cache"),
            "windowsfilenames": True,
        }

        # Cookies
        cookies_path = get_cookies_path()
        if cookies_path and cookies_path.is_file():
            ydl_opts["cookiefile"] = str(cookies_path)

        # Merge format for video
        if merge_container and self.config.media_type == "video":
            ydl_opts["merge_output_format"] = merge_container

        # Postprocessors
        if postprocessors:
            ydl_opts["postprocessors"] = postprocessors

        # Embed thumbnail artwork for audio: yt-dlp requires writethumbnail=True to embed it
        if self.config.embed_thumbnail and self.config.media_type == "audio":
            ydl_opts["writethumbnail"] = True

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                if self._is_cancelled:
                    raise DownloadCancelledException("Cancelled before starting.")

                self.status_signal.emit(self.item_id, DownloadStatus.DOWNLOADING)
                info = ydl.extract_info(self.config.url, download=True)
                
                if self._is_cancelled:
                    raise DownloadCancelledException("Cancelled during download.")

                # Determine final file path
                final_file = ""
                file_size = 0
                if info:
                    # yt-dlp often records requested_downloads with filepath
                    req_dl = info.get("requested_downloads")
                    if req_dl and isinstance(req_dl, list) and req_dl[0].get("filepath"):
                        final_file = req_dl[0].get("filepath")
                    elif info.get("_filename"):
                        final_file = info.get("_filename")

                # Fallback to checking destination folder for matching basename
                if not final_file or not Path(final_file).is_file():
                    candidates = list(dest_dir.glob(f"{clean_base}.*"))
                    # Filter out .part or temporary files
                    valid = [c for c in candidates if not c.name.endswith(".part") and not c.name.endswith(".ytdl")]
                    if valid:
                        final_file = str(valid[0])

                if final_file and Path(final_file).is_file():
                    file_size = Path(final_file).stat().st_size

                logger.info("Worker [%s] completed successfully: %s (%d bytes)", self.item_id, final_file, file_size)
                self.status_signal.emit(self.item_id, DownloadStatus.COMPLETED)
                self.finished_signal.emit(self.item_id, final_file, file_size)

        except DownloadCancelledException:
            logger.info("Worker [%s] cancelled.", self.item_id)
            self._cleanup_partial_files(dest_dir, clean_base)
            self.status_signal.emit(self.item_id, DownloadStatus.CANCELLED)
            self.cancelled_signal.emit(self.item_id)

        except Exception as e:
            if self._is_cancelled:
                logger.info("Worker [%s] cancelled during exception.", self.item_id)
                self._cleanup_partial_files(dest_dir, clean_base)
                self.status_signal.emit(self.item_id, DownloadStatus.CANCELLED)
                self.cancelled_signal.emit(self.item_id)
                return

            logger.error("Worker [%s] failed: %s", self.item_id, e, exc_info=True)
            friendly_err, tech_details = translate_error(e)
            self.status_signal.emit(self.item_id, DownloadStatus.FAILED)
            self.failed_signal.emit(self.item_id, friendly_err, tech_details)

    def _cleanup_partial_files(self, dest_dir: Path, base_name: str) -> None:
        """Clean up incomplete .part and .temp files on cancellation."""
        try:
            for part in dest_dir.glob(f"{base_name}.*.part"):
                try:
                    part.unlink(missing_ok=True)
                except Exception:
                    pass
            for ytdl in dest_dir.glob(f"{base_name}.*.ytdl"):
                try:
                    ytdl.unlink(missing_ok=True)
                except Exception:
                    pass
        except Exception as e:
            logger.warning("Error cleaning temporary files: %s", e)
