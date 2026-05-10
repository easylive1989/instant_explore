"""Pick the next place for a daily story.

Strategy:
1. Try to pick an active, never-used place (used_at IS NULL), oldest first.
2. If all are used, pick the active place with the oldest used_at (re-cycle).
3. After the story is generated, call `mark_place_used` to update used_at.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass(frozen=True)
class PickedPlace:
    id: str
    wikipedia_title_en: str


def pick_next_place(supabase) -> PickedPlace | None:
    """Returns the next place, or None if no active places exist."""
    # 1. Never-used active places, oldest first
    response = (
        supabase.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .eq("is_active", True)
        .is_("used_at", "null")
        .order("created_at")
        .limit(1)
        .execute()
    )
    if response.data:
        row = response.data[0]
        return PickedPlace(id=row["id"], wikipedia_title_en=row["wikipedia_title_en"])

    # 2. Recycle: oldest used_at among active places
    response = (
        supabase.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .eq("is_active", True)
        .order("used_at")
        .limit(1)
        .execute()
    )
    if response.data:
        row = response.data[0]
        return PickedPlace(id=row["id"], wikipedia_title_en=row["wikipedia_title_en"])

    return None


def mark_place_used(supabase, place_id: str) -> None:
    """Set used_at = now() on the given place."""
    now_iso = datetime.now(timezone.utc).isoformat()
    (
        supabase.table("daily_story_places")
        .update({"used_at": now_iso})
        .eq("id", place_id)
        .execute()
    )
