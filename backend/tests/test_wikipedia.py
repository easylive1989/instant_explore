import copy

import pytest
import requests_mock

from lorescape_backend.daily_story.wikipedia import (
    LeadImage,
    WikipediaSummary,
    fetch_intro_extract,
    fetch_lead_image,
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


INTRO_EXTRACT_RESPONSE = {
    "query": {
        "pages": {
            "12345": {
                "pageid": 12345,
                "ns": 0,
                "title": "Arles",
                "extract": (
                    "Arles is a coastal city in southern France...\n"
                    "Vincent van Gogh lived in Arles from 1888 to 1889..."
                ),
            }
        }
    }
}


def test_fetch_intro_extract_returns_plaintext_intro():
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=INTRO_EXTRACT_RESPONSE)
        extract = fetch_intro_extract("Arles")
    assert "Vincent van Gogh" in extract
    assert "1888" in extract


def test_fetch_intro_extract_returns_empty_when_page_missing():
    response = {
        "query": {
            "pages": {
                "-1": {"ns": 0, "title": "Nope", "missing": ""}
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=response)
        assert fetch_intro_extract("Nope") == ""


def test_fetch_intro_extract_passes_correct_params():
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=INTRO_EXTRACT_RESPONSE)
        fetch_intro_extract("Arles")
        sent = m.request_history[0].qs
    # MediaWiki extracts API requires these params
    assert sent["action"] == ["query"]
    assert sent["prop"] == ["extracts"]
    assert sent["explaintext"] == ["1"]
    assert sent["exintro"] == ["1"]
    assert sent["titles"] == ["arles"]  # requests_mock lowercases qs values


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


# ---- fetch_lead_image (licence-aware) ----------------------------------

PAGEIMAGE_RESP = {
    "query": {
        "pages": {
            "123": {
                "pageid": 123,
                "title": "Colosseum",
                "pageimage": "Colosseum_2020.jpg",
            }
        }
    }
}


def _imageinfo_resp(*, license_code, license_short, artist="<a href='#'>Jane Doe</a>", non_free=None):
    extmeta = {
        "License": {"value": license_code},
        "LicenseShortName": {"value": license_short},
    }
    if artist is not None:
        extmeta["Artist"] = {"value": artist}
    if non_free is not None:
        extmeta["NonFree"] = {"value": non_free}
    return {
        "query": {
            "pages": {
                "-1": {
                    "title": "File:Colosseum_2020.jpg",
                    "imageinfo": [
                        {
                            "url": "https://upload.wikimedia.org/Colosseum_2020.jpg",
                            "extmetadata": extmeta,
                        }
                    ],
                }
            }
        }
    }


def _mock_lead_image(m, imageinfo):
    """Register the two sequential api.php calls fetch_lead_image makes."""
    m.get(
        "https://en.wikipedia.org/w/api.php",
        [{"json": PAGEIMAGE_RESP}, {"json": imageinfo}],
    )


def test_fetch_lead_image_accepts_cc_by_sa_with_attribution():
    with requests_mock.Mocker() as m:
        _mock_lead_image(
            m,
            _imageinfo_resp(license_code="cc-by-sa-4.0", license_short="CC BY-SA 4.0"),
        )
        img = fetch_lead_image("Colosseum")
    assert isinstance(img, LeadImage)
    assert img.is_commercial_ok is True
    assert img.url == "https://upload.wikimedia.org/Colosseum_2020.jpg"
    assert img.attribution is not None
    assert "Jane Doe" in img.attribution
    assert "CC BY-SA 4.0" in img.attribution


def test_fetch_lead_image_accepts_public_domain_without_artist():
    with requests_mock.Mocker() as m:
        _mock_lead_image(
            m,
            _imageinfo_resp(
                license_code="pd", license_short="Public domain", artist=None
            ),
        )
        img = fetch_lead_image("Colosseum")
    assert img.is_commercial_ok is True
    assert img.attribution is not None
    assert "Public domain" in img.attribution


def test_fetch_lead_image_rejects_non_commercial():
    with requests_mock.Mocker() as m:
        _mock_lead_image(
            m,
            _imageinfo_resp(license_code="cc-by-nc-4.0", license_short="CC BY-NC 4.0"),
        )
        img = fetch_lead_image("Colosseum")
    assert img is not None
    assert img.is_commercial_ok is False
    assert img.attribution is None


def test_fetch_lead_image_rejects_no_derivatives():
    with requests_mock.Mocker() as m:
        _mock_lead_image(
            m,
            _imageinfo_resp(license_code="cc-by-nd-4.0", license_short="CC BY-ND 4.0"),
        )
        img = fetch_lead_image("Colosseum")
    assert img.is_commercial_ok is False


def test_fetch_lead_image_rejects_non_free_fair_use():
    with requests_mock.Mocker() as m:
        _mock_lead_image(
            m,
            _imageinfo_resp(
                license_code="Fair use",
                license_short="Fair use",
                non_free="1",
            ),
        )
        img = fetch_lead_image("Colosseum")
    assert img.is_commercial_ok is False


def test_fetch_lead_image_returns_none_when_no_pageimage():
    no_image = copy.deepcopy(PAGEIMAGE_RESP)
    del no_image["query"]["pages"]["123"]["pageimage"]
    with requests_mock.Mocker() as m:
        m.get("https://en.wikipedia.org/w/api.php", json=no_image)
        assert fetch_lead_image("Colosseum") is None
