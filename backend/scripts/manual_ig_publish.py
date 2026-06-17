"""Manual IG publish pipeline: render card → review caption → publish to Instagram.

The daily story must already exist in daily_stories (run manual_daily_story
publish first). The `preview` command renders the card and prints the full
caption so the user can review in chat before committing. The `publish`
command runs the full pipeline: render → upload to Supabase storage → post
to Instagram → update review_state.

Usage (from backend/):
    uv run python -m scripts.manual_ig_publish preview               # today
    uv run python -m scripts.manual_ig_publish preview --date 2026-06-17
    uv run python -m scripts.manual_ig_publish publish               # today
    uv run python -m scripts.manual_ig_publish publish --date 2026-06-17
"""
from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

import os

os.environ.pop("GOOGLE_API_KEY", None)

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.social import caption as caption_mod
from lorescape_backend.social import card_storage, instagram
from lorescape_backend.social.card import mapper, renderer

CARD_PREVIEW_PATH = "/tmp/lorescape_ig_card_{date}.png"


def _supabase(config: Config):
    return create_client(config.supabase_url, config.supabase_service_role_key)


def _load_rows(supabase, publish_date: date) -> tuple[dict, dict]:
    """Return (zh_row, place_row) for the given date or raise SystemExit."""
    result = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", publish_date.isoformat())
        .eq("language", "zh-TW")
        .execute()
    )
    if not result.data:
        raise SystemExit(
            f"No zh-TW daily_story for {publish_date}. "
            "Run manual_daily_story publish first."
        )
    zh_row = result.data[0]

    place_result = (
        supabase.table("daily_story_places")
        .select("id, wikipedia_title_en, card_location_en, card_city_ch, "
                "card_city_en, latitude, longitude")
        .eq("id", zh_row["place_id"])
        .execute()
    )
    if not place_result.data:
        raise SystemExit(f"Place row not found for id={zh_row['place_id']}")

    return zh_row, place_result.data[0]


def _build_caption(zh_row: dict, config: Config) -> str:
    copy = caption_mod.StoryCopy(
        place_name=zh_row["place_name"],
        era=zh_row.get("era", ""),
        story=zh_row.get("story", ""),
        hashtags=tuple(zh_row.get("hashtags") or []),
        image_attribution=zh_row.get("image_attribution"),
    )
    return caption_mod.build_full_caption(
        story=copy,
        brand_handle=config.brand_handle_ig,
        cta_text=config.cta_text,
    )


def cmd_preview(args: argparse.Namespace) -> int:
    config = Config.from_env()
    supabase = _supabase(config)
    publish_date = date.fromisoformat(args.date) if args.date else date.today()

    zh_row, place_row = _load_rows(supabase, publish_date)

    full_caption = _build_caption(zh_row, config)

    card_content = mapper.build_card_content(zh_row, place_row)
    if card_content is None:
        print(
            "WARNING: Card content incomplete — IG card cannot be rendered.\n"
            "Check that daily_story_places has card_location_en / card_city_ch "
            "/ card_city_en / latitude / longitude for this place.",
            file=sys.stderr,
        )
        print(f"\n{'='*72}\nCAPTION ({len(full_caption)} chars)\n{'='*72}")
        print(full_caption)
        return 1

    png_bytes = renderer.render_card(card_content)
    preview_path = Path(CARD_PREVIEW_PATH.format(date=publish_date))
    preview_path.write_bytes(png_bytes)

    print(f"Card  → {preview_path}  ({len(png_bytes) // 1024} KB)")
    print(f"\n{'='*72}\nCAPTION ({len(full_caption)} chars)\n{'='*72}")
    print(full_caption)
    return 0


def cmd_publish(args: argparse.Namespace) -> int:
    config = Config.from_env()
    if not config.instagram_enabled:
        raise SystemExit(
            "Instagram not configured — set IG_USER_ID and "
            "META_PAGE_ACCESS_TOKEN in backend/.env"
        )

    supabase = _supabase(config)
    publish_date = date.fromisoformat(args.date) if args.date else date.today()

    zh_row, place_row = _load_rows(supabase, publish_date)

    full_caption = _build_caption(zh_row, config)

    card_content = mapper.build_card_content(zh_row, place_row)
    if card_content is None:
        raise SystemExit(
            "Card content incomplete — cannot publish. "
            "Check daily_story_places fields for this place."
        )

    print("Rendering card...", file=sys.stderr)
    png_bytes = renderer.render_card(card_content)
    print(f"  {len(png_bytes) // 1024} KB", file=sys.stderr)

    storage_path = f"{publish_date}/{zh_row['id']}.png"
    print(f"Uploading to Supabase storage ({storage_path})...", file=sys.stderr)
    image_url = card_storage.upload_card_png(
        supabase, png_bytes, path=storage_path
    )
    print(f"  {image_url}", file=sys.stderr)

    print("Publishing to Instagram...", file=sys.stderr)
    ig_post_id = instagram.publish(
        ig_user_id=config.ig_user_id,
        access_token=config.meta_page_access_token,
        image_url=image_url,
        caption=full_caption,
    )
    print(f"  ig_post_id={ig_post_id}", file=sys.stderr)

    supabase.table("daily_stories").update({
        "review_state": "published",
        "ig_post_id": ig_post_id,
    }).eq("id", zh_row["id"]).execute()

    print(f"\nPublished! ig_post_id={ig_post_id}")
    print(f"daily_stories row {zh_row['id']} → review_state=published")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    preview_p = sub.add_parser("preview", help="Render card + print caption (no DB/IG writes)")
    preview_p.add_argument("--date", help="YYYY-MM-DD (default: today)")
    preview_p.set_defaults(func=cmd_preview)

    publish_p = sub.add_parser("publish", help="Render → upload → post to IG → update DB")
    publish_p.add_argument("--date", help="YYYY-MM-DD (default: today)")
    publish_p.set_defaults(func=cmd_publish)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
