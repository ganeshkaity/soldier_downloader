from app.constants import DownloadStatus
from app.downloader.queue_manager import QueueManager
from app.models.download_config import DownloadConfig


def test_queue_manager_add_and_counts():
    qm = QueueManager(concurrent_limit=3)
    qm.pause_new_downloads()
    assert qm.concurrent_limit == 3
    assert len(qm.items) == 0

    cfg1 = DownloadConfig(url="https://youtube.com/watch?v=11111111111", title="Test 1")
    cfg2 = DownloadConfig(url="https://youtube.com/watch?v=22222222222", title="Test 2")

    id1 = qm.add_download(cfg1)
    id2 = qm.add_download(cfg2)

    assert id1 in qm._items_by_id
    assert id2 in qm._items_by_id
    assert len(qm.items) == 2


def test_queue_manager_batch_add():
    qm = QueueManager(concurrent_limit=5)
    qm.pause_new_downloads()
    configs = [
        DownloadConfig(url=f"https://youtube.com/watch?v={i:011d}", title=f"Batch {i}")
        for i in range(10)
    ]
    ids = qm.add_batch(configs)
    assert len(ids) == 10
    assert len(qm.items) == 10


def test_queue_manager_cancel_and_retry():
    qm = QueueManager(concurrent_limit=2)
    qm.pause_new_downloads()
    cfg = DownloadConfig(url="https://youtube.com/watch?v=11111111111", title="Cancel Test")
    item_id = qm.add_download(cfg)

    # Cancel while queued
    qm.cancel_item(item_id)
    item = qm._items_by_id[item_id]
    assert item.status == DownloadStatus.CANCELLED

    # Retry while paused
    qm.retry_item(item_id)
    assert item.status == DownloadStatus.QUEUED


def test_queue_manager_clear_and_remove():
    qm = QueueManager(concurrent_limit=5)
    qm.pause_new_downloads()
    cfg1 = DownloadConfig(url="https://youtube.com/watch?v=11111111111", title="Clear Test 1")
    cfg2 = DownloadConfig(url="https://youtube.com/watch?v=22222222222", title="Clear Test 2")

    id1 = qm.add_download(cfg1)
    id2 = qm.add_download(cfg2)

    # Set status manually for testing cleanup
    qm._items_by_id[id1].status = DownloadStatus.COMPLETED
    qm._items_by_id[id2].status = DownloadStatus.CANCELLED

    qm.clear_completed()
    assert len(qm.items) == 0

    # Add item and remove explicitly
    id3 = qm.add_download(cfg1)
    assert len(qm.items) == 1
    qm.remove_item(id3)
    assert len(qm.items) == 0
