"""Stage a finished reel for review after it's synced to the VPS.

Confirms marketing/outputs/daily_video/<date>/final.mp4 exists locally and
upserts a clean 'pending' social_posts row for it (no Discord message id,
no slide_urls/caption — the bot builds the reel caption from narration.txt
+ the story row). The Discord publisher bot polls for pending rows lacking a
message id, renders a 720p review preview if needed, and posts it with ✅/❌
buttons. The publisher bot then publishes only after an approver approves —
this review is independent of the carousel's.

Run from scripts/ (normally invoked by upload_reel_to_vps.sh AFTER rsync):

    uv run python -m send_reel_for_review             # today
    uv run python -m send_reel_for_review 2026-07-05
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_publisher.config import Config
from lorescape_publisher import post_log

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_VIDEO_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_video"


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "publisher" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", default=date.today().isoformat(),
        help="Publish date YYYY-MM-DD (default: today)",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()

    video_path = DAILY_VIDEO_DIR / args.date / "final.mp4"
    if not video_path.is_file():
        print(f"final.mp4 not found: {video_path}", file=sys.stderr)
        return 1

    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    post_log.stage_pending(
        supabase, publish_date=args.date, media_type="reel"
    )
    print(
        "已上傳影片並建立 pending row。發布 bot 會在 Discord 貼審核訊息；"
        "按 🚀 立即發布，或核准後到排程時間才發。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
