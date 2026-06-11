"""Manual daily-story pipeline: generate → review in chat → publish.

Replaces the paused 08:00 cron with an interactive flow driven from a
Claude Code session (see .claude/skills/lorescape-manual-daily-story):

    1. `generate` picks the next place from daily_story_places (or a
       specific one), fetches Wikipedia material, generates the zh-TW and
       en stories with Gemini, prints a human-readable preview, and saves
       the full draft to /tmp/lorescape_daily_story_draft.json.
       NOTHING is written to Supabase at this stage.
    2. The reviewer reads the preview in chat. To revise, re-run
       `generate --feedback "..."` — the feedback is appended to the
       prompt and the draft is overwritten.
    3. `publish` reads the draft, upserts both language rows into
       daily_stories (idempotent on publish_date+language) and marks the
       place used. The App shows the newest publish_date immediately —
       there is no review_state gate on the App side — which is why
       review MUST happen before this step.

Run from backend/:

    uv run python -m scripts.manual_daily_story generate
    uv run python -m scripts.manual_daily_story generate --place-title "Alhambra"
    uv run python -m scripts.manual_daily_story generate --feedback "第二段太乾"
    uv run python -m scripts.manual_daily_story publish
    uv run python -m scripts.manual_daily_story publish --date 2026-06-12
"""
from __future__ import annotations

import argparse
import dataclasses
import json
import os
import sys
from datetime import date

from dotenv import load_dotenv

load_dotenv()
# The google-genai SDK prefers GOOGLE_API_KEY over GEMINI_API_KEY when both
# are set; on this machine GOOGLE_API_KEY is a non-Gemini key, so drop it.
os.environ.pop("GOOGLE_API_KEY", None)

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import (
    gemini_client,
    place_picker,
    prompts,
    story_writer,
    wikipedia,
)

DRAFT_PATH = "/tmp/lorescape_daily_story_draft.json"
LANGUAGES = ["zh-TW", "en"]
_RULE = "=" * 72


def _supabase(config: Config):
    return create_client(config.supabase_url, config.supabase_service_role_key)


def _pick_place(supabase, place_title: str | None) -> place_picker.PickedPlace:
    if place_title:
        response = (
            supabase.table("daily_story_places")
            .select("id, wikipedia_title_en")
            .eq("wikipedia_title_en", place_title)
            .limit(1)
            .execute()
        )
        if not response.data:
            raise SystemExit(
                f"Place {place_title!r} not found in daily_story_places"
            )
        row = response.data[0]
        return place_picker.PickedPlace(
            id=row["id"], wikipedia_title_en=row["wikipedia_title_en"]
        )
    place = place_picker.pick_next_place(supabase)
    if place is None:
        raise SystemExit("No active places available in daily_story_places")
    return place


def cmd_generate(args: argparse.Namespace) -> int:
    config = Config.from_env()
    supabase = _supabase(config)

    place = _pick_place(supabase, args.place_title)
    print(f"Place: {place.wikipedia_title_en}  (id={place.id})")

    summary = wikipedia.fetch_summary(place.wikipedia_title_en)
    intro_extract = (
        wikipedia.fetch_intro_extract(place.wikipedia_title_en)
        or summary.extract
    )

    # Same licence rule as the cron job: only commercially reusable lead
    # images are kept (with attribution); everything else is dropped.
    lead_image = wikipedia.fetch_lead_image(place.wikipedia_title_en)
    if lead_image and lead_image.is_commercial_ok and summary.image_url:
        image_url: str | None = summary.image_url
        image_attribution: str | None = lead_image.attribution
    else:
        image_url = None
        image_attribution = None

    stories: dict[str, dict] = {}
    wiki_urls: dict[str, str] = {}
    for language in LANGUAGES:
        target_lang = language.split("-")[0]
        wiki_urls[language] = (
            wikipedia.fetch_langlink_url(place.wikipedia_title_en, target_lang)
            or summary.en_url
        )
        user_prompt = prompts.build_user_prompt(
            wikipedia_title=place.wikipedia_title_en,
            wikipedia_extract=intro_extract,
            language=language,
        )
        if args.feedback:
            user_prompt += (
                "\n\nREVIEWER FEEDBACK on the previous draft — you MUST "
                "address it in this rewrite:\n" + args.feedback
            )
        print(f"Generating {language} story...")
        story = gemini_client.generate_story(
            api_key=config.gemini_api_key,
            system_instruction=prompts.SYSTEM_INSTRUCTION_FOR(language),
            user_prompt=user_prompt,
            response_schema=prompts.build_response_schema(language),
        )
        stories[language] = dataclasses.asdict(story)

    draft = {
        "place_id": place.id,
        "wikipedia_title_en": place.wikipedia_title_en,
        "image_url": image_url,
        "image_attribution": image_attribution,
        "wiki_urls": wiki_urls,
        "stories": stories,
    }
    with open(DRAFT_PATH, "w") as f:
        json.dump(draft, f, ensure_ascii=False, indent=2)

    _print_preview(draft)
    print(f"\nDraft saved to {DRAFT_PATH}")
    print("Review it, then either re-run generate --feedback '...' or run "
          "publish.")
    return 0


