import pytest
import requests_mock

from lorescape_backend.daily_story.wikipedia import (
    WikipediaSummary,
    fetch_summary,
    fetch_langlink_url,
)


SUMMARY_RESPONSE = {
    "title": "Colosseum",
    "extract": "The Colosseum is an oval amphitheatre in the centre of Rome.",
    "thumbnail": {"source": "https://upload.wikimedia.org/colosseum.jpg"},
    "content_urls": {
        "desktop": {"page": "https://en.wikipedia.org/wiki/Colosseum"}
    },
}


def test_fetch_summary_returns_extract_image_and_url():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Colosseum",
            json=SUMMARY_RESPONSE,
        )
        summary = fetch_summary("Colosseum")

    assert summary == WikipediaSummary(
        title="Colosseum",
        extract="The Colosseum is an oval amphitheatre in the centre of Rome.",
        image_url="https://upload.wikimedia.org/colosseum.jpg",
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )


def test_fetch_summary_handles_missing_thumbnail():
    response_no_thumb = {**SUMMARY_RESPONSE}
    response_no_thumb.pop("thumbnail")
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Colosseum",
            json=response_no_thumb,
        )
        summary = fetch_summary("Colosseum")
    assert summary.image_url is None


def test_fetch_summary_url_encodes_title_with_spaces():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/api/rest_v1/page/summary/Mont-Saint-Michel%20and%20its%20Bay",
            json={**SUMMARY_RESPONSE, "title": "Mont-Saint-Michel and its Bay"},
        )
        summary = fetch_summary("Mont-Saint-Michel and its Bay")
    assert summary.title == "Mont-Saint-Michel and its Bay"


LANGLINK_RESPONSE_WITH_ZH = {
    "query": {
        "pages": {
            "12345": {
                "pageid": 12345,
                "ns": 0,
                "title": "Colosseum",
                "langlinks": [{"lang": "zh", "*": "羅馬鬥獸場"}],
            }
        }
    }
}


def test_fetch_langlink_url_returns_target_lang_wiki_url():
    with requests_mock.Mocker() as m:
        m.get(
            "https://en.wikipedia.org/w/api.php",
            json=LANGLINK_RESPONSE_WITH_ZH,
        )
        url = fetch_langlink_url("Colosseum", "zh")
    assert url == "https://zh.wikipedia.org/wiki/%E7%BE%85%E9%A6%AC%E9%AC%A5%E7%8D%B8%E5%A0%B4"


def test_fetch_langlink_url_returns_none_when_no_langlink():
    response = {
        "query": {
            "pages": {
                "12345": {"pageid": 12345, "ns": 0, "title": "X"}
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=response)
        assert fetch_langlink_url("X", "zh") is None
