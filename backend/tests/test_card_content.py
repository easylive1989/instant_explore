"""CardContent dataclass tests."""
from __future__ import annotations

import pytest
from dataclasses import FrozenInstanceError

from lorescape_backend.social.card import CardContent


def _valid_payload() -> dict:
    return dict(
        title_ch="討厭鐵塔的文學大師",
        title_ch_sub="莫泊桑的「專屬午餐位」",
        location_ch="艾菲爾鐵塔．巴黎",
        location_en="TOUR EIFFEL · PARIS",
        location_coord="48.8584°N · 2.2945°E",
        anno_roman="MDCCCLXXXIX",
        city_ch="巴",
        city_en="PARIS",
        paragraphs_ch=("a", "b", "c"),
        pull_quote_ch="「q」",
        pull_quote_attrib_ch="—— x",
        photo_url="https://example.com/p.jpg",
    )


def test_card_content_holds_all_fields():
    payload = _valid_payload()
    content = CardContent(**payload)
    for key, expected in payload.items():
        assert getattr(content, key) == expected


def test_card_content_is_frozen():
    content = CardContent(**_valid_payload())
    with pytest.raises(FrozenInstanceError):
        content.title_ch = "modified"  # type: ignore[misc]


def test_card_content_paragraphs_is_tuple():
    """Tuple is hashable and immutable; ensures we don't accidentally pass a list."""
    content = CardContent(**_valid_payload())
    assert isinstance(content.paragraphs_ch, tuple)
