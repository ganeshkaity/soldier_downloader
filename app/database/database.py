"""SQLite Database connection manager and schema initialization."""

import sqlite3
from pathlib import Path
from typing import Optional
from app.utils.logger import get_logger
from app.utils.paths import get_db_path

logger = get_logger()

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    media_type TEXT NOT NULL,
    output_format TEXT NOT NULL,
    quality TEXT NOT NULL,
    file_path TEXT DEFAULT '',
    file_size INTEGER DEFAULT 0,
    status TEXT NOT NULL,
    date_time TEXT NOT NULL,
    duration INTEGER DEFAULT 0,
    thumbnail_url TEXT DEFAULT '',
    error_message TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_downloads_video_id ON downloads(video_id);
CREATE INDEX IF NOT EXISTS idx_downloads_status ON downloads(status);
CREATE INDEX IF NOT EXISTS idx_downloads_date_time ON downloads(date_time);
"""


class Database:
    """Manages SQLite database connections and initialization."""

    def __init__(self, db_path: Optional[Path] = None):
        self.db_path = db_path or get_db_path()
        self.init_database()

    def get_connection(self) -> sqlite3.Connection:
        """Create and return a configured connection to the SQLite database."""
        conn = sqlite3.connect(str(self.db_path), timeout=10.0)
        conn.row_factory = sqlite3.Row
        return conn

    def init_database(self) -> None:
        """Run initial migrations and ensure schema exists."""
        try:
            self.db_path.parent.mkdir(parents=True, exist_ok=True)
            with self.get_connection() as conn:
                conn.executescript(SCHEMA_SQL)
                conn.commit()
            logger.info("History database initialized successfully at %s", self.db_path)
        except Exception as e:
            logger.error("Failed to initialize database: %s", e, exc_info=True)
            raise
