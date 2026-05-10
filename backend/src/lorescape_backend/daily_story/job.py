"""Daily story job: pick → fetch → generate → write, with retry + Discord."""
from __future__ import annotations

import logging
import time
import traceback
from datetime import date

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import (
    discord_notify,
    gemini_client,
    place_picker,
    prompts,
    story_writer,
    wikipedia,
)

logger = logging.getLogger(__name__)

LANGUAGES = ["zh-TW", "en"]
RETRY_DELAYS = [1, 5, 30]  # delays before retries 1, 2, 3 → 4 total attempts


def run_once(config: Config, target_date: date) -> None:
    """Run the daily story job once. Raises on any failure."""
    supabase = create_client(config.supabase_url, config.supabase_service_role_key)

    place = place_picker.pick_next_place(supabase)
    if not place:
        raise RuntimeError("No active places available in daily_story_places")

    summary = wikipedia.fetch_summary(place.wikipedia_title_en)

    for language in LANGUAGES:
        target_lang = language.split("-")[0]  # 'zh-TW' → 'zh', 'en' → 'en'
        wiki_url = (
            wikipedia.fetch_langlink_url(place.wikipedia_title_en, target_lang)
            or summary.en_url
        )

        story = gemini_client.generate_story(
            api_key=config.gemini_api_key,
            system_instruction=prompts.SYSTEM_INSTRUCTION,
            user_prompt=prompts.build_user_prompt(
                wikipedia_title=place.wikipedia_title_en,
                wikipedia_extract=summary.extract,
                language=language,
            ),
            response_schema=prompts.GEMINI_RESPONSE_SCHEMA,
        )

        story_writer.insert_story(
            supabase,
            story_writer.StoryRow(
                publish_date=target_date,
                language=language,
                place_id=place.id,
                place_name=story.place_name,
                place_location=story.place_location,
                era=story.era,
                story=story.story,
                image_url=summary.image_url,
                wikipedia_url=wiki_url,
            ),
        )

    place_picker.mark_place_used(supabase, place.id)


def run_with_retry(config: Config, target_date: date) -> None:
    """Run the job with retry-with-backoff. Notify Discord on final failure."""
    last_exc: Exception | None = None
    total_attempts = len(RETRY_DELAYS) + 1

    for attempt in range(total_attempts):
        try:
            run_once(config, target_date)
            logger.info(
                "daily_story_job succeeded for %s on attempt %d",
                target_date.isoformat(), attempt + 1,
            )
            return
        except Exception as exc:  # noqa: BLE001 — orchestrator catches all
            last_exc = exc
            logger.warning("Attempt %d failed: %s", attempt + 1, exc)
            if attempt < total_attempts - 1:
                time.sleep(RETRY_DELAYS[attempt])

    # All attempts failed
    assert last_exc is not None
    logger.error("All %d attempts failed", total_attempts, exc_info=last_exc)
    if config.discord_webhook_url:
        discord_notify.notify_failure(
            webhook_url=config.discord_webhook_url,
            date_str=target_date.isoformat(),
            error_message=str(last_exc),
            traceback_str="".join(
                traceback.format_exception(type(last_exc), last_exc, last_exc.__traceback__)
            ),
        )
    raise last_exc
