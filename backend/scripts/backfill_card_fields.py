"""One-off backfill: regenerate card_* fields for rows where they are NULL.

Covers:
- All en rows (never had card_* fields).
- Pre-20260521 zh-TW rows (card_paragraphs_ch column did not exist yet).

For each NULL row:
  1. Look up the place's English Wikipedia title.
  2. Re-fetch the Wikipedia extract.
  3. Call Gemini in the row's language to produce card_* fields.
  4. UPDATE the row with all card_* fields PLUS:
     - story  = "\n\n".join(card_paragraphs)
     - place_name / place_location / era (same Gemini output)

Idempotent: re-running picks up only rows with card_paragraphs IS NULL.

Place-level fields on `daily_story_places` (card_location_en,
card_city_ch, card_city_en, latitude, longitude) are admin-curated and
NOT touched by this script. After running, the operator should fill any
NULLs via the Supabase Dashboard.

Usage:
    cd backend
    uv run python -m scripts.backfill_card_fields --dry-run   # estimate
    uv run python -m scripts.backfill_card_fields             # real run
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from dataclasses import dataclass

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import gemini_client, prompts, wikipedia
from lorescape_backend.shared.genai import GenaiSettings

logger = logging.getLogger(__name__)


@dataclass
class BackfillResult:
    processed: int
    failed: int
    errors: list[str]


# Indirection seams so tests can monkeypatch.
def _generate_story(**kwargs):
    return gemini_client.generate_story(**kwargs)


def _fetch_summary(title: str):
    return wikipedia.fetch_summary(title)


def run(
    supabase, *, dry_run: bool, settings: GenaiSettings | None = None
) -> BackfillResult:
    """Run the backfill once. Returns a result summary; never raises mid-run."""
    null_rows = (
        supabase.table("daily_stories")
        .select("id, language, place_id")
        .is_("card_paragraphs", None)
        .execute()
        .data
        or []
    )

    if dry_run:
        logger.info("[dry-run] would process %d rows", len(null_rows))
        return BackfillResult(processed=len(null_rows), failed=0, errors=[])

    processed = 0
    errors: list[str] = []

    for idx, row in enumerate(null_rows, start=1):
        row_id = row["id"]
        language = row["language"]
        place_id = row["place_id"]
        try:
            place_rows = (
                supabase.table("daily_story_places")
                .select("wikipedia_title_en")
                .eq("id", place_id)
                .execute()
                .data
                or []
            )
            if not place_rows:
                raise RuntimeError(f"place {place_id} not found")
            wiki_title = place_rows[0]["wikipedia_title_en"]

            summary = _fetch_summary(wiki_title)
            story = _generate_story(
                settings=settings,
                system_instruction=prompts.SYSTEM_INSTRUCTION,
                user_prompt=prompts.build_user_prompt(
                    wikipedia_title=wiki_title,
                    wikipedia_extract=summary.extract,
                    language=language,
                ),
                response_schema=prompts.build_response_schema(language),
            )

            payload = {
                "card_title": story.card_title,
                "card_title_sub": story.card_title_sub,
                "card_paragraphs": list(story.card_paragraphs),
                "card_pull_quote": story.card_pull_quote,
                "card_pull_quote_attrib": story.card_pull_quote_attrib,
                "card_anno_roman": story.card_anno_roman,
                "story": "\n\n".join(story.card_paragraphs),
                "place_name": story.place_name,
                "place_location": story.place_location,
                "era": story.era,
            }
            supabase.table("daily_stories").update(payload).eq("id", row_id).execute()

            processed += 1
            logger.info(
                "[%d/%d] %s %s OK", idx, len(null_rows), language, row_id
            )
        except Exception as exc:  # noqa: BLE001
            msg = f"row {row_id} ({language}): {exc}"
            errors.append(msg)
            logger.warning("[%d/%d] FAIL %s", idx, len(null_rows), msg)

    return BackfillResult(
        processed=processed, failed=len(errors), errors=errors
    )


def _main() -> int:
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
    )
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    url = os.environ["SUPABASE_URL"]
    service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    # A dry run never calls Gemini, so it needs no backend credentials.
    settings = None if args.dry_run else Config.from_env().genai_settings

    supabase = create_client(url, service_key)
    result = run(supabase, dry_run=args.dry_run, settings=settings)

    logger.info(
        "summary: processed=%d failed=%d", result.processed, result.failed
    )
    for err in result.errors:
        logger.error("  %s", err)

    logger.info(
        "reminder: backfill does not touch daily_story_places.card_location_en"
        " / card_city_* / latitude / longitude — fill manually via Supabase"
        " Dashboard for any new places."
    )
    return 0 if result.failed == 0 else 1


if __name__ == "__main__":
    sys.exit(_main())
