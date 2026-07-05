"""Record per-day Instagram publish outcomes in the `social_posts` table.

One row per (publish_date, media_type). A publish attempt upserts its row:
`status='published'` on success (with `ig_post_id`), `status='failed'` on
error (with the error text). Retries overwrite the same row, which is what
makes re-running a publish job for the same day idempotent.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

TABLE_NAME = "social_posts"


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
