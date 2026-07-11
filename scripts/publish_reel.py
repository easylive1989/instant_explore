"""Manually publish a daily video to Instagram Reels from your machine.

Reads the finished video at marketing/outputs/daily_video/<date>/final.mp4, builds the
caption from the Supabase daily story for that date (zh-TW), and publishes it
as an IG Reel using the local IG credentials in publisher/.env. This is fully
local and independent of the server's scheduled publish job — nothing is
written back to Supabase.

Run from scripts/:

    uv run python -m publish_reel 2026-06-22
    uv run python -m publish_reel 2026-06-22 --dry-run
    uv run python -m publish_reel 2026-06-22 --caption "自訂文案"
    uv run python -m publish_reel 2026-06-22 --video /path/to/clip.mp4
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_publisher.config import Config
from lorescape_publisher import caption, instagram, reel_cover

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_VIDEO_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_video"


def _resolve_video(date_str: str, override: str | None) -> Path:
    """Return the video file to publish for the given date."""
    if override:
        path = Path(override)
        if not path.is_file():
            raise FileNotFoundError(f"Video not found: {path}")
        return path
    day_dir = DAILY_VIDEO_DIR / date_str
    path = day_dir / "final.mp4"
    if not path.is_file():
        existing = (
            sorted(p.name for p in day_dir.iterdir())
            if day_dir.is_dir()
            else []
        )
        raise FileNotFoundError(
            f"final.mp4 not found in {day_dir}. Existing files: {existing}"
        )
    return path


def _read_narration(date_str: str) -> str | None:
    """Return the narration.txt text for the date, or None."""
    path = DAILY_VIDEO_DIR / date_str / "narration.txt"
    if path.is_file():
        return path.read_text(encoding="utf-8").strip()
    return None


def _build_caption(
    supabase, config, date_str: str, override: str | None
) -> str:
    """Build the IG caption: override → Supabase story → narration.txt."""
    if override:
        return override
    row = reel_cover.load_story_row(supabase, date_str)
    if row is not None:
        story_copy = caption.StoryCopy(
            place_name=row["place_name"],
            era=row["era"],
            story=row["story"],
            hashtags=tuple(row.get("hashtags") or ()),
            image_attribution=row.get("image_attribution"),
            hook=reel_cover.narration_hook(_read_narration(date_str)),
        )
        return caption.build_full_caption(
            story=story_copy,
            brand_handle=config.brand_handle_ig,
            cta_text=config.cta_text,
        )
    narration = _read_narration(date_str)
    if narration:
        return narration
    raise ValueError(
        f"No daily_stories row for {date_str} and no narration.txt; "
        f"pass --caption to provide the text."
    )


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "publisher" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("date", help="Publish date, YYYY-MM-DD")
    parser.add_argument("--caption", help="Override the caption text")
    parser.add_argument("--video", help="Override the video file path")
    parser.add_argument(
        "--no-cover",
        action="store_true",
        help="Skip the rendered carousel cover; let Meta pick a video frame",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the video and caption without publishing",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )

    video = _resolve_video(args.date, args.video)
    ig_caption = _build_caption(supabase, config, args.date, args.caption)

    cover_url: str | None = None
    if not args.no_cover:
        try:
            cover_url = reel_cover.build_cover_url(supabase, args.date)
        except Exception as exc:  # noqa: BLE001 — cover is best-effort
            print(
                f"Warning: could not build cover ({exc}); publishing "
                f"without a custom cover",
                file=sys.stderr,
            )

    if args.dry_run:
        print(f"[dry-run] video:   {video}")
        print(f"[dry-run] cover:   {cover_url or '(none — video frame)'}")
        print(f"[dry-run] caption:\n{ig_caption}")
        return 0

    if not config.instagram_enabled:
        print(
            "Instagram not configured: set IG_USER_ID and "
            "META_PAGE_ACCESS_TOKEN in publisher/.env",
            file=sys.stderr,
        )
        return 1

    try:
        post_id = instagram.publish_reel(
            ig_user_id=config.ig_user_id,
            access_token=config.meta_page_access_token,
            video_path=str(video),
            caption=ig_caption,
            cover_url=cover_url,
        )
    except Exception as exc:
        print(f"Publish failed: {exc}", file=sys.stderr)
        return 1
    print(f"Published reel: {post_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
