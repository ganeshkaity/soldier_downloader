from app.constants import DownloadStatus
from app.downloader.progress_parser import ProgressParser


def test_progress_parser_downloading_hook():
    parser = ProgressParser()
    hook_data = {
        "status": "downloading",
        "downloaded_bytes": 50_000_000,
        "total_bytes": 100_000_000,
        "speed": 5_000_000,
        "eta": 10,
    }

    percent, speed_str, eta_str, downloaded, total, status_text = parser.parse_hook(hook_data)

    assert percent == 50.0
    assert "MB" in speed_str or "MiB" in speed_str or "5." in speed_str or "4." in speed_str
    assert "00:10" in eta_str
    assert downloaded == 50_000_000
    assert total == 100_000_000
    assert status_text == DownloadStatus.DOWNLOADING


def test_progress_parser_finished_hook():
    parser = ProgressParser()
    hook_data = {
        "status": "finished",
        "total_bytes": 100_000_000,
    }

    percent, speed_str, eta_str, downloaded, total, status_text = parser.parse_hook(hook_data)
    assert percent == 100.0
    assert status_text == "Processing..."
