from datetime import date
from unittest.mock import MagicMock

from lorescape_publisher.daily_story.story_writer import StoryRow, insert_story


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
        "image_attribution": None,
        "hashtags": ["rome", "colosseum"],
        "paragraphs": [],
        "card_title": "",
        "card_title_sub": "",
        "card_paragraphs": [],
        "card_pull_quote": "",
        "card_pull_quote_attrib": "",
        "card_anno_roman": "",
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
        hashtags=("paris", "eiffelTower"),
        card_title="討厭鐵塔的文學大師",
        card_title_sub="莫泊桑的「專屬午餐位」",
        card_paragraphs=("第一段", "第二段", "第三段"),
        card_pull_quote="「看不見艾菲爾鐵塔的地方。」",
        card_pull_quote_attrib="—— 莫泊桑，一八八九",
        card_anno_roman="MDCCCLXXXIX",
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    # text[] columns must be JSON arrays, not tuples
    assert payload["card_paragraphs"] == ["第一段", "第二段", "第三段"]
    assert isinstance(payload["card_paragraphs"], list)
    assert payload["card_title"] == "討厭鐵塔的文學大師"
    assert payload["card_title_sub"] == "莫泊桑的「專屬午餐位」"
    assert payload["card_pull_quote"] == "「看不見艾菲爾鐵塔的地方。」"
    assert payload["card_pull_quote_attrib"] == "—— 莫泊桑，一八八九"
    assert payload["card_anno_roman"] == "MDCCCLXXXIX"


def test_insert_story_writes_long_paragraphs_as_list():
    """Long-form `paragraphs` is jsonb; must be serialized as a JSON list."""
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    insert_story(
        client,
        StoryRow(
            publish_date=date(2026, 5, 27),
            language="zh-TW",
            place_id="place-1",
            place_name="X",
            place_location="Y",
            era="Z",
            story="...",
            image_url=None,
            wikipedia_url="https://example.org",
            paragraphs=("長段一", "長段二", "長段三"),
        ),
    )

    payload = chain.upsert.call_args[0][0]
    assert payload["paragraphs"] == ["長段一", "長段二", "長段三"]
    assert isinstance(payload["paragraphs"], list)


def test_insert_story_writes_en_card_fields_too():
    """Both languages now carry card fields; en is no longer an exception."""
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
        story="P1\n\nP2\n\nP3",
        image_url=None,
        wikipedia_url="https://en.wikipedia.org/wiki/Eiffel_Tower",
        hashtags=("paris", "eiffelTower"),
        card_title="The Writer Who Hated the Tower",
        card_title_sub="Maupassant's lunch spot",
        card_paragraphs=("P1", "P2", "P3"),
        card_pull_quote="\"The one place you can't see the Eiffel Tower.\"",
        card_pull_quote_attrib="— Maupassant, 1889",
        card_anno_roman="MDCCCLXXXIX",
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    assert payload["card_paragraphs"] == ["P1", "P2", "P3"]
    assert isinstance(payload["card_paragraphs"], list)
    assert payload["card_title"] == "The Writer Who Hated the Tower"
    assert payload["card_title_sub"] == "Maupassant's lunch spot"
    assert payload["card_pull_quote"] == "\"The one place you can't see the Eiffel Tower.\""
    assert payload["card_pull_quote_attrib"] == "— Maupassant, 1889"
    assert payload["card_anno_roman"] == "MDCCCLXXXIX"
