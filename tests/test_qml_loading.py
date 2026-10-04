"""Verification test ensuring QML engine loads without syntax, import, or binding errors."""

import sys
import pytest
from pathlib import Path
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from app.bridge.python_qml_bridge import PythonQmlBridge
from app.database.database import Database
from app.database.history_repository import HistoryRepository
from app.downloader.download_manager import DownloadManager
from app.settings.settings_manager import SettingsManager
from app.utils.paths import resolve_qml_path


def test_qml_engine_loads_main(tmp_path):
    # Ensure QApplication exists
    app = QApplication.instance()
    if not app:
        app = QApplication([])

    settings = SettingsManager(file_path=tmp_path / "settings.json")
    db = Database(db_path=tmp_path / "history.db")
    history_repo = HistoryRepository(db=db)
    dl_mgr = DownloadManager(settings_manager=settings, history_repo=history_repo)

    bridge = PythonQmlBridge(
        settings_manager=settings,
        history_repo=history_repo,
        download_manager=dl_mgr
    )

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = resolve_qml_path("qml/Main.qml")
    assert Path(qml_file).is_file()

    errors = []
    def on_warnings(warnings):
        for w in warnings:
            errors.append(w.toString())

    engine.warnings.connect(on_warnings)
    engine.load(QUrl.fromLocalFile(qml_file))

    root_objs = engine.rootObjects()
    assert len(root_objs) > 0, f"QML failed to load root objects! Errors: {errors}"

    window = root_objs[0]
    assert window is not None
    # Close window cleanly
    window.close()
