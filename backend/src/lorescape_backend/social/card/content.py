"""Content payload for the E0c IG card."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CardContent:
    """Data needed to render one E0c (Chinese-only) IG card."""

    title_ch: str
    title_ch_sub: str
    location_ch: str
    location_en: str
    location_coord: str
    anno_roman: str
    city_ch: str
    city_en: str
    paragraphs_ch: tuple[str, ...]
    pull_quote_ch: str
    pull_quote_attrib_ch: str
    photo_url: str
