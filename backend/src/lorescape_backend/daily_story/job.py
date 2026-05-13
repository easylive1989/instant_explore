"""Daily story job: pick → fetch → generate → write, with retry + Discord."""
from __future__ import annotations

import logging
import time
import traceback
from datetime import date
from typing import Any

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import (
    discord_notify,
    discord_review,
    gemini_client,
    place_picker,
    prompts,
    story_writer,
    wikipedia,
)

logger = logging.getLogger(__name__)

LANGUAGES = ["zh-TW", "en"]
REVIEW_LANGUAGE = "en"  # the row we hand off to the social-publishing flow
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
                threads_summary=story.threads_summary,
                hashtags=story.hashtags,
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


def send_today_for_review(config: Config, target_date: date) -> None:
    """Find the EN row for target_date and post it to Discord for review.

    Idempotent: if discord_message_id is already set on the row, the function
    does nothing (avoids re-posting the same story when the job runs twice).
    """
    if not config.review_enabled:
        logger.info("Discord review not configured; skipping review step")
        return

    supabase = create_client(config.supabase_url, config.supabase_service_role_key)
    row = _load_review_row(supabase, target_date)
    if row is None:
        logger.warning(
            "No %s row found for %s — nothing to send for review",
            REVIEW_LANGUAGE, target_date.isoformat(),
        )
        return
    if row.get("discord_message_id"):
        logger.info(
            "Row %s already has discord_message_id; skipping re-post", row["id"]
        )
        return

    payload = discord_review.ReviewPayload(
        place_name=row["place_name"],
        era=row["era"],
        place_location=row["place_location"],
        story=row["story"],
        threads_summary=row.get("threads_summary") or "",
        image_url=row.get("image_url"),
        wikipedia_url=row["wikipedia_url"],
    )
    message_id = discord_review.send_for_review(
        bot_token=config.discord_bot_token,  # type: ignore[arg-type]
        channel_id=config.discord_review_channel_id,  # type: ignore[arg-type]
        payload=payload,
    )
    (
        supabase.table("daily_stories")
        .update({"discord_message_id": message_id})
        .eq("id", row["id"])
        .execute()
    )
    logger.info(
        "Sent %s story to Discord for review (message_id=%s)",
        target_date.isoformat(), message_id,
    )


def run_generate_and_review(config: Config, target_date: date) -> None:
    """Top-level entrypoint for the 09:00 cron: generate + send for review."""
    run_with_retry(config, target_date)
    try:
        send_today_for_review(config, target_date)
    except Exception:  # noqa: BLE001 — review send is best-effort
        logger.exception(
            "send_today_for_review failed; story is in DB but not in Discord"
        )
        if config.discord_webhook_url:
            discord_notify.notify_failure(
                webhook_url=config.discord_webhook_url,
                date_str=target_date.isoformat(),
                error_message="Story generated but Discord review send failed",
                traceback_str=traceback.format_exc(),
            )


def _load_review_row(supabase, target_date: date) -> dict[str, Any] | None:
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", target_date.isoformat())
        .eq("language", REVIEW_LANGUAGE)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None
