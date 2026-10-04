# 🛡️ Soldier Downloader
### Complete Native Windows Desktop YouTube Media Downloader

**Soldier Downloader** is a modern, high-performance Windows desktop application for downloading YouTube videos, audio tracks, playlists, shorts, and thumbnails locally.

Built with **Python**, **PySide6**, **Qt Quick / QML**, **yt-dlp**, **FFmpeg**, and **SQLite**. Zero cloud dependency, zero web servers, zero Electron bloat—runs 100% locally on your PC with a semi-dark liquid glass aesthetic.

---

## ✨ Features

- **Liquid Glass UI / UX**: Semi-dark glassmorphism theme with fluid micro-animations, responsive layout, smooth transitions, and distinct typography.
- **Zero GUI Freezing**: All extraction, searching, downloading, merging, and database operations execute asynchronously via dedicated `QThread` workers with throttled progress reporting.
- **Single Video Downloader**:
  - Automatically handles standard YouTube URLs, `youtu.be`, and YouTube Shorts (`/shorts/`).
  - Quality Presets: `Best`, `2160p (4K)`, `1440p (2K)`, `1080p`, `720p`, `480p`, `360p`.
  - Output Containers: `MP4`, `WebM`, `MKV`.
- **Advanced Format Inspector**:
  - Query real available video and audio streams via yt-dlp.
  - Filter streams by type (`Video Only`, `Audio Only`, `Combined`).
  - Select custom video and audio format IDs for precise merging.
- **Dedicated Audio Extraction**:
  - Source formats: Best audio, MP3, M4A, FLAC, OPUS, WAV, AAC, Vorbis, ALAC.
  - Automated metadata embedding (Title, Artist, Album).
  - Automated high-resolution cover art embedding directly from YouTube thumbnails into ID3/Vorbis tags.
- **Full YouTube Search**:
  - Integrated YouTube search with thumbnail previews, duration, channel name, and view counts without requiring a paid Google API key.
- **Playlist Downloader & Range Selector**:
  - Flat metadata extraction preventing UI lag even on large playlists.
  - Interactive selection: `Select All`, `Clear All`, `Invert Selection`.
  - Range selection (e.g. entries `10` through `32`) and `Select First N` items.
  - Semantic global quality configuration across all items.
- **Batch Downloader & .TXT Import**:
  - Multi-line text editor supporting both direct URLs and text search queries.
  - Automatic query resolution with reviewable item cards before queueing.
  - Import `.txt` files with duplicate detection, validation breakdown, and drag-and-drop support.
- **Standalone Thumbnail Downloader**:
  - Download full-resolution video thumbnails directly to `%USERPROFILE%\Downloads\Soldiers` without fetching video streams.
- **Multi-Download Queue Manager**:
  - Configurable concurrent downloads (default 5, adjustable 1–10).
  - Real-time progress, speed (MB/s), ETA countdown, downloaded/total size.
  - Per-item controls: `Cancel`, `Retry`, `Open File`, `Open Folder`, `Remove`.
  - Automatic duplicate skipping / overwriting.
- **Persistent SQLite History**:
  - Local SQLite database stored in `%LOCALAPPDATA%\SoldierDownloader\history.db`.
  - Searchable and filterable history (`All`, `Completed`, `Failed`, `Cancelled`, `Audio`, `Video`).
  - File existence verification and stale file cleanup.
- **Windows System Tray Integration**:
  - Minimize to tray on close, keeping active downloads running in the background.
  - Tray context menu: Show/Restore, Pause New Downloads, Resume, Exit.
- **Self-Healing Environment & Error Handling**:
  - Startup checks for `yt-dlp`, `ffmpeg`, `ffprobe`, and `cookies.txt`.
  - Friendly human-readable error translations (geo-blocks, age restrictions, private videos, network timeouts).
  - Private `cookies.txt` support for authenticated content without exposing credentials in logs.

---

## 📋 System Requirements

1. **Operating System**: Windows 10 or Windows 11 (64-bit)
2. **Python**: Python 3.10+ (tested and verified on Python 3.14)
3. **FFmpeg & FFprobe**: Installed and accessible via Windows `PATH`.

### Verify External Prerequisites

Open Command Prompt or PowerShell:

```cmd
ffmpeg -version
ffprobe -version
```

If FFmpeg is not installed:
- Download a build from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) or install via winget:
  ```cmd
  winget install Gyan.FFmpeg
  ```
- Ensure the `bin` directory containing `ffmpeg.exe` and `ffprobe.exe` is added to your Windows user or system `PATH`.

---

## 🚀 Installation & Setup

1. **Clone or Navigate to the Repository**:
   ```cmd
   cd /d "d:\my workspace\Personal_Tools\soldier_downloader"
   ```

2. **Create and Activate a Virtual Environment**:
   ```cmd
   python -m venv .venv
   .venv\Scripts\activate
   ```

3. **Install Dependencies**:
   ```cmd
   pip install -r requirements.txt
   ```

---

## 🔑 cookies.txt (Optional Authentication)

To download age-restricted or members-only videos that you are authorized to view:
1. Export your YouTube cookies using a standard browser extension (e.g. "Get cookies.txt LOCALLY").
2. Place the exported file as `cookies.txt` in the root folder of this project (`d:\my workspace\Personal_Tools\soldier_downloader\cookies.txt`).
3. Soldier Downloader will automatically detect and apply `cookies.txt`.

> [!WARNING]
> `cookies.txt` contains your active session credentials. Soldier Downloader keeps it strictly local and never logs or transmits its contents anywhere other than directly to YouTube via yt-dlp. Never share this file.

---

## 🏃 Running the Application

Run the application directly using Python:

```cmd
python main.py
```

### Running with Debug Mode
To inspect detailed verbose extractor outputs:
```cmd
python main.py --debug
```

---

## 🧪 Running Tests

To run the complete suite of unit and integration tests (38 tests covering filename sanitization, batch parsing, range selection, validators, settings, history DB, queue transitions, error translations, and QML loading):

```cmd
pytest -v
```

---

## 📦 Building Standalone Windows Executable (.exe)

Soldier Downloader includes pre-configured PyInstaller specifications:

1. Activate your virtual environment:
   ```cmd
   .venv\Scripts\activate
   pip install pyinstaller
   ```
2. Run the build script:
   ```cmd
   packaging\build_exe.bat
   ```
   Or run PyInstaller directly:
   ```cmd
   pyinstaller --clean --noconfirm packaging\SoldierDownloader.spec
   ```
3. The portable standalone application will be generated in `dist\SoldierDownloader\SoldierDownloader.exe`.

---

## 📂 Storage Paths

- **Default Download Directory**: `%USERPROFILE%\Downloads\Soldiers`
- **Application Database**: `%LOCALAPPDATA%\SoldierDownloader\history.db`
- **Application Settings**: `%LOCALAPPDATA%\SoldierDownloader\settings.json`
- **Log Files**: `%LOCALAPPDATA%\SoldierDownloader\logs\soldier_downloader.log`
- **Temporary Work Directory**: `%LOCALAPPDATA%\SoldierDownloader\temp`

---

## 📄 License & Safety Notice

Soldier Downloader is intended for personal use and downloading content you have the authorization to access. It does not bypass DRM or violate platform security controls; all media extraction utilizes standard yt-dlp mechanisms.
