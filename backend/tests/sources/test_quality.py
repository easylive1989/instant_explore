"""Tests for sources/quality.py bundle assessment."""
from __future__ import annotations

from lorescape_backend.sources.models import SourceBundle, SourceExtract
from lorescape_backend.sources.quality import assess_bundle


def _bundle(extracts: list[SourceExtract]) -> SourceBundle:
    return SourceBundle(
        wikidata_id="Q1",
        place_name="Test",
        extracts=extracts,
        total_chars=sum(e.char_count for e in extracts),
        is_sufficient=False,  # value under test
    )


def _wiki(provider: str, text: str, has_ne: bool = False) -> SourceExtract:
    return SourceExtract(
        provider=provider, title="t", text=text, char_count=len(text), has_named_entity=has_ne,
    )


def test_assess_bundle_returns_true_when_single_wiki_extract_meets_threshold():
    bundle = _bundle([_wiki("wikipedia_zh", "a" * 300)])
    assert assess_bundle(bundle) is True


def test_assess_bundle_returns_false_when_single_wiki_below_threshold():
    bundle = _bundle([_wiki("wikipedia_zh", "a" * 299)])
    assert assess_bundle(bundle) is False


def test_assess_bundle_returns_true_when_two_wikis_combined_meet_threshold():
    bundle = _bundle(
        [_wiki("wikipedia_zh", "a" * 200), _wiki("wikipedia_en", "b" * 200)]
    )
    assert assess_bundle(bundle) is True


def test_assess_bundle_returns_false_when_two_wikis_combined_below_threshold():
    bundle = _bundle(
        [_wiki("wikipedia_zh", "a" * 199), _wiki("wikipedia_en", "b" * 200)]
    )
    # 399 < 400 threshold
    assert assess_bundle(bundle) is False


def test_assess_bundle_returns_true_when_facts_have_p31_and_p571():
    facts = SourceExtract(
        provider="wikidata_facts",
        title=None,
        text="Type: park\nFounded: 2020",
        char_count=24,
        has_named_entity=True,
    )
    bundle = _bundle([facts])
    assert assess_bundle(bundle) is True


def test_assess_bundle_returns_true_when_facts_have_p31_and_p138():
    facts = SourceExtract(
        provider="wikidata_facts",
        title=None,
        text="Type: park\nNamed after: macaron",
        char_count=30,
        has_named_entity=True,
    )
    bundle = _bundle([facts])
    assert assess_bundle(bundle) is True


def test_assess_bundle_returns_false_when_facts_only_have_p31():
    facts = SourceExtract(
        provider="wikidata_facts",
        title=None,
        text="Type: park",
        char_count=10,
        has_named_entity=False,
    )
    bundle = _bundle([facts])
    assert assess_bundle(bundle) is False


def test_assess_bundle_returns_false_when_empty():
    bundle = _bundle([])
    assert assess_bundle(bundle) is False
