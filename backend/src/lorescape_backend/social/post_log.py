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
    slide_urls: list[str] | None = None,
    caption: str | None = None,
) -> None:
    """Upsert a 'pending' row pointing at the Discord review message.

    For pre-rendered carousels, `slide_urls` carries the uploaded slide
    URLs and `caption` the reviewed IG caption; the 21:00 publish job then
    publishes these exact images. Re-sending for review resets any prior
    state so the publish job re-reads the new message's reactions.
    """
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": "pending",
        "discord_message_id": discord_message_id,
        "slide_urls": slide_urls,
        "caption": caption,
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


def stage_pending(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    slide_urls: list[str] | None = None,
    caption: str | None = None,
) -> None:
    """本地產製後建立一筆乾淨的 pending row（尚未貼 Discord）。"""
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": "pending",
        "discord_message_id": None,
        "review_decision": None,
        "scheduled_at": None,
        "reviewed_by": None,
        "reviewed_at": None,
        "overdue_notified_at": None,
        "slide_urls": slide_urls,
        "caption": caption,
        "ig_post_id": None,
        "error": None,
        "published_at": None,
    }
    (
        supabase.table(TABLE_NAME)
        .upsert(payload, on_conflict="publish_date,media_type")
        .execute()
    )


def set_discord_message_id(
    supabase, *, publish_date: str, media_type: str, discord_message_id: str
) -> None:
    """bot 貼完審核訊息後回填 message id。"""
    _update(
        supabase, publish_date, media_type,
        {"discord_message_id": discord_message_id},
    )


def set_review_decision(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    decision: str,
    reviewed_by: str | None,
) -> None:
    """寫審核意圖（approved / rejected）與稽核欄位。"""
    _update(
        supabase, publish_date, media_type,
        {
            "review_decision": decision,
            "reviewed_by": reviewed_by,
            "reviewed_at": datetime.now(timezone.utc).isoformat(),
        },
    )


def set_schedule(
    supabase, *, publish_date: str, media_type: str, scheduled_at: str
) -> None:
    """設排程時間並把狀態切到 'scheduled'。"""
    _update(
        supabase, publish_date, media_type,
        {"scheduled_at": scheduled_at, "status": "scheduled"},
    )


def mark_overdue_notified(
    supabase, *, publish_date: str, media_type: str
) -> None:
    """記下已對「排程到點但未核准」提醒過一次。"""
    _update(
        supabase, publish_date, media_type,
        {"overdue_notified_at": datetime.now(timezone.utc).isoformat()},
    )


def list_pending_unposted(supabase) -> list[dict[str, Any]]:
    """status='pending' 且還沒貼過 Discord 的 row。"""
    response = (
        supabase.table(TABLE_NAME)
        .select("*")
        .eq("status", "pending")
        .is_("discord_message_id", "null")
        .execute()
    )
    return response.data or []


def list_scheduled_due(supabase, now_iso: str) -> list[dict[str, Any]]:
    """status='scheduled' 且 scheduled_at 已到的 row。"""
    response = (
        supabase.table(TABLE_NAME)
        .select("*")
        .eq("status", "scheduled")
        .lte("scheduled_at", now_iso)
        .execute()
    )
    return response.data or []


def _update(
    supabase, publish_date: str, media_type: str, patch: dict[str, Any]
) -> None:
    (
        supabase.table(TABLE_NAME)
        .update(patch)
        .eq("publish_date", publish_date)
        .eq("media_type", media_type)
        .execute()
    )
