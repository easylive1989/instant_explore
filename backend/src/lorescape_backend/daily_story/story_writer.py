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
    threads_summary: str
    hashtags: tuple[str, ...] = field(default_factory=tuple)
    # IG card fields — populated only on the zh-TW path.
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language)).

    The new social-publishing columns (discord_message_id, review_state, etc.)
    are written separately by the discord_review and publisher modules — this
    function only writes the story content itself.
    """
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    # asdict leaves tuple-typed fields as tuples, but the Supabase JSON
    # serializer needs lists for text[] / jsonb columns. Any new tuple field
    # added to StoryRow must be explicitly converted here.
    payload["hashtags"] = list(row.hashtags)
    if row.card_paragraphs_ch is not None:
        payload["card_paragraphs_ch"] = list(row.card_paragraphs_ch)
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
