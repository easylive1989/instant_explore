"""21:00 Asia/Taipei publish job: read Discord reactions, post to Threads/IG.

State machine (per `daily_stories` row, only the en row is published):

    pending → published   (✅ reaction → both APIs called, at least Threads OK)
    pending → rejected    (❌ reaction)
    pending → skipped     (no reaction by 21:00, or no image and Threads
                          itself is disabled by config)
    pending → failed      (publish call raised; publish_error filled in)

Idempotent: only rows still in 'pending' are touched.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_notify, discord_review
from lorescape_backend.social import caption, instagram, threads

logger = logging.getLogger(__name__)

PUBLISH_LANGUAGE = "en"


def run_publish_job(config: Config, target_date: date | None = None) -> None:
    """Process all pending daily_stories rows for the given date (default: today)."""
    if target_date is None:
        target_date = date.today()

    supabase = create_client(config.supabase_url, config.supabase_service_role_key)
    rows = _load_pending_rows(supabase, target_date)

    if not rows:
        logger.info("No pending rows for %s", target_date.isoformat())
        return

    if not config.review_enabled:
        logger.warning(
            "Discord review not configured — marking %d pending row(s) as skipped",
            len(rows),
        )
        for row in rows:
            _update_state(supabase, row, "skipped")
        return

    for row in rows:
        _process_row(supabase, config, row)


def _process_row(supabase, config: Config, row: dict[str, Any]) -> None:
    message_id = row.get("discord_message_id")
    if not message_id:
        logger.warning("Row %s has no discord_message_id; marking skipped", row["id"])
        _update_state(supabase, row, "skipped")
        return

    decision = discord_review.check_reaction(
        bot_token=config.discord_bot_token,  # type: ignore[arg-type]
        channel_id=config.discord_review_channel_id,  # type: ignore[arg-type]
        message_id=message_id,
        approver_ids=config.discord_approver_ids,
    )

    if decision == "rejected":
        _update_state(supabase, row, "rejected")
        return
    if decision == "none":
        _update_state(supabase, row, "skipped")
        return

    # decision == "approved"
    _try_publish(supabase, config, row)


def _try_publish(supabase, config: Config, row: dict[str, Any]) -> None:
    story_copy = caption.StoryCopy(
        place_name=row["place_name"],
        era=row["era"],
        story=row["story"],
        threads_summary=row["threads_summary"] or "",
        hashtags=tuple(row.get("hashtags") or ()),
    )
    threads_text = caption.build_threads_caption(
        story=story_copy,
        brand_handle=config.brand_handle_threads,
        cta_text=config.cta_text,
    )
    ig_text = caption.build_full_caption(
        story=story_copy,
        brand_handle=config.brand_handle_ig,
        cta_text=config.cta_text,
    )

    threads_post_id: str | None = None
    ig_post_id: str | None = None
    try:
        if config.threads_enabled:
            threads_post_id = threads.publish(
                user_id=config.threads_user_id,  # type: ignore[arg-type]
                access_token=config.threads_access_token,  # type: ignore[arg-type]
                text=threads_text,
                image_url=row.get("image_url"),
            )
        else:
            logger.info("Threads not configured; skipping Threads publish")

        if config.instagram_enabled and row.get("image_url"):
            ig_post_id = instagram.publish(
                ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
                access_token=config.meta_page_access_token,  # type: ignore[arg-type]
                image_url=row["image_url"],
                caption=ig_text,
            )
        elif not row.get("image_url"):
            logger.info("Row %s has no image_url; skipping IG publish", row["id"])
        else:
            logger.info("Instagram not configured; skipping IG publish")

    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Publish failed for row %s", row["id"])
        _update_state(
            supabase,
            row,
            "failed",
            extra={
                "publish_error": _truncate(str(exc), 1000),
                "threads_post_id": threads_post_id,
                "ig_post_id": ig_post_id,
            },
        )
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=row["publish_date"],
                error_message=f"Publish failed: {exc}",
                traceback_str="",
            )
        return

    _update_state(
        supabase,
        row,
        "published",
        extra={
            "threads_post_id": threads_post_id,
            "ig_post_id": ig_post_id,
        },
    )


def _load_pending_rows(supabase, target_date: date) -> list[dict[str, Any]]:
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", target_date.isoformat())
        .eq("language", PUBLISH_LANGUAGE)
        .eq("review_state", "pending")
        .execute()
    )
    return response.data or []


def _update_state(
    supabase,
    row: dict[str, Any],
    new_state: str,
    *,
    extra: dict[str, Any] | None = None,
) -> None:
    now = datetime.now(timezone.utc).isoformat()
    payload: dict[str, Any] = {
        "review_state": new_state,
        "reviewed_at": now,
    }
    if new_state == "published":
        payload["published_at"] = now
    if extra:
        payload.update(extra)
    (
        supabase.table("daily_stories")
        .update(payload)
        .eq("id", row["id"])
        .execute()
    )


def _truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"


def main() -> None:
    """CLI entrypoint: `python -m lorescape_backend.social.publisher [YYYY-MM-DD]`."""
    import logging
    import sys

    logging.basicConfig(level=logging.INFO)

    config = Config.from_env()
    target = (
        date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()
    )
    run_publish_job(config, target)


if __name__ == "__main__":
    main()
