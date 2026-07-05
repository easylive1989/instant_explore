"""21:10 Asia/Taipei reel publish job: post the day's video to IG Reels.

Runs after the 21:00 carousel job. Gate and idempotency:

- The zh-TW daily_stories row must be in review_state='published' — i.e.
  the Discord ✅ approved the story and the carousel went out. The reel
  reuses that same review; it never publishes an unapproved story.
- A social_posts row (publish_date, 'reel') with status='published' means
  the reel already went out — the job exits, so the 21:10 / 23:10
  double-schedule and manual re-runs are safe.

The video is expected at `<DAILY_VIDEO_DIR>/<date>/final.mp4`, rsynced from
the operator's machine (see scripts/upload_reel_to_vps.sh). A sibling
narration.txt supplies the caption's hook line. When the video is missing
the job notifies the Discord webhook and leaves no state behind, so a late
upload is picked up by the next scheduled run (or a manual one).

Manual CLI (back-fill / debugging):
    python -m lorescape_backend.social.reel_publisher [YYYY-MM-DD] [--dry-run]
"""
from __future__ import annotations

import logging
from datetime import date
from pathlib import Path

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_notify
from lorescape_backend.social import caption, instagram, post_log, reel_cover

logger = logging.getLogger(__name__)

VIDEO_FILENAME = "final.mp4"
NARRATION_FILENAME = "narration.txt"


def run_reel_publish_job(
    config: Config, target_date: date | None = None, *, dry_run: bool = False
) -> None:
    """Publish the day's reel if approved, present, and not yet published."""
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

    existing = post_log.get_post(supabase, date_str, "reel")
    if existing and existing.get("status") == "published":
        logger.info("Reel for %s already published; nothing to do", date_str)
        return

    row = reel_cover.load_story_row(supabase, date_str)
    if row is None:
        logger.info("No zh-TW daily_stories row for %s; skipping", date_str)
        return
    if row.get("review_state") != "published":
        logger.info(
            "Story for %s is in review_state=%s (not 'published'); "
            "skipping reel", date_str, row.get("review_state"),
        )
        return

    video_path = Path(config.daily_video_dir) / date_str / VIDEO_FILENAME
    if not video_path.is_file():
        logger.warning("No reel video at %s; skipping", video_path)
        _notify(
            config,
            date_str,
            f"Reel publish: no video at {video_path} — upload with "
            f"scripts/upload_reel_to_vps.sh or publish manually via "
            f"/publish-reel.",
        )
        return

    ig_caption = _build_caption(config, row, video_path.parent)

    cover_url: str | None = None
    try:
        cover_url = reel_cover.build_cover_url(
            supabase, date_str, story_row=row
        )
    except Exception as exc:  # noqa: BLE001 — cover is best-effort
        logger.warning("Could not build reel cover (%s); using video frame",
                       exc)

    if dry_run:
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


def _build_caption(config: Config, row: dict, day_dir: Path) -> str:
    narration_path = day_dir / NARRATION_FILENAME
    narration_text = (
        narration_path.read_text(encoding="utf-8")
        if narration_path.is_file()
        else None
    )
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
        help="Print the video, cover and caption without publishing",
    )
    args = parser.parse_args()

    config = Config.from_env()
    target = date.fromisoformat(args.date) if args.date else date.today()
    run_reel_publish_job(config, target, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
