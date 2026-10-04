"""History repository for database operations on download history."""

import os
from datetime import datetime
from pathlib import Path
from typing import List, Optional
from app.database.database import Database
from app.models.history_item import HistoryItem
from app.utils.logger import get_logger

logger = get_logger()


class HistoryRepository:
    """Provides CRUD operations for download history."""

    def __init__(self, db: Optional[Database] = None):
        self.db = db or Database()

    def add(
        self,
        video_id: str,
        title: str,
        url: str,
        media_type: str,
        output_format: str,
        quality: str,
        file_path: str = "",
        file_size: int = 0,
        status: str = "Completed",
        duration: int = 0,
        thumbnail_url: str = "",
        error_message: str = "",
        date_time: Optional[str] = None
    ) -> int:
        """Insert a download record into the history table."""
        if not date_time:
            date_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        query = """
        INSERT INTO downloads (
            video_id, title, url, media_type, output_format, quality,
            file_path, file_size, status, date_time, duration, thumbnail_url, error_message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        params = (
            video_id, title, url, media_type, output_format, quality,
            file_path, file_size, status, date_time, duration, thumbnail_url, error_message
        )

        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return cursor.lastrowid or 0
        except Exception as e:
            logger.error("Error adding history entry: %s", e, exc_info=True)
            return 0

    def update_status(
        self,
        record_id: int,
        status: str,
        file_path: Optional[str] = None,
        file_size: Optional[int] = None,
        error_message: Optional[str] = None
    ) -> bool:
        """Update status, file path, size, or error message of an existing record."""
        updates = ["status = ?"]
        params = [status]

        if file_path is not None:
            updates.append("file_path = ?")
            params.append(file_path)

        if file_size is not None:
            updates.append("file_size = ?")
            params.append(file_size)

        if error_message is not None:
            updates.append("error_message = ?")
            params.append(error_message)

        params.append(record_id)
        query = f"UPDATE downloads SET {', '.join(updates)} WHERE id = ?"

        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, tuple(params))
                conn.commit()
                return cursor.rowcount > 0
        except Exception as e:
            logger.error("Error updating history status: %s", e, exc_info=True)
            return False

    def get_all(
        self,
        search_query: str = "",
        filter_type: str = "All",
        sort_by: str = "Newest"
    ) -> List[HistoryItem]:
        """
        Query history records with optional search query, status/media filter, and sorting.
        """
        conditions = []
        params = []

        if search_query.strip():
            conditions.append("(title LIKE ? OR url LIKE ?)")
            q = f"%{search_query.strip()}%"
            params.extend([q, q])

        # Filter handling
        filter_lower = filter_type.strip().lower()
        if filter_lower == "completed":
            conditions.append("status = 'Completed'")
        elif filter_lower == "failed":
            conditions.append("status = 'Failed'")
        elif filter_lower == "cancelled":
            conditions.append("status = 'Cancelled'")
        elif filter_lower == "audio":
            conditions.append("media_type = 'audio'")
        elif filter_lower == "video":
            conditions.append("media_type = 'video'")

        where_clause = f"WHERE {' AND '.join(conditions)}" if conditions else ""

        # Sort handling
        sort_lower = sort_by.strip().lower()
        if sort_lower == "oldest":
            order_clause = "ORDER BY id ASC"
        elif sort_lower == "name":
            order_clause = "ORDER BY title COLLATE NOCASE ASC"
        elif sort_lower == "size":
            order_clause = "ORDER BY file_size DESC"
        else:  # Default newest
            order_clause = "ORDER BY id DESC"

        query = f"SELECT * FROM downloads {where_clause} {order_clause}"

        items: List[HistoryItem] = []
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, tuple(params))
                rows = cursor.fetchall()
                for row in rows:
                    items.append(HistoryItem(
                        id=row["id"],
                        video_id=row["video_id"],
                        title=row["title"],
                        url=row["url"],
                        media_type=row["media_type"],
                        output_format=row["output_format"],
                        quality=row["quality"],
                        file_path=row["file_path"],
                        file_size=row["file_size"],
                        status=row["status"],
                        date_time=row["date_time"],
                        duration=row["duration"],
                        thumbnail_url=row["thumbnail_url"],
                        error_message=row["error_message"],
                    ))
        except Exception as e:
            logger.error("Error retrieving download history: %s", e, exc_info=True)

        return items

    def delete(self, record_id: int) -> bool:
        """Delete a single history entry by ID."""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("DELETE FROM downloads WHERE id = ?", (record_id,))
                conn.commit()
                return cursor.rowcount > 0
        except Exception as e:
            logger.error("Error deleting history record %d: %s", record_id, e, exc_info=True)
            return False

    def clear_all(self) -> bool:
        """Clear all history entries."""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("DELETE FROM downloads")
                conn.commit()
                return True
        except Exception as e:
            logger.error("Error clearing download history: %s", e, exc_info=True)
            return False

    def delete_missing_files_records(self) -> int:
        """Remove history entries where the file on disk no longer exists."""
        all_items = self.get_all()
        removed_count = 0
        for item in all_items:
            if item.status == "Completed" and item.file_path:
                if not Path(item.file_path).is_file():
                    self.delete(item.id)
                    removed_count += 1
        return removed_count

    def find_by_video_id(self, video_id: str) -> Optional[HistoryItem]:
        """Find the latest record for a given video ID."""
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT * FROM downloads WHERE video_id = ? ORDER BY id DESC LIMIT 1",
                    (video_id,)
                )
                row = cursor.fetchone()
                if row:
                    return HistoryItem(
                        id=row["id"],
                        video_id=row["video_id"],
                        title=row["title"],
                        url=row["url"],
                        media_type=row["media_type"],
                        output_format=row["output_format"],
                        quality=row["quality"],
                        file_path=row["file_path"],
                        file_size=row["file_size"],
                        status=row["status"],
                        date_time=row["date_time"],
                        duration=row["duration"],
                        thumbnail_url=row["thumbnail_url"],
                        error_message=row["error_message"],
                    )
        except Exception as e:
            logger.error("Error finding history by video_id: %s", e, exc_info=True)
        return None
