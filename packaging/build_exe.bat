@echo off
echo ========================================================
echo Building Soldier Downloader Windows Standalone Executable
echo ========================================================

REM Check if PyInstaller is installed
python -m pip show pyinstaller >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] PyInstaller not detected. Installing pyinstaller...
    python -m pip install pyinstaller
)

echo [INFO] Running PyInstaller build...
pyinstaller --clean --noconfirm packaging\SoldierDownloader.spec

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo Build Successful!
    echo Standalone executable is located at:
    echo dist\SoldierDownloader\SoldierDownloader.exe
    echo ========================================================
) else (
    echo.
    echo [ERROR] Build failed! Check the error log output above.
)

pause
