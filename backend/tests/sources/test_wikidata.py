"""Tests for sources/wikidata.py — entity claims + narrative formatter."""
from __future__ import annotations

import pytest
import requests_mock

from lorescape_backend.sources import wikidata as wd_src


@pytest.fixture(autouse=True)
def _clear_caches():
    wd_src._entity_cache.clear()


def _claims_response(qid: str, claims: dict) -> dict:
    """Minimal wbgetentities response with claims+labels.

    `claims` is a property-id → list of statement dicts already shaped
    like the API output. Labels are produced from referenced entity ids.
    """
    return {"entities": {qid: {"claims": claims, "labels": {}}}}


def _value_statement(entity_id: str) -> dict:
    return {
        "mainsnak": {
            "snaktype": "value",
            "datavalue": {
                "type": "wikibase-entityid",
                "value": {"id": entity_id},
            },
        }
    }


def _time_statement(time_iso: str) -> dict:
    return {
        "mainsnak": {
            "snaktype": "value",
            "datavalue": {
                "type": "time",
                "value": {"time": time_iso},  # e.g. "+2020-00-00T00:00:00Z"
            },
        }
    }


def test_fetch_entity_claims_returns_narrative_text_for_all_supported_props():
    with requests_mock.Mocker() as m:
        # First request: claims for the place itself.
        place_claims = {
            "P31": [_value_statement("Q22698")],   # park
            "P571": [_time_statement("+2020-00-00T00:00:00Z")],
            "P138": [_value_statement("Q1093742")],  # macaron
            "P131": [_value_statement("Q237174")],  # Zhongli
            "P17": [_value_statement("Q865")],     # Taiwan
            "P361": [_value_statement("Q60767620")],  # Taoyuan Aerotropolis
        }
        # Second request: labels for referenced entities.
        labels_resp = {
            "entities": {
                "Q22698": {"labels": {"en": {"value": "urban park"}}},
                "Q1093742": {"labels": {"en": {"value": "macaron"}}},
                "Q237174": {"labels": {"en": {"value": "Zhongli District"}}},
                "Q865": {"labels": {"en": {"value": "Taiwan"}}},
                "Q60767620": {"labels": {"en": {"value": "Taoyuan Aerotropolis"}}},
            }
        }

        m.get(
            "https://www.wikidata.org/w/api.php",
            [
                {"json": _claims_response("Q108234567", place_claims)},
                {"json": labels_resp},
            ],
        )

        text = wd_src.fetch_entity_claims("Q108234567")

    assert text is not None
    assert "Type: urban park" in text
    assert "Founded: 2020" in text
    assert "Named after: macaron" in text
    assert "Located in: Zhongli District" in text
    assert "Country: Taiwan" in text
    assert "Part of: Taoyuan Aerotropolis" in text


def test_fetch_entity_claims_returns_partial_when_some_props_missing():
    with requests_mock.Mocker() as m:
        claims = {
            "P31": [_value_statement("Q22698")],
            "P571": [_time_statement("+2020-00-00T00:00:00Z")],
            # no P138/P131/P17/P361
        }
        labels = {"entities": {"Q22698": {"labels": {"en": {"value": "urban park"}}}}}
        m.get(
            "https://www.wikidata.org/w/api.php",
            [
                {"json": _claims_response("Q1", claims)},
                {"json": labels},
            ],
        )
        text = wd_src.fetch_entity_claims("Q1")

    assert text is not None
    assert "Type: urban park" in text
    assert "Founded: 2020" in text
    assert "Named after:" not in text


def test_fetch_entity_claims_returns_none_when_entity_missing():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json={"entities": {"Q1": {"missing": ""}}},
        )
        text = wd_src.fetch_entity_claims("Q1")

    assert text is None


def test_fetch_entity_claims_returns_none_when_no_supported_claims():
    with requests_mock.Mocker() as m:
        m.get(
            "https://www.wikidata.org/w/api.php",
            json=_claims_response("Q1", {"P9999": [_value_statement("Q2")]}),
        )
        text = wd_src.fetch_entity_claims("Q1")

    assert text is None


def test_fetch_entity_claims_returns_none_on_http_error():
    with requests_mock.Mocker() as m:
        m.get("https://www.wikidata.org/w/api.php", status_code=503)
        text = wd_src.fetch_entity_claims("Q1")

    assert text is None


def test_fetch_entity_claims_caches_subsequent_calls():
    with requests_mock.Mocker() as m:
        claims = {"P31": [_value_statement("Q22698")], "P571": [_time_statement("+2020-00-00T00:00:00Z")]}
        labels = {"entities": {"Q22698": {"labels": {"en": {"value": "urban park"}}}}}
        m.get(
            "https://www.wikidata.org/w/api.php",
            [
                {"json": _claims_response("Q1", claims)},
                {"json": labels},
            ],
        )

        first = wd_src.fetch_entity_claims("Q1")
        second = wd_src.fetch_entity_claims("Q1")

    assert first == second
    # Cache hit on the second call: only 2 HTTP calls in total (claims + labels).
    assert m.call_count == 2
