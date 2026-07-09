"""Upload a wander-style carousel's slides and stage it for review.

Reads marketing/outputs/daily_carousel/<date>/slide_*.jpg + caption.txt
(rendered by `python -m lorescape_backend.social.wander.renderer`), uploads
the slides to the public `ig-cards` bucket (wander/<date>/slide_NN.jpg),
and upserts a clean 'pending' social_posts row carrying the slide URLs and
the caption (no Discord message id yet). The Discord publisher bot polls for
pending rows lacking a message id, posts the review message with ✅/❌
buttons, and publishes exactly these images once an approver approves — the
default carousel rendering is skipped for that day.

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
from lorescape_backend.social import card_storage, post_log

REPO_ROOT = Path(__file__).resolve().parents[1]
DAILY_CAROUSEL_DIR = REPO_ROOT / "marketing" / "outputs" / "daily_carousel"


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
    post_log.stage_pending(
        supabase,
        publish_date=args.date,
        media_type="carousel",
        slide_urls=slide_urls,
        caption=caption,
    )
    print(
        f"Uploaded {len(slide_urls)} slides + staged pending row for "
        f"{args.date}. 發布 bot 會在一分鐘內於 Discord 貼審核訊息。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
