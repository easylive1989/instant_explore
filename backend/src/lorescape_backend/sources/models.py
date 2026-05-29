"""Datatypes shared by sources/ pipeline."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

Provider = Literal["wikipedia_zh", "wikipedia_en", "wikidata_facts"]


@dataclass(frozen=True)
class SourceExtract:
    """One piece of raw source material from a single provider."""
    provider: Provider
    title: str | None
    text: str
    char_count: int
    has_named_entity: bool


@dataclass(frozen=True)
class SourceBundle:
    """Aggregated source materials passed to the Gemini prompt."""
    wikidata_id: str | None  # None for legacy path
    place_name: str
    extracts: list[SourceExtract]
    total_chars: int
    is_sufficient: bool
