"""Unit tests for SQLite database schema and history repository CRUD."""

import pytest
from app.database.database import Database
from app.database.history_repository import HistoryRepository


@pytest.fixture
def repo(tmp_path):
    db_file = tmp_path / "test_history.db"
    db = Database(db_path=db_file)
    return HistoryRepository(db=db)


def test_add_and_get_history(repo):
    rec_id = repo.add(
        video_id="abc123xyz00",
        title="Test Song",
        url="https://youtube.com/watch?v=abc123xyz00",
        media_type="audio",
        output_format="MP3",
        quality="Best",
        file_path="C:/Downloads/Soldiers/Test Song.mp3",
        file_size=1024 * 1024 * 5,
        status="Completed",
    )
    assert rec_id > 0

    items = repo.get_all()
    assert len(items) == 1
    assert items[0].title == "Test Song"
    assert items[0].video_id == "abc123xyz00"


def test_filter_and_search_history(repo):
    repo.add(video_id="v1", title="Python Tutorial", url="http://yt/1", media_type="video", output_format="MP4", quality="1080p")
    repo.add(video_id="v2", title="Jazz Music", url="http://yt/2", media_type="audio", output_format="MP3", quality="Best")

    # Search
    search_py = repo.get_all(search_query="Python")
    assert len(search_py) == 1
    assert search_py[0].title == "Python Tutorial"

    # Filter audio
    audio_items = repo.get_all(filter_type="audio")
    assert len(audio_items) == 1
    assert audio_items[0].title == "Jazz Music"


def test_delete_and_clear_history(repo):
    id1 = repo.add(video_id="v1", title="Item 1", url="http://yt/1", media_type="video", output_format="MP4", quality="1080p")
    id2 = repo.add(video_id="v2", title="Item 2", url="http://yt/2", media_type="video", output_format="MP4", quality="1080p")

    assert len(repo.get_all()) == 2
    repo.delete(id1)
    assert len(repo.get_all()) == 1

    repo.clear_all()
    assert len(repo.get_all()) == 0
