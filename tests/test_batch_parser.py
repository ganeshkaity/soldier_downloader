"""Unit tests for batch line parsing and duplicate identification."""

import pytest
from app.utils.validators import classify_input


def parse_batch_text(text: str):
    """Mirror bridge batch line parsing logic for test verification."""
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    items = []
    seen = set()

    for idx, line in enumerate(lines, start=1):
        kind, resolved = classify_input(line)
        is_dup = resolved in seen
        seen.add(resolved)

        items.append({
            "index": idx,
            "raw_text": line,
            "type": kind,
            "content": resolved,
            "is_duplicate": is_dup,
            "valid": kind in ("url", "search"),
        })

    return items


def test_batch_mixed_input():
    sample = """
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    Interstellar OST Main Theme
    https://youtu.be/dQw4w9WgXcQ
    Lo-fi hip hop radio
    
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    """
    items = parse_batch_text(sample)
    assert len(items) == 5

    # Item 1 is URL
    assert items[0]["type"] == "url"
    assert items[0]["is_duplicate"] is False

    # Item 2 is search query
    assert items[1]["type"] == "search"
    assert items[1]["is_duplicate"] is False

    # Item 3 is duplicate normalized watch URL of Item 1
    assert items[2]["type"] == "url"
    assert items[2]["is_duplicate"] is True

    # Item 4 is search query
    assert items[3]["type"] == "search"
    assert items[3]["is_duplicate"] is False

    # Item 5 is another duplicate URL
    assert items[4]["type"] == "url"
    assert items[4]["is_duplicate"] is True
