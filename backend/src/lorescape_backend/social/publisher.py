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
the reviewer sees) and supplies the IG card + caption copy. The IG publish
outcome itself (post id / error) is recorded in the `social_posts` table
(media_type='carousel'), not on the daily_stories row.

Idempotent: only rows still in 'pending' are touched.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_notify, discord_review
from lorescape_backend.social import card_storage, caption, instagram, post_log
from lorescape_backend.social.card import mapper
from lorescape_backend.social.card.renderer import render_slides

logger = logging.getLogger(__name__)

PUBLISH_LANGUAGE = "zh-TW"


def run_publish_job(
    config: Config,
    target_date: date | None = None,
    *,
    dry_run: bool = False,
) -> None:
    """Process all pending daily_stories rows for the given date (default: today).

    When a pre-rendered (wander-style) carousel was sent for review for
    this date, that review alone decides the day's carousel and the
    default rendering flow is skipped entirely. `dry_run` prints the
    decision without publishing in the pre-rendered branch, and — when no
    pre-rendered carousel exists for this date — never falls through to
    the real default flow either.
    """
    if target_date is None:
        target_date = date.today()

    supabase = create_client(config.supabase_url, config.supabase_service_role_key)

    if _handle_prerendered(supabase, config, target_date, dry_run=dry_run):
        return

    if dry_run:
        print(
            f"[dry-run] no pre-rendered carousel for "
            f"{target_date.isoformat()}; default flow not executed"
        )
        return

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
        _update_state(supabase, row, "failed")
        post_log.record_post(
            supabase,
            publish_date=row["publish_date"],
            media_type="carousel",
            status="failed",
            ig_post_id=ig_post_id,
            error=_truncate(str(exc), 1000),
        )
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=row["publish_date"],
                error_message=f"Publish failed: {exc}",
                traceback_str="",
            )
        return

    _update_state(supabase, row, "published")
    if ig_post_id is not None or publish_error is not None:
        post_log.record_post(
            supabase,
            publish_date=row["publish_date"],
            media_type="carousel",
            status="published" if ig_post_id else "failed",
            ig_post_id=ig_post_id,
            error=publish_error,
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


def _update_state(supabase, row: dict[str, Any], new_state: str) -> None:
    payload: dict[str, Any] = {
        "review_state": new_state,
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }
    (
        supabase.table("daily_stories")
        .update(payload)
        .eq("id", row["id"])
        .execute()
    )


def _truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"


def _handle_prerendered(
    supabase, config: Config, target_date: date, *, dry_run: bool = False
) -> bool:
    """Publish a pre-rendered carousel if one was sent for review today.

    Returns True when a pre-rendered row exists (slide_urls non-empty) —
    the caller must then skip the default flow entirely, regardless of
    the outcome here.
    """
    date_str = target_date.isoformat()
    row = post_log.get_post(supabase, date_str, "carousel")
    if row is None or not row.get("slide_urls"):
        return False

    status = row.get("status")
    if status in ("published", "rejected", "skipped"):
        logger.info(
            "Pre-rendered carousel for %s already '%s'; nothing to do",
            date_str, status,
        )
        return True

    message_id = row.get("discord_message_id")
    if not message_id or not config.review_enabled:
        logger.warning(
            "Pre-rendered carousel for %s has no reviewable message "
            "(message_id=%s, review_enabled=%s); leaving pending",
            date_str, message_id, config.review_enabled,
        )
        return True

    decision = discord_review.check_reaction(
        bot_token=config.discord_bot_token,  # type: ignore[arg-type]
        channel_id=config.discord_review_channel_id,  # type: ignore[arg-type]
        message_id=message_id,
        approver_ids=config.discord_approver_ids,
    )
    slide_urls = list(row["slide_urls"])
    ig_caption = row.get("caption") or ""

    if dry_run:
        print(f"[dry-run] decision: {decision}")
        for url in slide_urls:
            print(f"[dry-run] slide:   {url}")
        print(f"[dry-run] caption:\n{ig_caption}")
        return True

    if decision == "rejected":
        post_log.mark_status(
            supabase, publish_date=date_str, media_type="carousel",
            status="rejected",
        )
        _sync_story_state(supabase, date_str, "rejected")
        return True
    if decision == "none":
        post_log.mark_status(
            supabase, publish_date=date_str, media_type="carousel",
            status="skipped",
        )
        _sync_story_state(supabase, date_str, "skipped")
        return True

    # decision == "approved"
    if not config.instagram_enabled:
        logger.warning(
            "Instagram not configured; leaving pre-rendered carousel pending"
        )
        return True
    try:
        ig_post_id = instagram.publish_carousel(
            ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
            access_token=config.meta_page_access_token,  # type: ignore[arg-type]
            image_urls=slide_urls,
            caption=ig_caption,
        )
    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Pre-rendered carousel publish failed for %s",
                         date_str)
        post_log.record_post(
            supabase, publish_date=date_str, media_type="carousel",
            status="failed", error=_truncate(str(exc), 1000),
        )
        _sync_story_state(supabase, date_str, "failed")
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=date_str,
                error_message=f"Pre-rendered carousel publish failed: {exc}",
                traceback_str="",
            )
        return True

    post_log.record_post(
        supabase, publish_date=date_str, media_type="carousel",
        status="published", ig_post_id=ig_post_id,
    )
    _sync_story_state(supabase, date_str, "published")
    logger.info("Published pre-rendered carousel for %s: %s",
                date_str, ig_post_id)
    return True


def _sync_story_state(supabase, date_str: str, new_state: str) -> None:
    """Mirror the pre-rendered carousel outcome onto the day's story row.

    Only rows still in 'pending' are touched, so a story already resolved
    by other means keeps its state; this prevents the next-day back-fill
    flow from re-sending an already-decided day.
    """
    (
        supabase.table("daily_stories")
        .update({
            "review_state": new_state,
            "reviewed_at": datetime.now(timezone.utc).isoformat(),
        })
        .eq("publish_date", date_str)
        .eq("language", PUBLISH_LANGUAGE)
        .eq("review_state", "pending")
        .execute()
    )


def main() -> None:
    """CLI: `python -m lorescape_backend.social.publisher [date] [--dry-run]`."""
    import argparse

    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", help="Publish date YYYY-MM-DD (default: today)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print decision/slides/caption without publishing; never "
             "falls through to the default (non-pre-rendered) flow",
    )
    args = parser.parse_args()

    config = Config.from_env()
    target = date.fromisoformat(args.date) if args.date else date.today()
    run_publish_job(config, target, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
