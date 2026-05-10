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
