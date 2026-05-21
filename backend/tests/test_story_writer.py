from datetime import date
from unittest.mock import MagicMock

from lorescape_backend.daily_story.story_writer import StoryRow, insert_story


def test_insert_story_upserts_with_publish_date_language_conflict_key():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 11),
        language="zh-TW",
        place_id="place-1",
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        story="...",
        image_url="https://upload.wikimedia.org/x.jpg",
        wikipedia_url="https://zh.wikipedia.org/wiki/...",
        threads_summary="短摘",
        hashtags=("rome", "colosseum"),
    )

    insert_story(client, row)

    client.table.assert_called_with("daily_stories")
    chain.upsert.assert_called_once()
    payload = chain.upsert.call_args[0][0]
    assert payload == {
        "publish_date": "2026-05-11",
        "language": "zh-TW",
        "place_id": "place-1",
        "place_name": "羅馬競技場",
        "place_location": "義大利羅馬",
        "era": "公元 70-80 年",
        "story": "...",
        "image_url": "https://upload.wikimedia.org/x.jpg",
        "wikipedia_url": "https://zh.wikipedia.org/wiki/...",
        "threads_summary": "短摘",
        "hashtags": ["rome", "colosseum"],
        "card_title_ch": None,
        "card_title_sub_ch": None,
        "card_paragraphs_ch": None,
        "card_pull_quote_ch": None,
        "card_pull_quote_attrib_ch": None,
        "card_anno_roman": None,
    }
    # Verify on_conflict kwarg
    assert chain.upsert.call_args.kwargs.get("on_conflict") == "publish_date,language"


def test_insert_story_handles_null_image_url():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    insert_story(
        client,
        StoryRow(
            publish_date=date(2026, 5, 11),
            language="en",
            place_id="p",
            place_name="X",
            place_location="Y",
            era="Z",
            story="...",
            image_url=None,
            wikipedia_url="https://en.wikipedia.org/wiki/X",
            threads_summary="t",
        ),
    )

    payload = chain.upsert.call_args[0][0]
    assert payload["image_url"] is None


def test_insert_story_writes_zh_tw_card_fields_with_paragraphs_as_list():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 21),
        language="zh-TW",
        place_id="place-1",
        place_name="艾菲爾鐵塔",
        place_location="巴黎",
        era="十九世紀末",
        story="第一段\n\n第二段\n\n第三段",
        image_url=None,
        wikipedia_url="https://zh.wikipedia.org/wiki/...",
        threads_summary="短摘",
        hashtags=("paris", "eiffelTower"),
        card_title_ch="討厭鐵塔的文學大師",
        card_title_sub_ch="莫泊桑的「專屬午餐位」",
        card_paragraphs_ch=("第一段", "第二段", "第三段"),
        card_pull_quote_ch="「看不見艾菲爾鐵塔的地方。」",
        card_pull_quote_attrib_ch="—— 莫泊桑，一八八九",
        card_anno_roman="MDCCCLXXXIX",
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    # text[] columns must be JSON arrays, not tuples
    assert payload["card_paragraphs_ch"] == ["第一段", "第二段", "第三段"]
    assert isinstance(payload["card_paragraphs_ch"], list)
    assert payload["card_title_ch"] == "討厭鐵塔的文學大師"
    assert payload["card_title_sub_ch"] == "莫泊桑的「專屬午餐位」"
    assert payload["card_pull_quote_ch"] == "「看不見艾菲爾鐵塔的地方。」"
    assert payload["card_pull_quote_attrib_ch"] == "—— 莫泊桑，一八八九"
    assert payload["card_anno_roman"] == "MDCCCLXXXIX"


def test_insert_story_leaves_card_fields_null_for_en_row():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 21),
        language="en",
        place_id="place-1",
        place_name="Eiffel Tower",
        place_location="Paris",
        era="Late 19th century",
        story="English story",
        image_url=None,
        wikipedia_url="https://en.wikipedia.org/wiki/Eiffel_Tower",
        threads_summary="t",
        hashtags=(),
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    for field in (
        "card_title_ch",
        "card_title_sub_ch",
        "card_paragraphs_ch",
        "card_pull_quote_ch",
        "card_pull_quote_attrib_ch",
        "card_anno_roman",
    ):
        assert payload[field] is None, f"expected {field} to be None for en row"
