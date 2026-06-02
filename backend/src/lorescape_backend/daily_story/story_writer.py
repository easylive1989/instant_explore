"""Insert daily story rows into Supabase."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import date


@dataclass(frozen=True)
class StoryRow:
    publish_date: date
    language: str
    place_id: str
    place_name: str
    place_location: str
    era: str
    story: str
    image_url: str | None
    wikipedia_url: str
    # Credit string for the lead image (author / licence / source). None when
    # there is no commercially usable image.
    image_attribution: str | None = None
    hashtags: tuple[str, ...] = field(default_factory=tuple)
    # Long-form 3-paragraph narration used by App story view & TTS.
    paragraphs: tuple[str, ...] = field(default_factory=tuple)
    # IG card fields — populated on every row (both zh-TW and en).
    card_title: str = ""
    card_title_sub: str = ""
    card_paragraphs: tuple[str, ...] = field(default_factory=tuple)
    card_pull_quote: str = ""
    card_pull_quote_attrib: str = ""
    card_anno_roman: str = ""


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language)).

    The new social-publishing columns (discord_message_id, review_state, etc.)
    are written separately by the discord_review and publisher modules — this
    function only writes the story content itself.
    """
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    # asdict leaves tuple-typed fields as tuples, but the Supabase JSON
    # serializer needs lists for text[] / jsonb columns.
    payload["hashtags"] = list(row.hashtags)
    payload["paragraphs"] = list(row.paragraphs)
    payload["card_paragraphs"] = list(row.card_paragraphs)
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
