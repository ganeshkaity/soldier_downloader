"""Robust Windows filename sanitization and conflict resolution."""

import re
from pathlib import Path
from typing import Union

# Invalid characters in Windows file systems: < > : " / \ | ? * and control chars (0-31)
INVALID_CHARS_PATTERN = re.compile(r'[\<\>\:\"\/\\\|\?\*\x00-\x1f]')

# Windows reserved device names
RESERVED_NAMES = {
    "CON", "PRN", "AUX", "NUL",
    "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
    "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
}

# Maximum filename length (standard NTFS component limit is 255; 200 leaves margin for paths)
MAX_FILENAME_LEN = 200


def sanitize_filename(name: str, fallback: str = "Soldier_Download") -> str:
    """
    Sanitize a filename for Windows file systems.
    
    Removes invalid characters, handles reserved device names,
    strips trailing dots and spaces, limits length, and prevents empty strings.
    """
    if not name or not name.strip():
        name = fallback

    # Replace invalid characters with space or underscore
    cleaned = INVALID_CHARS_PATTERN.sub("_", name)

    # Replace multiple spaces with a single space
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()

    # Strip trailing dots and spaces (Windows ignores or rejects them)
    cleaned = cleaned.rstrip(". ")

    # Check for reserved device names
    base_upper = cleaned.upper()
    if base_upper in RESERVED_NAMES:
        cleaned = f"{cleaned}_file"

    # Truncate length if needed
    if len(cleaned) > MAX_FILENAME_LEN:
        cleaned = cleaned[:MAX_FILENAME_LEN].rstrip(". ")

    if not cleaned:
        cleaned = fallback

    return cleaned


def resolve_unique_path(directory: Union[str, Path], filename: str, ext: str) -> Path:
    """
    Generate a non-conflicting path in directory by appending (1), (2), etc.
    only if a collision actually exists.
    """
    dir_path = Path(directory)
    dir_path.mkdir(parents=True, exist_ok=True)
    
    clean_ext = ext if ext.startswith(".") else f".{ext}"
    sanitized_base = sanitize_filename(filename)
    
    candidate = dir_path / f"{sanitized_base}{clean_ext}"
    if not candidate.exists():
        return candidate

    counter = 1
    while True:
        candidate = dir_path / f"{sanitized_base} ({counter}){clean_ext}"
        if not candidate.exists():
            return candidate
        counter += 1
