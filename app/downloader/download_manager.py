"""DownloadManager tying together QueueManager, HistoryRepository, and Settings."""

from pathlib import Path
from typing import List, Optional
from PySide6.QtCore import QObject, Signal

from app.database.history_repository import HistoryRepository
from app.downloader.queue_manager import QueueManager
from app.models.download_config import DownloadConfig
from app.models.download_item import DownloadItem
from app.settings.settings_manager import SettingsManager
from app.utils.filename import sanitize_filename
from app.utils.logger import get_logger

logger = get_logger()


class DownloadManager(QObject):
    """High-level manager handling downloads, queue lifecycle, and history persistence."""

    # Bridge notification signals
    download_started = Signal(str, str)     # item_id, title
    download_finished = Signal(str, str)    # item_id, file_path
    download_failed = Signal(str, str)      # item_id, error_message
    item_skipped = Signal(str, str)         # title, reason

    def __init__(
        self,
        settings_manager: SettingsManager,
        history_repo: HistoryRepository,
        parent: Optional[QObject] = None
    ):
        super().__init__(parent)
        self.settings = settings_manager
        self.history = history_repo
        
        concurrent_limit = int(self.settings.get("concurrent_downloads", 5))
        self.queue = QueueManager(concurrent_limit=concurrent_limit, parent=self)

        # Connect queue signals
        self.queue.item_completed_signal.connect(self._on_item_completed)
        self.queue.item_failed_signal.connect(self._on_item_failed)

    def enqueue_item(self, config: DownloadConfig) -> Optional[str]:
        """Validate duplicate policy and enqueue download config."""
        dup_mode = self.settings.get("duplicate_mode", "Skip")

        # Check duplicate
        if dup_mode == "Skip":
            # Check if file already exists in destination
            dest_dir = Path(config.destination_dir)
            clean_base = sanitize_filename(config.filename or config.title)
            existing_files = list(dest_dir.glob(f"{clean_base}.*"))
            valid_existing = [f for f in existing_files if not f.name.endswith(".part") and not f.name.endswith(".ytdl")]
            if valid_existing:
                logger.info("Skipping '%s' because '%s' already exists.", config.title, valid_existing[0])
                self.item_skipped.emit(config.title, f"File already exists: {valid_existing[0].name}")
                return None

        item_id = self.queue.add_download(config)
        self.download_started.emit(item_id, config.title)
        return item_id

    def enqueue_batch(self, configs: List[DownloadConfig]) -> List[str]:
        """Enqueue multiple configs respecting duplicate rules."""
        valid_configs: List[DownloadConfig] = []
        dup_mode = self.settings.get("duplicate_mode", "Skip")

        for cfg in configs:
            if dup_mode == "Skip":
                dest_dir = Path(cfg.destination_dir)
                clean_base = sanitize_filename(cfg.filename or cfg.title)
                existing_files = list(dest_dir.glob(f"{clean_base}.*"))
                valid_existing = [f for f in existing_files if not f.name.endswith(".part") and not f.name.endswith(".ytdl")]
                if valid_existing:
                    self.item_skipped.emit(cfg.title, f"File already exists: {valid_existing[0].name}")
                    continue
            valid_configs.append(cfg)

        return self.queue.add_batch(valid_configs)

    def _on_item_completed(self, item_id: str, file_path: str, file_size: int) -> None:
        """Record completed download in SQLite history."""
        item = self.queue._items_by_id.get(item_id)
        if not item:
            return

        logger.info("Recording history for completed item: %s", item.title)
        self.history.add(
            video_id=item.video_id,
            title=item.title,
            url=item.url,
            media_type=item.media_type,
            output_format=item.format,
            quality=item.quality,
            file_path=file_path,
            file_size=file_size,
            status="Completed",
            duration=0,
            thumbnail_url=item.thumbnail_url,
            error_message="",
        )
        self.download_finished.emit(item_id, file_path)

    def _on_item_failed(self, item_id: str, friendly_err: str, details: str) -> None:
        """Record failed download in SQLite history."""
        item = self.queue._items_by_id.get(item_id)
        if not item:
            return

        logger.info("Recording history for failed item: %s", item.title)
        self.history.add(
            video_id=item.video_id,
            title=item.title,
            url=item.url,
            media_type=item.media_type,
            output_format=item.format,
            quality=item.quality,
            file_path="",
            file_size=0,
            status="Failed",
            duration=0,
            thumbnail_url=item.thumbnail_url,
            error_message=friendly_err,
        )
        self.download_failed.emit(item_id, friendly_err)
