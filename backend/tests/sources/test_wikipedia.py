"""Tests for sources/wikipedia.py — fetch_extract_by_qid via sitelinks."""
from __future__ import annotations

import pytest
import requests_mock

from lorescape_backend.sources import wikipedia as wiki_src


@pytest.fixture(autouse=True)
def _clear_caches():
    """Reset module-level TTL caches between tests."""
    wiki_src._extract_cache.clear()


def _sitelinks_response(*, qid: str, sitelinks: dict[str, str]) -> dict:
    """Build a minimal Wikidata wbgetentities response shape."""
    return {
        "entities": {
            qid: {
                "sitelinks": {
                    f"{lang}wiki": {"site": f"{lang}wiki", "title": title}
                    for lang, title in sitelinks.items()
                },
            }
        }
    }


def _extract_response(extract_text: str) -> dict:
    return {"query": {"pages": {"42": {"extract": extract_text}}}}


def test_fetch_extract_by_qid_returns_zh_extract_when_zh_sitelink_present():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_sitelinks_response(qid="Q108234567", sitelinks={"zh": "馬卡龍公園"}),
        )
        m.get(
            "https://zh.wikipedia.org/w/api.php",
            json=_extract_response("馬卡龍公園是位於桃園市的一座主題公園。"),
        )
        text = wiki_src.fetch_extract_by_qid("Q108234567", "zh")

    assert text == "馬卡龍公園是位於桃園市的一座主題公園。"


def test_fetch_extract_by_qid_returns_none_when_sitelink_missing():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_sitelinks_response(qid="Q1", sitelinks={"en": "Foo"}),  # no zh
        )
        text = wiki_src.fetch_extract_by_qid("Q1", "zh")

    assert text is None


def test_fetch_extract_by_qid_returns_none_when_extract_api_returns_no_text():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_sitelinks_response(qid="Q1", sitelinks={"en": "Foo"}),
        )
        m.get(
            "https://en.wikipedia.org/w/api.php",
            json={"query": {"pages": {"42": {}}}},  # no extract
        )
        text = wiki_src.fetch_extract_by_qid("Q1", "en")

    assert text is None


def test_fetch_extract_by_qid_returns_none_when_wikidata_5xx():
    with requests_mock.Mocker() as m:
        m.get("https://www.wikidata.org/w/api.php", status_code=503)
        text = wiki_src.fetch_extract_by_qid("Q1", "zh")

    assert text is None


def test_fetch_extract_by_qid_returns_none_when_wikipedia_5xx():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_sitelinks_response(qid="Q1", sitelinks={"en": "Foo"}),
        )
        m.get("https://en.wikipedia.org/w/api.php", status_code=503)
        text = wiki_src.fetch_extract_by_qid("Q1", "en")

    assert text is None


def test_fetch_extract_by_qid_caches_subsequent_calls():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_sitelinks_response(qid="Q1", sitelinks={"zh": "X"}),
        )
        m.get("https://zh.wikipedia.org/w/api.php", json=_extract_response("hello"))

        first = wiki_src.fetch_extract_by_qid("Q1", "zh")
        second = wiki_src.fetch_extract_by_qid("Q1", "zh")

    assert first == second == "hello"
    # Cached call should not hit either endpoint twice.
    assert m.call_count == 2  # 1 sitelinks + 1 extract, second pass served from cache


def test_fetch_intro_extract_returns_extract(requests_mock):
    requests_mock.get(
        "https://en.wikipedia.org/w/api.php",
        json={"query": {"pages": {"123": {"extract": "Intro text."}}}},
    )
    assert wiki_src.fetch_intro_extract("Some Title") == "Intro text."


def test_fetch_intro_extract_empty_when_missing(requests_mock):
    requests_mock.get(
        "https://en.wikipedia.org/w/api.php",
        json={"query": {"pages": {"-1": {"missing": ""}}}},
    )
    assert wiki_src.fetch_intro_extract("No Such Page") == ""
