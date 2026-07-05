"""Send the day's finished reel to Discord for review.

Posts marketing/outputs/daily_video/<date>/final.mp4 to the Discord review
channel (bot token from backend/.env), seeds ✅/❌, and upserts a 'pending'
social_posts row carrying the message id. The VPS reel job (21:10 / 23:10
Asia/Taipei) then publishes only after an approver reacts ✅ — this review
is independent of the carousel's.

Videos over Discord's 10 MB attachment limit are re-encoded to a 720p
preview (the preview is only for review; the VPS still publishes the
original final.mp4).

Run from scripts/ (normally invoked by upload_reel_to_vps.sh):

    uv run python -m send_reel_for_review             # today
    uv run python -m send_reel_for_review 2026-07-05
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_review
from lorescape_backend.social import post_log

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_VIDEO_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_video"

# Discord's attachment cap on a non-boosted server is 10 MB; leave headroom
# for the multipart envelope.
MAX_ATTACHMENT_BYTES = int(9.5 * 1024 * 1024)


def _load_video_bytes(video_path: Path) -> bytes:
    """Return video bytes, re-encoded to a 720p preview when too large."""
    if video_path.stat().st_size <= MAX_ATTACHMENT_BYTES:
        return video_path.read_bytes()
    print(
        f"{video_path.name} exceeds Discord's attachment limit; "
        f"encoding a 720p preview for review..."
    )
    with tempfile.NamedTemporaryFile(suffix=".mp4") as preview:
        subprocess.run(
            [
                "ffmpeg", "-y", "-i", str(video_path),
                "-vf", "scale=-2:720",
                "-c:v", "libx264", "-crf", "28", "-preset", "veryfast",
                "-c:a", "aac", "-b:a", "96k",
                preview.name,
            ],
            check=True,
            capture_output=True,
        )
        return Path(preview.name).read_bytes()


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv(REPO_ROOT / "backend" / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "date", nargs="?", default=date.today().isoformat(),
        help="Publish date YYYY-MM-DD (default: today)",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    if not (config.discord_bot_token and config.discord_review_channel_id):
        print(
            "Discord review not configured: set DISCORD_BOT_TOKEN and "
            "DISCORD_REVIEW_CHANNEL_ID in backend/.env",
            file=sys.stderr,
        )
        return 1

    video_path = DAILY_VIDEO_DIR / args.date / "final.mp4"
    if not video_path.is_file():
        print(f"final.mp4 not found: {video_path}", file=sys.stderr)
        return 1

    message_id = discord_review.send_video_for_review(
        bot_token=config.discord_bot_token,
        channel_id=config.discord_review_channel_id,
        video_bytes=_load_video_bytes(video_path),
        publish_date=args.date,
    )

    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    post_log.record_review_pending(
        supabase,
        publish_date=args.date,
        media_type="reel",
        discord_message_id=message_id,
    )
    print(
        f"Sent reel for review: message_id={message_id} — react ✅ before "
        f"21:10 (or 23:10) Asia/Taipei to publish."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
