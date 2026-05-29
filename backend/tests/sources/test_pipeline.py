"""Tests for sources/pipeline.py — multi-source bundle assembly."""
from __future__ import annotations

import pytest

from lorescape_backend.sources import pipeline
from lorescape_backend.sources.models import SourceBundle


@pytest.fixture
def patch_sources(monkeypatch):
    """Helper to stub the three providers in the pipeline."""
    calls: dict[str, list] = {"wiki": [], "wd": []}

    def factory(zh_text=None, en_text=None, facts_text=None):
        def fake_wiki(qid, lang):
            calls["wiki"].append((qid, lang))
            return {"zh": zh_text, "en": en_text}.get(lang)

        def fake_wd(qid):
            calls["wd"].append(qid)
            return facts_text

        monkeypatch.setattr(pipeline, "fetch_extract_by_qid", fake_wiki)
        monkeypatch.setattr(pipeline, "fetch_entity_claims", fake_wd)
        return calls

    return factory


def test_build_source_bundle_assembles_all_three_providers(patch_sources):
    patch_sources(
        zh_text="馬卡龍公園是位於桃園市的一座主題公園。" * 20,
        en_text="Macaron Park is a themed park in Taoyuan." * 20,
        facts_text="Type: urban park\nFounded: 2020\nNamed after: macaron",
    )

    bundle = pipeline.build_source_bundle(
        wikidata_id="Q108234567", language="zh-TW", place_name="馬卡龍公園",
    )

    providers = {e.provider for e in bundle.extracts}
    assert providers == {"wikipedia_zh", "wikipedia_en", "wikidata_facts"}
    assert bundle.wikidata_id == "Q108234567"
    assert bundle.place_name == "馬卡龍公園"
    assert bundle.is_sufficient is True


def test_build_source_bundle_strips_locale_to_wiki_lang_code(patch_sources):
    calls = patch_sources(zh_text="x" * 400, en_text=None, facts_text=None)

    pipeline.build_source_bundle(
        wikidata_id="Q1", language="zh-TW", place_name="x",
    )

    # `zh-TW` locale should map to wiki lang code `zh`.
    langs_requested = {lang for _, lang in calls["wiki"]}
    assert langs_requested == {"zh", "en"}


def test_build_source_bundle_omits_missing_providers(patch_sources):
    patch_sources(zh_text=None, en_text="abc" * 200, facts_text=None)

    bundle = pipeline.build_source_bundle(
        wikidata_id="Q1", language="en", place_name="x",
    )

    providers = {e.provider for e in bundle.extracts}
    assert providers == {"wikipedia_en"}
    assert bundle.is_sufficient is True  # en extract long enough


def test_build_source_bundle_returns_insufficient_when_everything_thin(patch_sources):
    patch_sources(zh_text="短", en_text="too short", facts_text="Type: park")  # no Founded/Named after

    bundle = pipeline.build_source_bundle(
        wikidata_id="Q1", language="zh-TW", place_name="x",
    )

    assert bundle.is_sufficient is False


def test_build_source_bundle_returns_empty_extracts_when_all_providers_fail(patch_sources):
    patch_sources(zh_text=None, en_text=None, facts_text=None)

    bundle = pipeline.build_source_bundle(
        wikidata_id="Q1", language="en", place_name="x",
    )

    assert bundle.extracts == []
    assert bundle.is_sufficient is False


def test_legacy_single_source_bundle_wraps_single_english_extract(monkeypatch):
    monkeypatch.setattr(
        pipeline,
        "fetch_intro_extract_legacy",
        lambda title: "Some English Wikipedia extract about Macaron Park" * 10,
    )

    bundle = pipeline.legacy_single_source_bundle(title="Macaron Park")

    assert bundle.wikidata_id is None
    assert bundle.place_name == "Macaron Park"
    assert len(bundle.extracts) == 1
    assert bundle.extracts[0].provider == "wikipedia_en"


def test_legacy_single_source_bundle_returns_insufficient_on_empty_extract(monkeypatch):
    monkeypatch.setattr(pipeline, "fetch_intro_extract_legacy", lambda title: "")
    bundle = pipeline.legacy_single_source_bundle(title="Foo")
    assert bundle.is_sufficient is False
    assert bundle.extracts == []
