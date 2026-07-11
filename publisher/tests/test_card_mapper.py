"""Tests for build_card_content: zh-TW row + place row → CardContent | None."""
from __future__ import annotations

from lorescape_publisher.card.content import CardContent
from lorescape_publisher.card.mapper import build_card_content


def _zh_tw_row(**overrides) -> dict:
    base = {
        "id": "row-zh-1",
        "publish_date": "2026-05-21",
        "language": "zh-TW",
        "place_id": "place-1",
        "place_name": "艾菲爾鐵塔",
        "place_location": "巴黎",
        "era": "十九世紀末",
        "story": "第一段\n\n第二段\n\n第三段",
        "image_url": "https://upload.wikimedia.org/x.jpg",
        "wikipedia_url": "https://zh.wikipedia.org/wiki/...",
        "hashtags": ["paris", "eiffelTower"],
        "card_title": "討厭鐵塔的文學大師",
        "card_title_sub": "莫泊桑的「專屬午餐位」",
        "card_paragraphs": ["第一段", "第二段", "第三段"],
        "card_pull_quote": "「看不見鐵塔的地方。」",
        "card_pull_quote_attrib": "—— 莫泊桑,一八八九",
        "card_anno_roman": "MDCCCLXXXIX",
    }
    base.update(overrides)
    return base


def _place_row(**overrides) -> dict:
    base = {
        "id": "place-1",
        "name": "Eiffel Tower",
        "wikipedia_title_en": "Eiffel Tower",
        "country": "France",
        "card_location_en": "TOUR EIFFEL · PARIS",
        "card_city_ch": "巴",
        "card_city_en": "PARIS",
        "latitude": 48.8584,
        "longitude": 2.2945,
    }
    base.update(overrides)
    return base


def test_build_card_content_happy_path():
    result = build_card_content(_zh_tw_row(), _place_row())
    assert result == CardContent(
        title_ch="討厭鐵塔的文學大師",
        title_ch_sub="莫泊桑的「專屬午餐位」",
        location_ch="艾菲爾鐵塔．巴黎",
        location_en="TOUR EIFFEL · PARIS",
        location_coord="48.8584°N · 2.2945°E",
        anno_roman="MDCCCLXXXIX",
        city_ch="巴",
        city_en="PARIS",
        paragraphs_ch=("第一段", "第二段", "第三段"),
        pull_quote_ch="「看不見鐵塔的地方。」",
        pull_quote_attrib_ch="—— 莫泊桑,一八八九",
        photo_url="https://upload.wikimedia.org/x.jpg",
    )


def test_build_card_content_paragraphs_list_becomes_tuple():
    result = build_card_content(_zh_tw_row(), _place_row())
    assert isinstance(result.paragraphs_ch, tuple)


def test_build_card_content_southern_western_hemisphere_coord():
    place = _place_row(latitude=-33.8688, longitude=-70.6483)  # Santiago
    result = build_card_content(_zh_tw_row(), place)
    assert result.location_coord == "33.8688°S · 70.6483°W"


def test_build_card_content_equator_and_prime_meridian_are_valid():
    place = _place_row(latitude=0.0, longitude=0.0)
    result = build_card_content(_zh_tw_row(), place)
    # 0 is treated as the northern / eastern side by convention.
    assert result.location_coord == "0.0000°N · 0.0000°E"


def test_build_card_content_returns_none_if_any_zh_tw_card_field_missing():
    for field in (
        "card_title",
        "card_title_sub",
        "card_paragraphs",
        "card_pull_quote",
        "card_pull_quote_attrib",
        "card_anno_roman",
    ):
        row = _zh_tw_row(**{field: None})
        assert build_card_content(row, _place_row()) is None, (
            f"expected None when {field} is None"
        )


def test_build_card_content_returns_none_if_zh_tw_card_paragraphs_empty():
    row = _zh_tw_row(card_paragraphs=[])
    assert build_card_content(row, _place_row()) is None


def test_build_card_content_returns_none_if_any_place_field_missing():
    for field in ("card_location_en", "card_city_ch", "card_city_en"):
        place = _place_row(**{field: None})
        assert build_card_content(_zh_tw_row(), place) is None, (
            f"expected None when place.{field} is None"
        )


def test_build_card_content_returns_none_if_latitude_or_longitude_missing():
    assert build_card_content(_zh_tw_row(), _place_row(latitude=None)) is None
    assert build_card_content(_zh_tw_row(), _place_row(longitude=None)) is None


def test_build_card_content_returns_none_if_image_url_missing():
    row = _zh_tw_row(image_url=None)
    assert build_card_content(row, _place_row()) is None


def test_build_card_content_returns_none_if_place_name_or_location_missing():
    assert build_card_content(_zh_tw_row(place_name=None), _place_row()) is None
    assert build_card_content(_zh_tw_row(place_location=None), _place_row()) is None
