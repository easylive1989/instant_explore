"""Shared helpers for publishing an IG Reel of a daily story.

Used by both the server-side reel publish job
(`lorescape_backend.social.reel_publisher`) and the local manual fallback
(`scripts/publish_reel.py`), so the Reel keeps the same cover face and
caption sources no matter which path publishes it.
"""
from __future__ import annotations

from typing import Any

from lorescape_backend.social import card_storage
from lorescape_backend.social.card import mapper, render_cover

PUBLISH_LANGUAGE = "zh-TW"


def load_story_row(supabase, date_str: str) -> dict[str, Any] | None:
    """Return the zh-TW daily_stories row for the date, or None."""
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", date_str)
        .eq("language", PUBLISH_LANGUAGE)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


def load_place_row(supabase, place_id: str) -> dict[str, Any] | None:
    """Return the daily_story_places row for the id, or None."""
    response = (
        supabase.table("daily_story_places")
        .select("*")
        .eq("id", place_id)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


def build_cover_url(
    supabase, date_str: str, *, story_row: dict[str, Any] | None = None
) -> str | None:
    """Render the carousel cover for the date and upload it; return the public
    URL so the Reel shares the same title face as the grid cards.

    Returns None (the Reel then falls back to a video frame) whenever the
    story/place data needed to render the cover is missing.
    """
    row = story_row if story_row is not None else load_story_row(
        supabase, date_str
    )
    if row is None:
        return None
    place_id = row.get("place_id")
    if not place_id:
        return None
    place_row = load_place_row(supabase, place_id)
    if place_row is None:
        return None
    content = mapper.build_card_content(row, place_row)
    if content is None:
        return None
    png = render_cover(content)
    return card_storage.upload_card_png(
        supabase, png, path=f"{date_str}/reel-cover.png"
    )


def narration_hook(narration_text: str | None) -> str | None:
    """Return the first non-empty narration line (the reel's spoken hook)."""
    if not narration_text:
        return None
    for line in narration_text.splitlines():
        stripped = line.strip()
        if stripped:
            return stripped
    return None
