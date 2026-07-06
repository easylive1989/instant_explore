"""Send a wander-style carousel to Discord for review + stage it for publish.

Reads marketing/outputs/daily_carousel/<date>/slide_*.jpg + caption.txt
(rendered by `python -m lorescape_backend.social.wander.renderer`), uploads
the slides to the public `ig-cards` bucket (wander/<date>/slide_NN.jpg),
posts them all in ONE Discord review message seeded with ✅/❌, and upserts
a 'pending' social_posts row carrying the message id, the slide URLs and
the caption. The VPS 21:00 publish job then publishes exactly these images
once an approver reacts ✅ — the default carousel rendering is skipped for
that day.

Run from scripts/:

    uv run python -m send_carousel_for_review             # today
    uv run python -m send_carousel_for_review 2026-07-06
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_review
from lorescape_backend.social import card_storage, post_log

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_CAROUSEL_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_carousel"

# Discord attachment cap on a non-boosted server (per file), with headroom —
# same convention as send_reel_for_review.py. Rendered slides are ~1 MB so
# hitting this means something went wrong upstream.
MAX_ATTACHMENT_BYTES = int(9.5 * 1024 * 1024)


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

    day_dir = DAILY_CAROUSEL_DIR / args.date
    slide_paths = sorted(day_dir.glob("slide_*.jpg"))
    caption_path = day_dir / "caption.txt"
    if not slide_paths:
        print(f"no slide_*.jpg found in {day_dir}", file=sys.stderr)
        return 1
    if not caption_path.is_file():
        print(f"caption.txt not found in {day_dir}", file=sys.stderr)
        return 1
    caption = caption_path.read_text(encoding="utf-8").strip()

    slide_bytes = [p.read_bytes() for p in slide_paths]
    for path, data in zip(slide_paths, slide_bytes):
        if len(data) > MAX_ATTACHMENT_BYTES:
            print(
                f"{path.name} is {len(data)} bytes — over the Discord "
                f"attachment limit; re-render with lower quality",
                file=sys.stderr,
            )
            return 1

    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    slide_urls = [
        card_storage.upload_card_image(
            supabase, data,
            path=f"wander/{args.date}/{path.name}",
            content_type="image/jpeg",
        )
        for path, data in zip(slide_paths, slide_bytes)
    ]

    message_id = discord_review.send_images_for_review(
        bot_token=config.discord_bot_token,
        channel_id=config.discord_review_channel_id,
        images=slide_bytes,
        publish_date=args.date,
    )
    post_log.record_review_pending(
        supabase,
        publish_date=args.date,
        media_type="carousel",
        discord_message_id=message_id,
        slide_urls=slide_urls,
        caption=caption,
    )
    print(
        f"Sent {len(slide_urls)} slides for review: message_id={message_id}"
        f" — react ✅ before 21:00 Asia/Taipei to publish."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