def _print_preview(draft: dict) -> None:
    for language in LANGUAGES:
        story = draft["stories"][language]
        print(f"\n{_RULE}\n[{language}] {story['place_name']} — "
              f"{story['place_location']}  (era: {story['era']})\n{_RULE}")
        for i, paragraph in enumerate(story["paragraphs"], 1):
            print(f"\n[{i}] ({len(paragraph)} chars) {paragraph}")
        if story["card_pull_quote"]:
            print(f"\npull quote: {story['card_pull_quote']}")
        print(f"hashtags: {' '.join(story['hashtags'])}")
    image = draft["image_url"] or "(none — no commercially usable lead image)"
    print(f"\ncover image: {image}")


def cmd_publish(args: argparse.Namespace) -> int:
    config = Config.from_env()
    supabase = _supabase(config)

    try:
        with open(DRAFT_PATH) as f:
            draft = json.load(f)
    except FileNotFoundError:
        raise SystemExit(f"No draft at {DRAFT_PATH} — run generate first.")

    publish_date = (
        date.fromisoformat(args.date) if args.date else date.today()
    )

    for language in LANGUAGES:
        story = draft["stories"][language]
        story_writer.insert_story(
            supabase,
            story_writer.StoryRow(
                publish_date=publish_date,
                language=language,
                place_id=draft["place_id"],
                place_name=story["place_name"],
                place_location=story["place_location"],
                era=story["era"],
                story="\n\n".join(story["card_paragraphs"]),
                image_url=draft["image_url"],
                image_attribution=draft["image_attribution"],
                wikipedia_url=draft["wiki_urls"][language],
                hashtags=tuple(story["hashtags"]),
                paragraphs=tuple(story["paragraphs"]),
                card_title=story["card_title"],
                card_title_sub=story["card_title_sub"],
                card_paragraphs=tuple(story["card_paragraphs"]),
                card_pull_quote=story["card_pull_quote"],
                card_pull_quote_attrib=story["card_pull_quote_attrib"],
                card_anno_roman=story["card_anno_roman"],
            ),
        )
        print(f"Upserted daily_stories ({publish_date}, {language})")

    place_picker.mark_place_used(supabase, draft["place_id"])
    print(f"Marked place used: {draft['wikipedia_title_en']}")

    rows = (
        supabase.table("daily_stories")
        .select("language, place_name, review_state")
        .eq("publish_date", publish_date.isoformat())
        .execute()
    ).data
    print(f"Verification — rows for {publish_date}: {rows}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("generate", help="Generate a draft (no DB writes)")
    gen.add_argument("--place-title", help="Use this wikipedia_title_en "
                     "instead of the picker")
    gen.add_argument("--feedback", help="Reviewer feedback to address in "
                     "the regenerated draft")
    gen.set_defaults(func=cmd_generate)

    pub = sub.add_parser("publish", help="Write the reviewed draft to "
                         "Supabase and mark the place used")
    pub.add_argument("--date", help="Publish date YYYY-MM-DD "
                     "(default: today)")
    pub.set_defaults(func=cmd_publish)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
