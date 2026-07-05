"""21:10 Asia/Taipei reel publish job: post the day's video to IG Reels.

The reel has its own Discord review, fully independent of the carousel's:
the local send-for-review step (scripts/send_reel_for_review.py) posts the
video to the review channel and creates a 'pending' social_posts row with
the message id. This job reads that message's ✅/❌ reactions and drives
the row's state machine:

    pending → published  (approver ✅ → IG publish succeeded)
    pending → failed     (publish call raised; retried on the next run)
    pending → rejected   (approver ❌)
    pending → skipped    (no reaction by the final 23:10 pass)

The 21:10 run leaves an unreacted row in 'pending' so a late ✅ still
publishes at 23:10; the 23:10 run (`final_pass=True`) marks it 'skipped',
matching the carousel's semantics. Re-runs are idempotent: published /
rejected / skipped rows are never touched again.

The video is expected at `<DAILY_VIDEO_DIR>/<date>/final.mp4`, rsynced from
the operator's machine (see scripts/upload_reel_to_vps.sh). A sibling
narration.txt supplies the caption's hook line.

Manual CLI (back-fill / debugging):
    python -m lorescape_backend.social.reel_publisher [YYYY-MM-DD] [--dry-run]
"""
from __future__ import annotations

import logging
from datetime import date
from pathlib import Path

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_notify, discord_review
from lorescape_backend.social import caption, instagram, post_log, reel_cover

logger = logging.getLogger(__name__)

VIDEO_FILENAME = "final.mp4"
NARRATION_FILENAME = "narration.txt"


def run_reel_publish_job(
    config: Config,
    target_date: date | None = None,
    *,
    dry_run: bool = False,
    final_pass: bool = False,
) -> None:
    """Publish the day's reel once its own Discord review is approved."""
    if target_date is None:
        target_date = date.today()
    date_str = target_date.isoformat()

    if not config.daily_video_dir:
        logger.warning(
            "DAILY_VIDEO_DIR not set — reel publish job disabled"
        )
        return

    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )

    row = post_log.get_post(supabase, date_str, "reel")
    if row is None:
        logger.info("No reel review row for %s; nothing to publish", date_str)
        if not final_pass:
            _notify(
                config,
                date_str,
                "Reel publish: no reel was sent for review today — run "
                "scripts/upload_reel_to_vps.sh, or publish manually via "
                "/publish-reel.",
            )
        return
    status = row.get("status")
    if status in ("published", "rejected", "skipped"):
        logger.info(
            "Reel for %s already in terminal state '%s'; nothing to do",
            date_str, status,
        )
        return

    # status is 'pending' or 'failed' (failed = approved but the publish
    # attempt raised; re-check the reaction and retry).
    message_id = row.get("discord_message_id")
    if not message_id or not config.review_enabled:
        logger.warning(
            "Reel row for %s has no reviewable message (message_id=%s, "
            "review_enabled=%s); leaving as-is",
            date_str, message_id, config.review_enabled,
        )
        return

    decision = discord_review.check_reaction(
        bot_token=config.discord_bot_token,  # type: ignore[arg-type]
        channel_id=config.discord_review_channel_id,  # type: ignore[arg-type]
        message_id=message_id,
        approver_ids=config.discord_approver_ids,
    )
    if decision == "rejected":
        logger.info("Reel for %s rejected by reviewer", date_str)
        if not dry_run:
            post_log.mark_status(
                supabase, publish_date=date_str, media_type="reel",
                status="rejected",
            )
        return
    if decision == "none":
        if final_pass:
            logger.info(
                "Reel for %s got no reaction by the final pass; marking "
                "skipped", date_str,
            )
            if not dry_run:
                post_log.mark_status(
                    supabase, publish_date=date_str, media_type="reel",
                    status="skipped",
                )
        else:
            logger.info(
                "Reel for %s has no reaction yet; leaving pending for the "
                "23:10 pass", date_str,
            )
        return

    # decision == "approved"
    video_path = Path(config.daily_video_dir) / date_str / VIDEO_FILENAME
    if not video_path.is_file():
        logger.warning("No reel video at %s; cannot publish", video_path)
        _notify(
            config,
            date_str,
            f"Reel publish: approved but no video at {video_path} — "
            f"re-run scripts/upload_reel_to_vps.sh.",
        )
        return

    ig_caption = _build_caption(config, supabase, date_str, video_path.parent)

    cover_url: str | None = None
    try:
        cover_url = reel_cover.build_cover_url(supabase, date_str)
    except Exception as exc:  # noqa: BLE001 — cover is best-effort
        logger.warning("Could not build reel cover (%s); using video frame",
                       exc)

    if dry_run:
        print("[dry-run] decision: approved")
        print(f"[dry-run] video:   {video_path}")
        print(f"[dry-run] cover:   {cover_url or '(none — video frame)'}")
        print(f"[dry-run] caption:\n{ig_caption}")
        return

    if not config.instagram_enabled:
        logger.warning("Instagram not configured; skipping reel publish")
        return

    try:
        ig_post_id = instagram.publish_reel(
            ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
            access_token=config.meta_page_access_token,  # type: ignore[arg-type]
            video_path=str(video_path),
            caption=ig_caption,
            cover_url=cover_url,
        )
    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Reel publish failed for %s", date_str)
        post_log.record_post(
            supabase,
            publish_date=date_str,
            media_type="reel",
            status="failed",
            error=_truncate(str(exc), 1000),
        )
        _notify(config, date_str, f"Reel publish failed: {exc}")
        return

    post_log.record_post(
        supabase,
        publish_date=date_str,
        media_type="reel",
        status="published",
        ig_post_id=ig_post_id,
    )
    logger.info("Published reel for %s: %s", date_str, ig_post_id)


def _build_caption(
    config: Config, supabase, date_str: str, day_dir: Path
) -> str:
    """Caption from the day's story row, falling back to narration.txt."""
    narration_path = day_dir / NARRATION_FILENAME
    narration_text = (
        narration_path.read_text(encoding="utf-8").strip()
        if narration_path.is_file()
        else None
    )
    row = reel_cover.load_story_row(supabase, date_str)
    if row is None:
        return narration_text or ""
    story_copy = caption.StoryCopy(
        place_name=row["place_name"],
        era=row["era"],
        story=row["story"],
        hashtags=tuple(row.get("hashtags") or ()),
        image_attribution=row.get("image_attribution"),
        hook=reel_cover.narration_hook(narration_text),
    )
    return caption.build_full_caption(
        story=story_copy,
        brand_handle=config.brand_handle_ig,
        cta_text=config.cta_text,
    )


def _notify(config: Config, date_str: str, message: str) -> None:
    if not config.discord_webhook_url:
        return
    discord_notify.notify_failure(
        webhook_url=config.discord_webhook_url,
        date_str=date_str,
        error_message=message,
        traceback_str="",
    )


def _truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"


def main() -> None:
    """CLI: `python -m lorescape_backend.social.reel_publisher [date] [--dry-run]`."""
    import argparse

    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", help="Publish date YYYY-MM-DD (default: today)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print the decision, video, cover and caption without "
             "publishing",
    )
    parser.add_argument(
        "--final-pass", action="store_true",
        help="Mark an unreacted review as skipped (the 23:10 behaviour)",
    )
    args = parser.parse_args()

    config = Config.from_env()
    target = date.fromisoformat(args.date) if args.date else date.today()
    run_reel_publish_job(
        config, target, dry_run=args.dry_run, final_pass=args.final_pass
    )


if __name__ == "__main__":
    main()
