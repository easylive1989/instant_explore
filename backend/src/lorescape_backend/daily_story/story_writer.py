"""Insert daily story rows into Supabase."""
from __future__ import annotations

from dataclasses import asdict, dataclass
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


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language))."""
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
