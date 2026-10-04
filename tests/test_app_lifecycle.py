import sys
from pathlib import Path
from PySide6.QtCore import QCoreApplication, QTimer, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from app.bridge.python_qml_bridge import PythonQmlBridge
from app.constants import APP_NAME, APP_VERSION
from app.database.database import Database
from app.database.history_repository import HistoryRepository
from app.downloader.download_manager import DownloadManager
from app.services.environment_service import EnvironmentService
from app.settings.settings_manager import SettingsManager
from app.utils.paths import resolve_qml_path


def test_full_app_lifecycle(tmp_path):
    app = QApplication.instance()
    if not app:
        app = QApplication([])

    settings = SettingsManager(file_path=tmp_path / "settings.json")
    db = Database(db_path=tmp_path / "history.db")
    history_repo = HistoryRepository(db=db)
    download_manager = DownloadManager(settings_manager=settings, history_repo=history_repo)
    bridge = PythonQmlBridge(settings_manager=settings, history_repo=history_repo, download_manager=download_manager)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = resolve_qml_path("qml/Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    assert len(engine.rootObjects()) > 0
    main_window = engine.rootObjects()[0]
    assert main_window.property("visible") is True

    # Test bridge properties
    assert bridge.appName == APP_NAME
    assert bridge.appVersion == APP_VERSION
    assert bridge.activeCount == 0
    assert bridge.queuedCount == 0

    # Ensure clean shutdown
    main_window.close()
