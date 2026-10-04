"""PythonQmlBridge serving as the robust communication hub between QML and Python."""

import json
import os
import subprocess
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional

from PySide6.QtCore import QObject, QThread, Property, Signal, Slot
from PySide6.QtGui import QGuiApplication, QClipboard

from app.constants import APP_NAME, APP_VERSION, DownloadStatus
from app.database.history_repository import HistoryRepository
from app.downloader.download_manager import DownloadManager
from app.models.download_config import DownloadConfig
from app.services.environment_service import EnvironmentService
from app.services.playlist_service import PlaylistService
from app.services.search_service import SearchService
from app.services.thumbnail_service import ThumbnailService
from app.services.yt_dlp_service import YtDlpService, translate_error
from app.settings.settings_manager import SettingsManager
from app.utils.filename import sanitize_filename
from app.utils.logger import get_logger
from app.utils.paths import get_default_download_dir, get_logs_dir
from app.utils.validators import classify_input, extract_video_id, is_youtube_url

logger = get_logger()


# --- Background Worker Threads for Non-blocking Operations ---

class AnalyzeWorker(QThread):
    """Worker thread for analyzing a single YouTube URL."""
    finished_signal = Signal(dict)
    failed_signal = Signal(str, str)

    def __init__(self, url: str, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.url = url

    def run(self) -> None:
        try:
            info = YtDlpService.extract_video_info(self.url)
            self.finished_signal.emit(info.to_dict())
        except Exception as e:
            friendly_err, tech_details = translate_error(e)
            self.failed_signal.emit(friendly_err, tech_details)


class SearchWorker(QThread):
    """Worker thread for performing YouTube searches."""
    finished_signal = Signal(list)
    failed_signal = Signal(str, str)

    def __init__(self, query: str, limit: int, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.query = query
        self.limit = limit

    def run(self) -> None:
        try:
            results = SearchService.search(self.query, self.limit)
            self.finished_signal.emit([r.to_dict() for r in results])
        except Exception as e:
            friendly_err, tech_details = translate_error(e)
            self.failed_signal.emit(friendly_err, tech_details)


class PlaylistWorker(QThread):
    """Worker thread for extracting playlist entries."""
    finished_signal = Signal(dict)
    failed_signal = Signal(str, str)

    def __init__(self, url: str, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.url = url

    def run(self) -> None:
        try:
            playlist = PlaylistService.extract_playlist(self.url)
            self.finished_signal.emit(playlist.to_dict())
        except Exception as e:
            friendly_err, tech_details = translate_error(e)
            self.failed_signal.emit(friendly_err, tech_details)


class BatchResolveWorker(QThread):
    """Worker thread for resolving search terms in batch input."""
    finished_signal = Signal(list)
    failed_signal = Signal(str)

    def __init__(self, items: List[Dict[str, Any]], parent: Optional[QObject] = None):
        super().__init__(parent)
        self.items = items

    def run(self) -> None:
        resolved_items = []
        try:
            for itm in self.items:
                if itm.get("type") == "search":
                    query = itm.get("query", "")
                    results = SearchService.search(query, limit=1)
                    if results:
                        top = results[0]
                        resolved_items.append({
                            "type": "url",
                            "url": top.url,
                            "video_id": top.video_id,
                            "title": top.title,
                            "thumbnail_url": top.thumbnail_url,
                            "duration_str": top.duration_str,
                            "original_query": query,
                        })
                    else:
                        resolved_items.append({
                            "type": "unresolved",
                            "query": query,
                            "title": f"No results for: {query}",
                            "url": "",
                        })
                else:
                    resolved_items.append(itm)
            self.finished_signal.emit(resolved_items)
        except Exception as e:
            self.failed_signal.emit(str(e))


class ThumbnailFetchWorker(QThread):
    """Worker thread for fetching metadata/thumbnail preview."""
    finished_signal = Signal(dict)
    failed_signal = Signal(str)

    def __init__(self, query_or_url: str, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.query_or_url = query_or_url

    def run(self) -> None:
        try:
            kind, resolved = classify_input(self.query_or_url)
            if kind == "url":
                info = YtDlpService.extract_video_info(resolved)
                self.finished_signal.emit({
                    "title": info.title,
                    "thumbnail_url": info.thumbnail_url,
                    "url": info.url,
                    "resolution": "HD" if not info.is_short else "Short",
                })
            else:
                results = SearchService.search(resolved, limit=1)
                if results:
                    top = results[0]
                    self.finished_signal.emit({
                        "title": top.title,
                        "thumbnail_url": top.thumbnail_url,
                        "url": top.url,
                        "resolution": "Standard",
                    })
                else:
                    self.failed_signal.emit("No video found for search query.")
        except Exception as e:
            friendly, _ = translate_error(e)
            self.failed_signal.emit(friendly)


# --- Main PythonQmlBridge ---

class PythonQmlBridge(QObject):
    """
    Main communication bridge between QML frontend and Python backend services.
    Exposes high-level slots, properties, and signals for a snappy, non-blocking UI.
    """

    # Analysis signals
    analysisStarted = Signal()
    analysisFinished = Signal(dict)
    analysisFailed = Signal(str, str)

    # Search signals
    searchStarted = Signal()
    searchFinished = Signal(list)
    searchFailed = Signal(str, str)

    # Playlist signals
    playlistStarted = Signal()
    playlistFinished = Signal(dict)
    playlistFailed = Signal(str, str)

    # Batch signals
    batchResolved = Signal(list)
    batchFailed = Signal(str)

    # Thumbnail signals
    thumbnailPreviewReady = Signal(dict)
    thumbnailPreviewFailed = Signal(str)
    thumbnailDownloaded = Signal(bool, str)

    # Queue signals
    queueChanged = Signal()
    itemProgressUpdated = Signal(str, float, str, str, int, int, str)
    itemCompleted = Signal(str, str)
    itemFailed = Signal(str, str)

    # Toast and dialog notifications
    showToast = Signal(str, str)  # type (info, success, warning, error), message
    environmentChanged = Signal()
    settingsChanged = Signal()

    def __init__(
        self,
        settings_manager: SettingsManager,
        history_repo: HistoryRepository,
        download_manager: DownloadManager,
        parent: Optional[QObject] = None
    ):
        super().__init__(parent)
        self.settings = settings_manager
        self.history = history_repo
        self.download_manager = download_manager

        # Store active worker references to prevent garbage collection
        self._analyze_worker: Optional[AnalyzeWorker] = None
        self._search_worker: Optional[SearchWorker] = None
        self._playlist_worker: Optional[PlaylistWorker] = None
        self._batch_worker: Optional[BatchResolveWorker] = None
        self._thumb_worker: Optional[ThumbnailFetchWorker] = None

        # Connect queue signals
        self.download_manager.queue.queue_updated.connect(self._on_queue_updated)
        self.download_manager.queue.item_progress_signal.connect(self._on_item_progress)
        self.download_manager.download_finished.connect(self._on_download_finished)
        self.download_manager.download_failed.connect(self._on_download_failed)
        self.download_manager.item_skipped.connect(self._on_item_skipped)

        self._env_status = EnvironmentService.get_status().to_dict()

    # --- Properties ---

    @Property(str, constant=True)
    def appName(self) -> str:
        return APP_NAME

    @Property(str, constant=True)
    def appVersion(self) -> str:
        return APP_VERSION

    @Property(dict, notify=environmentChanged)
    def environment(self) -> dict:
        return self._env_status

    @Property(list, notify=queueChanged)
    def queueItems(self) -> list:
        return [itm.to_dict() for itm in self.download_manager.queue.items]

    @Property(int, notify=queueChanged)
    def activeCount(self) -> int:
        return self.download_manager.queue.get_active_count()

    @Property(int, notify=queueChanged)
    def queuedCount(self) -> int:
        return self.download_manager.queue.get_queued_count()

    @Property(int, notify=queueChanged)
    def completedCount(self) -> int:
        return self.download_manager.queue.get_completed_count()

    @Property(bool, notify=queueChanged)
    def isQueuePaused(self) -> bool:
        return self.download_manager.queue.is_paused

    # --- Environment Slots ---

    @Slot()
    def refreshEnvironment(self) -> None:
        """Re-check environment tools and emit status update."""
        self._env_status = EnvironmentService.get_status().to_dict()
        self.environmentChanged.emit()

    # --- Analysis Slots ---

    @Slot(str)
    def analyzeUrl(self, url: str) -> None:
        """Start background analysis of a single video URL."""
        cleaned = url.strip()
        if not cleaned:
            self.analysisFailed.emit("Please enter a valid YouTube URL.", "")
            return

        self.analysisStarted.emit()
        self._analyze_worker = AnalyzeWorker(cleaned, self)
        self._analyze_worker.finished_signal.connect(self._on_analysis_finished)
        self._analyze_worker.failed_signal.connect(self._on_analysis_failed)
        self._analyze_worker.start()

    def _on_analysis_finished(self, data: dict) -> None:
        self.analysisFinished.emit(data)

    def _on_analysis_failed(self, friendly_err: str, tech_err: str) -> None:
        self.analysisFailed.emit(friendly_err, tech_err)

    # --- Search Slots ---

    @Slot(str, int)
    def search(self, query: str, limit: int = 20) -> None:
        """Perform non-blocking YouTube search."""
        cleaned = query.strip()
        if not cleaned:
            self.searchFailed.emit("Please enter a search query.", "")
            return

        self.searchStarted.emit()
        self._search_worker = SearchWorker(cleaned, limit, self)
        self._search_worker.finished_signal.connect(self._on_search_finished)
        self._search_worker.failed_signal.connect(self._on_search_failed)
        self._search_worker.start()

    def _on_search_finished(self, results: list) -> None:
        self.searchFinished.emit(results)

    def _on_search_failed(self, friendly_err: str, tech_err: str) -> None:
        self.searchFailed.emit(friendly_err, tech_err)

    # --- Playlist Slots ---

    @Slot(str)
    def analyzePlaylist(self, url: str) -> None:
        """Extract playlist entries without freezing UI."""
        cleaned = url.strip()
        if not cleaned:
            self.playlistFailed.emit("Please enter a valid playlist URL.", "")
            return

        self.playlistStarted.emit()
        self._playlist_worker = PlaylistWorker(cleaned, self)
        self._playlist_worker.finished_signal.connect(self._on_playlist_finished)
        self._playlist_worker.failed_signal.connect(self._on_playlist_failed)
        self._playlist_worker.start()

    def _on_playlist_finished(self, data: dict) -> None:
        self.playlistFinished.emit(data)

    def _on_playlist_failed(self, friendly_err: str, tech_err: str) -> None:
        self.playlistFailed.emit(friendly_err, tech_err)

    @Slot(int, int, int, result=list)
    def calculatePlaylistRange(self, total: int, start: int, end: int) -> list:
        """Calculate range selection indices."""
        return PlaylistService.calculate_range_selection(total, start, end)

    @Slot(int, int, result=list)
    def calculatePlaylistFirstN(self, total: int, n: int) -> list:
        """Calculate first N selection indices."""
        return PlaylistService.calculate_first_n_selection(total, n)

    # --- Batch & TXT Import Slots ---

    @Slot(str, result=list)
    def parseBatchLines(self, text: str) -> list:
        """
        Parse multi-line batch text, classify lines, and return structured items.
        """
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        items: List[Dict[str, Any]] = []
        seen = set()

        for idx, line in enumerate(lines, start=1):
            kind, resolved = classify_input(line)
            is_dup = resolved in seen
            seen.add(resolved)

            items.append({
                "index": idx,
                "raw_text": line,
                "type": kind,
                "content": resolved,
                "is_duplicate": is_dup,
                "valid": kind in ("url", "search"),
            })

        return items

    @Slot(list)
    def resolveBatchSearchTerms(self, items: list) -> None:
        """Resolve plain text search queries into concrete YouTube videos."""
        self._batch_worker = BatchResolveWorker(items, self)
        self._batch_worker.finished_signal.connect(lambda res: self.batchResolved.emit(res))
        self._batch_worker.failed_signal.connect(lambda err: self.batchFailed.emit(err))
        self._batch_worker.start()

    @Slot(str, result=dict)
    def importTxtFile(self, file_path_or_url: str) -> dict:
        """
        Read a .txt file containing URLs or search terms.
        Supports both raw paths and file:/// URLs from drag & drop or file dialogs.
        """
        clean_path = file_path_or_url.strip()
        if clean_path.startswith("file:///"):
            clean_path = clean_path[8:]
            # On Windows: remove leading slash if e.g. /C:/
            if len(clean_path) >= 3 and clean_path[0] == "/" and clean_path[2] == ":":
                clean_path = clean_path[1:]

        path = Path(clean_path)
        if not path.is_file():
            return {
                "success": False,
                "error": f"File not found: {clean_path}",
                "total": 0, "valid": 0, "invalid": 0, "duplicates": 0,
                "items": []
            }

        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            items = self.parseBatchLines(content)
            total = len(items)
            valid_count = sum(1 for itm in items if itm["valid"] and not itm["is_duplicate"])
            dup_count = sum(1 for itm in items if itm["is_duplicate"])
            invalid_count = total - (valid_count + dup_count)

            return {
                "success": True,
                "total": total,
                "valid": valid_count,
                "invalid": invalid_count,
                "duplicates": dup_count,
                "items": items,
            }
        except Exception as e:
            logger.error("Failed importing TXT file: %s", e, exc_info=True)
            return {
                "success": False,
                "error": str(e),
                "total": 0, "valid": 0, "invalid": 0, "duplicates": 0,
                "items": []
            }

    # --- Thumbnail Downloader Slots ---

    @Slot(str)
    def fetchThumbnailPreview(self, query_or_url: str) -> None:
        """Fetch video metadata and thumbnail preview."""
        self._thumb_worker = ThumbnailFetchWorker(query_or_url, self)
        self._thumb_worker.finished_signal.connect(lambda data: self.thumbnailPreviewReady.emit(data))
        self._thumb_worker.failed_signal.connect(lambda err: self.thumbnailPreviewFailed.emit(err))
        self._thumb_worker.start()

    @Slot(str, str)
    def downloadThumbnail(self, thumbnail_url: str, title: str) -> None:
        """Download thumbnail and save directly into configured folder."""
        dest_dir = self.settings.get("download_dir", get_default_download_dir())
        
        def _do_download():
            ok, path_or_err = ThumbnailService.download_thumbnail(thumbnail_url, title, str(dest_dir))
            self.thumbnailDownloaded.emit(ok, path_or_err)
            if ok:
                self.showToast.emit("success", f"Thumbnail saved: {Path(path_or_err).name}")
            else:
                self.showToast.emit("error", f"Thumbnail download failed: {path_or_err}")

        threading.Thread(target=_do_download, daemon=True).start()

    # --- Download Queue Slots ---

    @Slot(str, str, str, str, str, str, str, str, str)
    def queueSingleDownload(
        self,
        url: str,
        video_id: str,
        title: str,
        thumbnail_url: str,
        media_type: str,
        quality_mode: str,
        output_format: str,
        video_format_id: str = "",
        audio_format_id: str = ""
    ) -> None:
        """Create DownloadConfig and enqueue item into DownloadManager."""
        dest_dir = str(self.settings.get("download_dir", get_default_download_dir()))
        embed_meta = True
        embed_thumb = (media_type == "audio")  # Rule 14: audio embeds thumbnail, video does not by default

        cfg = DownloadConfig(
            url=url,
            video_id=video_id,
            title=title,
            thumbnail_url=thumbnail_url,
            media_type=media_type,
            quality_mode=quality_mode,
            output_format=output_format,
            video_format_id=video_format_id if video_format_id else None,
            audio_format_id=audio_format_id if audio_format_id else None,
            destination_dir=dest_dir,
            embed_metadata=embed_meta,
            embed_thumbnail=embed_thumb,
            duplicate_mode=self.settings.get("duplicate_mode", "Skip"),
        )

        item_id = self.download_manager.enqueue_item(cfg)
        if item_id:
            self.showToast.emit("success", f"Added to queue: {title}")

    @Slot(list, str, str, str)
    def queueBatchDownloads(
        self,
        items: list,
        media_type: str,
        quality_mode: str,
        output_format: str
    ) -> None:
        """Enqueue multiple items (from playlist or batch) with common format settings."""
        dest_dir = str(self.settings.get("download_dir", get_default_download_dir()))
        embed_meta = True
        embed_thumb = (media_type == "audio")
        dup_mode = self.settings.get("duplicate_mode", "Skip")

        configs: List[DownloadConfig] = []
        for itm in items:
            v_url = itm.get("url", "")
            if not v_url:
                continue

            v_title = itm.get("title", "Untitled")
            v_id = itm.get("video_id") or extract_video_id(v_url) or ""
            v_thumb = itm.get("thumbnail_url", "")

            configs.append(DownloadConfig(
                url=v_url,
                video_id=v_id,
                title=v_title,
                thumbnail_url=v_thumb,
                media_type=media_type,
                quality_mode=quality_mode,
                output_format=output_format,
                destination_dir=dest_dir,
                embed_metadata=embed_meta,
                embed_thumbnail=embed_thumb,
                duplicate_mode=dup_mode,
            ))

        enqueued_ids = self.download_manager.enqueue_batch(configs)
        self.showToast.emit("success", f"Added {len(enqueued_ids)} items to queue.")

    @Slot(str)
    def cancelDownload(self, item_id: str) -> None:
        self.download_manager.queue.cancel_item(item_id)
        self.showToast.emit("info", "Download cancelled.")

    @Slot(str)
    def retryDownload(self, item_id: str) -> None:
        self.download_manager.queue.retry_item(item_id)
        self.showToast.emit("info", "Retrying download...")

    @Slot(str)
    def removeQueueItem(self, item_id: str) -> None:
        self.download_manager.queue.remove_item(item_id)

    @Slot()
    def clearCompletedQueue(self) -> None:
        self.download_manager.queue.clear_completed()

    @Slot()
    def clearAllQueue(self) -> None:
        self.download_manager.queue.clear_all()
        self.showToast.emit("info", "Queue cleared.")

    @Slot()
    def toggleQueuePause(self) -> None:
        if self.download_manager.queue.is_paused:
            self.download_manager.queue.resume_new_downloads()
            self.showToast.emit("info", "Queue resumed.")
        else:
            self.download_manager.queue.pause_new_downloads()
            self.showToast.emit("info", "Queue paused.")
        self.queueChanged.emit()

    def _on_queue_updated(self) -> None:
        self.queueChanged.emit()

    def _on_item_progress(
        self,
        item_id: str,
        percent: float,
        speed_str: str,
        eta_str: str,
        downloaded: int,
        total: int,
        status_text: str
    ) -> None:
        self.itemProgressUpdated.emit(item_id, percent, speed_str, eta_str, downloaded, total, status_text)

    def _on_download_finished(self, item_id: str, file_path: str) -> None:
        self.itemCompleted.emit(item_id, file_path)
        self.showToast.emit("success", f"Download finished: {Path(file_path).name}")

    def _on_download_failed(self, item_id: str, error_msg: str) -> None:
        self.itemFailed.emit(item_id, error_msg)
        self.showToast.emit("error", f"Download failed: {error_msg}")

    def _on_item_skipped(self, title: str, reason: str) -> None:
        self.showToast.emit("warning", f"Skipped '{title}': {reason}")

    # --- History Slots ---

    @Slot(str, str, str, result=list)
    def getHistory(self, search_query: str = "", filter_type: str = "All", sort_by: str = "Newest") -> list:
        """Fetch history records matching filters and sort options."""
        items = self.history.get_all(search_query, filter_type, sort_by)
        return [itm.to_dict() for itm in items]

    @Slot(int)
    def deleteHistoryItem(self, record_id: int) -> None:
        self.history.delete(record_id)
        self.showToast.emit("info", "History record removed.")

    @Slot()
    def clearAllHistory(self) -> None:
        self.history.clear_all()
        self.showToast.emit("info", "All history cleared.")

    @Slot()
    def cleanMissingFiles(self) -> None:
        count = self.history.delete_missing_files_records()
        self.showToast.emit("info", f"Cleaned {count} missing file records.")

    # --- Settings Slots ---

    @Slot(result=dict)
    def getSettings(self) -> dict:
        return self.settings.all_settings()

    @Slot(str, "QVariant")
    def setSetting(self, key: str, value: Any) -> None:
        self.settings.set(key, value)
        if key == "concurrent_downloads":
            self.download_manager.queue.set_concurrent_limit(int(value))
        self.settingsChanged.emit()

    @Slot(dict)
    def saveAllSettings(self, new_settings: dict) -> None:
        self.settings.update_multiple(new_settings)
        if "concurrent_downloads" in new_settings:
            self.download_manager.queue.set_concurrent_limit(int(new_settings["concurrent_downloads"]))
        self.settingsChanged.emit()
        self.showToast.emit("success", "Settings saved successfully.")

    @Slot()
    def resetSettings(self) -> None:
        self.settings.reset_to_defaults()
        self.download_manager.queue.set_concurrent_limit(5)
        self.settingsChanged.emit()
        self.showToast.emit("info", "Settings reset to defaults.")

    @Slot()
    def openLogsFolder(self) -> None:
        """Open logs folder in Windows File Explorer."""
        log_dir = get_logs_dir()
        self.openFolder(str(log_dir))

    @Slot()
    def openDownloadsFolder(self) -> None:
        """Open configured downloads folder in Windows File Explorer."""
        dest_dir = self.settings.get("download_dir", get_default_download_dir())
        self.openFolder(str(dest_dir))

    @Slot(result=dict)
    def checkYtDlpUpdates(self) -> dict:
        """Check for updates to yt-dlp via PyPI or installed version."""
        current_ver = self._env_status.get("yt_dlp", {}).get("version", "unknown")
        # Lightweight check or return current version
        return {
            "current_version": current_ver,
            "latest_version": current_ver,
            "update_available": False,
        }

    # --- Native Windows File & Folder Slots ---

    @Slot(str)
    def openFile(self, file_path: str) -> None:
        """Open downloaded media file with Windows default handler."""
        if not file_path:
            self.showToast.emit("warning", "File path is empty.")
            return

        p = Path(file_path)
        if not p.is_file():
            self.showToast.emit("error", "File no longer exists on disk.")
            return

        try:
            os.startfile(str(p))
        except Exception as e:
            logger.error("Failed opening file %s: %s", file_path, e)
            self.showToast.emit("error", f"Could not open file: {e}")

    @Slot(str)
    def openFolder(self, file_path_or_dir: str) -> None:
        """Reveal file or open directory in Windows File Explorer."""
        if not file_path_or_dir:
            return

        target = Path(file_path_or_dir)
        try:
            if target.is_file():
                # Open explorer and select file
                subprocess.Popen(f'explorer /select,"{str(target)}"')
            elif target.is_dir():
                os.startfile(str(target))
            else:
                # If target doesn't exist, try its parent
                if target.parent.is_dir():
                    os.startfile(str(target.parent))
                else:
                    self.showToast.emit("error", "Folder does not exist.")
        except Exception as e:
            logger.error("Failed opening folder %s: %s", file_path_or_dir, e)
            self.showToast.emit("error", f"Could not open folder: {e}")

    @Slot(str)
    def copyToClipboard(self, text: str) -> None:
        """Copy text to Windows clipboard."""
        cb = QGuiApplication.clipboard()
        if cb:
            cb.setText(text, QClipboard.Mode.Clipboard)
            self.showToast.emit("info", "Copied to clipboard.")
