"""21:00 Asia/Taipei publish job: read Discord reactions, post to Instagram.

State machine (per `daily_stories` row, only the zh-TW row is tracked):

    pending → published   (✅ reaction → IG publish succeeded)
    pending → rejected    (❌ reaction)
    pending → skipped     (no reaction by 21:00)
    pending → failed      (publish call raised; publish_error filled in)
    pending → pending     (no transition: review not configured, OR row has
                           no discord_message_id yet — both are recoverable
                           by fixing config and re-running the back-fill flow
                           described in backend/README.md)

The zh-TW row carries the review state and Discord message id (matching what
the reviewer sees) and supplies the IG card + caption copy.

Idempotent: only rows still in 'pending' are touched.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_notify, discord_review
from lorescape_backend.social import card_storage, caption, instagram
from lorescape_backend.social.card import mapper
from lorescape_backend.social.card.renderer import render_slides

logger = logging.getLogger(__name__)

PUBLISH_LANGUAGE = "zh-TW"


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
        # Don't mutate rows: a missing Discord config is recoverable, and
        # marking rows as `skipped` here would make today permanently
        # un-publishable once the operator fixes the config. Leave the rows
        # in `pending` so the back-fill flow can pick them up later.
        logger.warning(
            "Discord review not configured — leaving %d pending row(s) "
            "untouched so they can be processed after config is fixed",
            len(rows),
        )
        # Surface the silent accumulation: webhook is a separate channel from
        # the bot token, so it usually survives when review_enabled is False.
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=target_date.isoformat(),
                error_message=(
                    f"Publish job: review not configured (missing "
                    f"DISCORD_BOT_TOKEN / DISCORD_REVIEW_CHANNEL_ID / "
                    f"DISCORD_APPROVER_IDS); {len(rows)} row(s) left in "
                    f"`pending`. See backend/README.md back-fill steps."
                ),
                traceback_str="",
            )
        return

    for row in rows:
        _process_row(supabase, config, row)


def _process_row(supabase, config: Config, row: dict[str, Any]) -> None:
    message_id = row.get("discord_message_id")
    if not message_id:
        # Leave row in `pending` (don't mark skipped) so the back-fill flow
        # can recover it: operator runs `send_today_for_review` to populate
        # discord_message_id, reacts on Discord, then re-runs this job.
        logger.warning(
            "Row %s has no discord_message_id; leaving in `pending` for "
            "back-fill (see backend/README.md)", row["id"],
        )
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
    # `row` is the zh-TW pending row (carries review state); use it directly
    # for IG card + caption.
    zh_story_copy = caption.StoryCopy(
        place_name=row["place_name"],
        era=row["era"],
        story=row["story"],
        hashtags=tuple(row.get("hashtags") or ()),
        image_attribution=row.get("image_attribution"),
    )

    place_row = _load_place_row(supabase, row["place_id"])
    card_content = None
    if place_row is not None:
        card_content = mapper.build_card_content(row, place_row)

    ig_caption = None
    if card_content is not None:
        ig_caption = caption.build_full_caption(
            story=zh_story_copy,
            brand_handle=config.brand_handle_ig,
            cta_text=config.cta_text,
        )

    ig_post_id: str | None = None
    publish_error: str | None = None
    try:
        if config.instagram_enabled and card_content is not None:
            slides = render_slides(card_content)
            card_urls = [
                card_storage.upload_card_png(
                    supabase,
                    png,
                    path=f"{row['publish_date']}/{row['id']}-{index}.png",
                )
                for index, png in enumerate(slides)
            ]
            ig_post_id = instagram.publish_carousel(
                ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
                access_token=config.meta_page_access_token,  # type: ignore[arg-type]
                image_urls=card_urls,
                caption=ig_caption,  # type: ignore[arg-type]
            )
        elif card_content is None:
            logger.info(
                "Row %s missing card content; skipping IG publish", row["id"]
            )
            publish_error = "ig_skipped_missing_card_content"
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
            "ig_post_id": ig_post_id,
            "publish_error": publish_error,
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


def _load_place_row(supabase, place_id: str) -> dict[str, Any] | None:
    response = (
        supabase.table("daily_story_places")
        .select("*")
        .eq("id", place_id)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


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
