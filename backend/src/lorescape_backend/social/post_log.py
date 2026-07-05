"""Track per-day Instagram publish state in the `social_posts` table.

One row per (publish_date, media_type). For reels the row is created as
`pending` by the local send-for-review step (carrying the Discord message
id of the video review post); the publish job then moves it to
published / failed / rejected / skipped. For carousels only the outcome
is recorded (review state lives on daily_stories.review_state). Upserts
overwrite the same row, which is what makes re-running a publish job for
the same day idempotent.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

TABLE_NAME = "social_posts"


def record_review_pending(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    discord_message_id: str,
) -> None:
    """Upsert a 'pending' row pointing at the Discord review message.

    Re-sending for review (e.g. after a re-edited video) resets any prior
    state so the publish job re-reads the new message's reactions.
    """
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": "pending",
        "discord_message_id": discord_message_id,
        "ig_post_id": None,
        "error": None,
        "published_at": None,
    }
    (
        supabase.table(TABLE_NAME)
        .upsert(payload, on_conflict="publish_date,media_type")
        .execute()
    )


def mark_status(
    supabase, *, publish_date: str, media_type: str, status: str
) -> None:
    """Set the review verdict (e.g. 'rejected' / 'skipped') on the row."""
    (
        supabase.table(TABLE_NAME)
        .update({"status": status})
        .eq("publish_date", publish_date)
        .eq("media_type", media_type)
        .execute()
    )


def record_post(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    status: str,
    ig_post_id: str | None = None,
    error: str | None = None,
) -> None:
    """Upsert the publish outcome for (publish_date, media_type)."""
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": status,
        "ig_post_id": ig_post_id,
        "error": error,
        "published_at": (
            datetime.now(timezone.utc).isoformat()
            if status == "published"
            else None
        ),
    }
    (
        supabase.table(TABLE_NAME)
        .upsert(payload, on_conflict="publish_date,media_type")
        .execute()
    )


def get_post(
    supabase, publish_date: str, media_type: str
) -> dict[str, Any] | None:
    """Return the social_posts row for (publish_date, media_type), or None."""
    response = (
        supabase.table(TABLE_NAME)
        .select("*")
        .eq("publish_date", publish_date)
        .eq("media_type", media_type)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None
