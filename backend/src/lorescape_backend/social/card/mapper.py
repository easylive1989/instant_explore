"""Compose CardContent from a joined daily_stories + daily_story_places pair.

Returns None if any field required to render an E0c card is missing. This
lets the publisher gracefully skip IG while still publishing Threads.
"""
from __future__ import annotations

from typing import Any

from .content import CardContent


def build_card_content(
    daily_story_row: dict[str, Any], place_row: dict[str, Any]
) -> CardContent | None:
    """Return a CardContent if every required field is present, else None.

    `daily_story_row` is the zh-TW row — the IG card layout is Chinese-only.
    en rows also carry `card_*` fields now (consumed by the App), but the
    IG publisher gates on language and never feeds them here. `place_row`
    is the matching `daily_story_places` row joined on `place_id`.
    """
    place_name = daily_story_row.get("place_name")
    place_location = daily_story_row.get("place_location")
    photo_url = daily_story_row.get("image_url")

    title_ch = daily_story_row.get("card_title")
    title_ch_sub = daily_story_row.get("card_title_sub")
    paragraphs = daily_story_row.get("card_paragraphs")
    pull_quote_ch = daily_story_row.get("card_pull_quote")
    pull_quote_attrib_ch = daily_story_row.get("card_pull_quote_attrib")
    anno_roman = daily_story_row.get("card_anno_roman")

    location_en = place_row.get("card_location_en")
    city_ch = place_row.get("card_city_ch")
    city_en = place_row.get("card_city_en")
    latitude = place_row.get("latitude")
    longitude = place_row.get("longitude")

    # Truthy check rejects None and empty strings/lists. Latitude/longitude
    # are checked separately with `is None` so 0.0 (equator / prime meridian)
    # stays valid.
    string_required = (
        place_name, place_location, photo_url,
        title_ch, title_ch_sub, pull_quote_ch,
        pull_quote_attrib_ch, anno_roman,
        location_en, city_ch, city_en,
    )
    if not all(string_required):
        return None
    if not paragraphs:
        return None
    if latitude is None or longitude is None:
        return None

    return CardContent(
        title_ch=title_ch,
        title_ch_sub=title_ch_sub,
        location_ch=f"{place_name}．{place_location}",
        location_en=location_en,
        location_coord=_format_coord(float(latitude), float(longitude)),
        anno_roman=anno_roman,
        city_ch=city_ch,
        city_en=city_en,
        paragraphs_ch=tuple(paragraphs),
        pull_quote_ch=pull_quote_ch,
        pull_quote_attrib_ch=pull_quote_attrib_ch,
        photo_url=photo_url,
    )


def _format_coord(latitude: float, longitude: float) -> str:
    lat_dir = "N" if latitude >= 0 else "S"
    lng_dir = "E" if longitude >= 0 else "W"
    return f"{abs(latitude):.4f}°{lat_dir} · {abs(longitude):.4f}°{lng_dir}"
