"""
Soldier Downloader - Main Desktop Entry Point
Native Windows YouTube Media Downloader built with PySide6 & Qt Quick (QML).
"""

import os
import sys
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtGui import QIcon, QAction
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu

from app.bridge.python_qml_bridge import PythonQmlBridge
from app.config import parse_args
from app.constants import APP_NAME, APP_VERSION
from app.database.database import Database
from app.database.history_repository import HistoryRepository
from app.downloader.download_manager import DownloadManager
from app.services.environment_service import EnvironmentService
from app.settings.settings_manager import SettingsManager
from app.utils.logger import get_logger, setup_logger
from app.utils.paths import resolve_qml_path


def create_tray_icon(app: QApplication, window, bridge: PythonQmlBridge, settings: SettingsManager) -> QSystemTrayIcon:
    """Configure Windows System Tray icon, context menu, and click interactions."""
    tray = QSystemTrayIcon(app)

    # Standard system icon fallback or custom icon
    icon = app.style().standardIcon(app.style().StandardPixmap.SP_ArrowDown)
    tray.setIcon(icon)
    tray.setToolTip(f"{APP_NAME} v{APP_VERSION}")

    menu = QMenu()

    action_open = QAction("Open Soldier Downloader", menu)
    action_open.triggered.connect(lambda: _show_and_activate(window))
    menu.addAction(action_open)

    menu.addSeparator()

    action_pause = QAction("Pause Downloads", menu)
    action_pause.triggered.connect(lambda: bridge.toggleQueuePause())
    menu.addAction(action_pause)

    action_resume = QAction("Resume Downloads", menu)
    action_resume.triggered.connect(lambda: bridge.toggleQueuePause())
    menu.addAction(action_resume)

    menu.addSeparator()

    action_exit = QAction("Exit", menu)
    action_exit.triggered.connect(lambda: _force_exit(app, bridge))
    menu.addAction(action_exit)

    tray.setContextMenu(menu)

    def on_tray_activated(reason):
        if reason in (QSystemTrayIcon.ActivationReason.Trigger, QSystemTrayIcon.ActivationReason.DoubleClick):
            _show_and_activate(window)

    tray.activated.connect(on_tray_activated)
    tray.show()
    return tray


def _show_and_activate(window):
    """Restore, un-minimize, and bring window to foreground."""
    if window:
        window.show()
        window.requestActivate()


def _force_exit(app: QApplication, bridge: PythonQmlBridge):
    """Clean exit ensuring workers are halted."""
    bridge.download_manager.queue.pause_new_downloads()
    app.quit()


def main():
    # Parse CLI flags (--debug, --minimized)
    cli_config = parse_args()
    logger = setup_logger(debug=cli_config.debug)
    logger.info("Starting %s v%s", APP_NAME, APP_VERSION)

    # Enable High-DPI scaling
    QCoreApplication.setApplicationName(APP_NAME)
    QCoreApplication.setOrganizationName("SoldierTeam")

    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)

    # 1. Initialize persistent settings
    settings = SettingsManager()

    # 2. Initialize database
    db = Database()
    history_repo = HistoryRepository(db=db)

    # 3. Initialize download manager and concurrency
    download_manager = DownloadManager(
        settings_manager=settings,
        history_repo=history_repo
    )

    # 4. Perform startup environment detection
    env_status = EnvironmentService.get_status()
    logger.info("Environment check complete. All critical tools ready: %s", env_status.all_critical_ready)

    # 5. Initialize Python ↔ QML Bridge
    bridge = PythonQmlBridge(
        settings_manager=settings,
        history_repo=history_repo,
        download_manager=download_manager
    )

    # 6. Initialize QML Engine
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = resolve_qml_path("qml/Main.qml")
    logger.info("Loading main QML interface from %s", qml_file)
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        logger.critical("Failed to load QML interface. Exiting.")
        sys.exit(-1)

    main_window = engine.rootObjects()[0]

    # 7. Setup Windows System Tray
    tray_icon = None
    if QSystemTrayIcon.isSystemTrayAvailable():
        tray_icon = create_tray_icon(app, main_window, bridge, settings)

    # Handle window close behavior
    def on_window_closing(close_event=None):
        should_minimize = settings.get("minimize_to_tray", True)
        close_mode = settings.get("close_behavior", "Minimize to tray")

        active_dl_count = bridge.activeCount
        if active_dl_count > 0 or (should_minimize and close_mode == "Minimize to tray"):
            if close_event is not None and hasattr(close_event, "accepted"):
                close_event.accepted = False
            main_window.hide()
            if tray_icon:
                tray_icon.showMessage(
                    APP_NAME,
                    f"Running in system tray. {active_dl_count} active downloads continuing.",
                    QSystemTrayIcon.MessageIcon.Information,
                    2000
                )
        else:
            app.quit()

    main_window.closing.connect(on_window_closing)

    # Handle startup minimized
    if cli_config.start_minimized or settings.get("start_minimized", False):
        main_window.hide()
    else:
        main_window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
