"""Unit tests for Windows filename sanitization and conflict resolution."""

import os
from pathlib import Path
import pytest
from app.utils.filename import sanitize_filename, resolve_unique_path, RESERVED_NAMES


def test_sanitize_clean_string():
    name = "Normal Video Title"
    assert sanitize_filename(name) == "Normal Video Title"


def test_sanitize_windows_invalid_chars():
    name = 'Video <Title> : With "Special/Chars" | And * Questions?'
    cleaned = sanitize_filename(name)
    for bad_char in ['<', '>', ':', '"', '/', '\\', '|', '?', '*']:
        assert bad_char not in cleaned


def test_sanitize_trailing_dots_and_spaces():
    name = "Some Title with Trailing Dots and Spaces...   "
    cleaned = sanitize_filename(name)
    assert not cleaned.endswith(".")
    assert not cleaned.endswith(" ")
    assert cleaned == "Some Title with Trailing Dots and Spaces"


def test_sanitize_reserved_windows_names():
    for res in ["CON", "PRN", "AUX", "NUL", "COM1", "LPT1"]:
        cleaned = sanitize_filename(res)
        assert cleaned.upper() not in RESERVED_NAMES
        assert cleaned.startswith(res)


def test_sanitize_empty_or_whitespace():
    assert sanitize_filename("") == "Soldier_Download"
    assert sanitize_filename("   ") == "Soldier_Download"
    assert sanitize_filename(None) == "Soldier_Download"


def test_sanitize_long_filename():
    long_name = "A" * 300
    cleaned = sanitize_filename(long_name)
    assert len(cleaned) <= 200


def test_resolve_unique_path(tmp_path):
    f1 = resolve_unique_path(tmp_path, "MyFile", ".mp4")
    assert f1.name == "MyFile.mp4"
    f1.touch()

    # Second candidate must resolve with (1)
    f2 = resolve_unique_path(tmp_path, "MyFile", ".mp4")
    assert f2.name == "MyFile (1).mp4"
    f2.touch()

    # Third candidate must resolve with (2)
    f3 = resolve_unique_path(tmp_path, "MyFile", ".mp4")
    assert f3.name == "MyFile (2).mp4"
