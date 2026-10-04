"""QueueManager coordinating concurrent download workers and queue state."""

from typing import Dict, List, Optional
from PySide6.QtCore import QObject, Signal

from app.constants import DEFAULT_CONCURRENT_DOWNLOADS, DownloadStatus
from app.downloader.download_worker import DownloadWorker
from app.models.download_config import DownloadConfig
from app.models.download_item import DownloadItem
from app.utils.logger import get_logger

logger = get_logger()


class QueueManager(QObject):
    """
    Manages the queue of download tasks, executing up to max_concurrent downloads
    simultaneously and maintaining state.
    """

    # Signals for UI integration
    queue_updated = Signal()
    item_progress_signal = Signal(str, float, str, str, int, int, str)
    item_status_signal = Signal(str, str)
    item_completed_signal = Signal(str, str, int)  # item_id, file_path, file_size
    item_failed_signal = Signal(str, str, str)     # item_id, friendly_error, details
    item_cancelled_signal = Signal(str)

    def __init__(self, concurrent_limit: int = DEFAULT_CONCURRENT_DOWNLOADS, parent: Optional[QObject] = None):
        super().__init__(parent)
        self.concurrent_limit = concurrent_limit
        self.items: List[DownloadItem] = []
        self._items_by_id: Dict[str, DownloadItem] = {}
        self._active_workers: Dict[str, DownloadWorker] = {}
        self._is_paused = False

    def set_concurrent_limit(self, limit: int) -> None:
        """Update maximum concurrent downloads and process queue."""
        self.concurrent_limit = max(1, min(limit, 10))
        logger.info("Concurrent download limit set to %d", self.concurrent_limit)
        self._process_queue()

    def pause_new_downloads(self) -> None:
        """Pause processing new queued items without stopping active downloads."""
        self._is_paused = True
        logger.info("New downloads paused.")

    def resume_new_downloads(self) -> None:
        """Resume processing queued items."""
        self._is_paused = False
        logger.info("New downloads resumed.")
        self._process_queue()

    @property
    def is_paused(self) -> bool:
        return self._is_paused

    def add_download(self, config: DownloadConfig) -> str:
        """Enqueue a new download item and trigger queue processing."""
        item = DownloadItem(
            video_id=config.video_id,
            url=config.url,
            title=config.title,
            media_type=config.media_type,
            quality=config.quality_mode,
            format=config.output_format,
            status=DownloadStatus.QUEUED,
            thumbnail_url=config.thumbnail_url,
            config=config,
        )

        self.items.append(item)
        self._items_by_id[item.id] = item
        logger.info("Enqueued download item [%s]: %s", item.id, item.title)

        self.queue_updated.emit()
        self._process_queue()
        return item.id

    def add_batch(self, configs: List[DownloadConfig]) -> List[str]:
        """Enqueue multiple download items."""
        ids: List[str] = []
        for cfg in configs:
            item = DownloadItem(
                video_id=cfg.video_id,
                url=cfg.url,
                title=cfg.title,
                media_type=cfg.media_type,
                quality=cfg.quality_mode,
                format=cfg.output_format,
                status=DownloadStatus.QUEUED,
                thumbnail_url=cfg.thumbnail_url,
                config=cfg,
            )
            self.items.append(item)
            self._items_by_id[item.id] = item
            ids.append(item.id)

        logger.info("Enqueued batch of %d items", len(configs))
        self.queue_updated.emit()
        self._process_queue()
        return ids

    def cancel_item(self, item_id: str) -> None:
        """Cancel an active or queued download."""
        item = self._items_by_id.get(item_id)
        if not item:
            return

        if item_id in self._active_workers:
            # Active worker -> request cancellation
            worker = self._active_workers[item_id]
            worker.cancel()
        elif item.status == DownloadStatus.QUEUED:
            item.status = DownloadStatus.CANCELLED
            self.queue_updated.emit()
            self._process_queue()

    def retry_item(self, item_id: str) -> None:
        """Retry a failed or cancelled item."""
        item = self._items_by_id.get(item_id)
        if not item or not item.config:
            return

        if item.status in (DownloadStatus.FAILED, DownloadStatus.CANCELLED):
            item.status = DownloadStatus.QUEUED
            item.progress_percent = 0.0
            item.error_message = ""
            item.speed_str = "—"
            item.eta_str = "—"
            item.downloaded_bytes = 0
            item.total_bytes = 0
            logger.info("Retrying item [%s]: %s", item.id, item.title)
            self.queue_updated.emit()
            self._process_queue()

    def remove_item(self, item_id: str) -> None:
        """Remove an item from the queue."""
        if item_id in self._active_workers:
            self.cancel_item(item_id)

        if item_id in self._items_by_id:
            del self._items_by_id[item_id]

        self.items = [i for i in self.items if i.id != item_id]
        self.queue_updated.emit()
        self._process_queue()

    def clear_completed(self) -> None:
        """Remove all completed, cancelled, or failed items."""
        to_remove = [i.id for i in self.items if i.status in (DownloadStatus.COMPLETED, DownloadStatus.CANCELLED)]
        for i_id in to_remove:
            if i_id in self._items_by_id:
                del self._items_by_id[i_id]
        self.items = [i for i in self.items if i.status not in (DownloadStatus.COMPLETED, DownloadStatus.CANCELLED)]
        self.queue_updated.emit()

    def clear_all(self) -> None:
        """Cancel all active downloads and clear the entire queue."""
        for worker in list(self._active_workers.values()):
            worker.cancel()
        self._active_workers.clear()
        self.items.clear()
        self._items_by_id.clear()
        self.queue_updated.emit()

    def get_active_count(self) -> int:
        """Return number of currently downloading items."""
        return len(self._active_workers)

    def get_queued_count(self) -> int:
        """Return number of pending queued items."""
        return sum(1 for i in self.items if i.status == DownloadStatus.QUEUED)

    def get_completed_count(self) -> int:
        """Return number of completed items in queue."""
        return sum(1 for i in self.items if i.status == DownloadStatus.COMPLETED)

    def _process_queue(self) -> None:
        """Start pending items up to concurrent_limit."""
        if self._is_paused:
            return

        available_slots = self.concurrent_limit - len(self._active_workers)
        if available_slots <= 0:
            return

        for item in self.items:
            if available_slots <= 0:
                break
            if item.status == DownloadStatus.QUEUED and item.id not in self._active_workers:
                self._start_worker(item)
                available_slots -= 1

    def _start_worker(self, item: DownloadItem) -> None:
        """Instantiate and start DownloadWorker for item."""
        if not item.config:
            return

        worker = DownloadWorker(item.id, item.config)
        worker.progress_signal.connect(self._on_worker_progress)
        worker.status_signal.connect(self._on_worker_status)
        worker.finished_signal.connect(self._on_worker_finished)
        worker.failed_signal.connect(self._on_worker_failed)
        worker.cancelled_signal.connect(self._on_worker_cancelled)

        self._active_workers[item.id] = worker
        item.status = DownloadStatus.PREPARING
        worker.start()

    def _on_worker_progress(
        self,
        item_id: str,
        percent: float,
        speed_str: str,
        eta_str: str,
        downloaded: int,
        total: int,
        status_text: str
    ) -> None:
        item = self._items_by_id.get(item_id)
        if item:
            item.progress_percent = percent
            item.speed_str = speed_str
            item.eta_str = eta_str
            item.downloaded_bytes = downloaded
            item.total_bytes = total
            item.status = status_text
            self.item_progress_signal.emit(item_id, percent, speed_str, eta_str, downloaded, total, status_text)

    def _on_worker_status(self, item_id: str, status: str) -> None:
        item = self._items_by_id.get(item_id)
        if item:
            item.status = status
            self.item_status_signal.emit(item_id, status)
            self.queue_updated.emit()

    def _on_worker_finished(self, item_id: str, file_path: str, file_size: int) -> None:
        item = self._items_by_id.get(item_id)
        if item:
            item.status = DownloadStatus.COMPLETED
            item.destination_file = file_path
            item.downloaded_bytes = file_size
            item.total_bytes = file_size
            item.progress_percent = 100.0
            item.speed_str = "—"
            item.eta_str = "—"
            self.item_completed_signal.emit(item_id, file_path, file_size)

        self._cleanup_worker(item_id)

    def _on_worker_failed(self, item_id: str, friendly_err: str, details: str) -> None:
        item = self._items_by_id.get(item_id)
        if item:
            item.status = DownloadStatus.FAILED
            item.error_message = friendly_err
            item.speed_str = "—"
            item.eta_str = "—"
            self.item_failed_signal.emit(item_id, friendly_err, details)

        self._cleanup_worker(item_id)

    def _on_worker_cancelled(self, item_id: str) -> None:
        item = self._items_by_id.get(item_id)
        if item:
            item.status = DownloadStatus.CANCELLED
            item.speed_str = "—"
            item.eta_str = "—"
            self.item_cancelled_signal.emit(item_id)

        self._cleanup_worker(item_id)

    def _cleanup_worker(self, item_id: str) -> None:
        if item_id in self._active_workers:
            del self._active_workers[item_id]

        self.queue_updated.emit()
        self._process_queue()
