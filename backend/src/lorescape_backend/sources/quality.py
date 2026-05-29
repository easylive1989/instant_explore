"""Quality heuristic for SourceBundle.

Decides whether the aggregated source material is rich enough to
ground a story. When False, the API short-circuits to
`insufficient_source=true` without spending a Gemini call.
"""
from __future__ import annotations

from lorescape_backend.sources.models import SourceBundle, SourceExtract

_SINGLE_WIKI_THRESHOLD = 300  # chars
_COMBINED_WIKI_THRESHOLD = 400  # chars


def assess_bundle(bundle: SourceBundle) -> bool:
    """Return True when the bundle is rich enough for storytelling.

    Rules (OR):
      1. Any single Wikipedia extract >= 300 chars
      2. Combined Wikipedia extracts >= 400 chars
      3. Wikidata facts include (P31 AND P571) OR (P31 AND P138)
    """
    wiki_extracts = [e for e in bundle.extracts if e.provider.startswith("wikipedia_")]
    facts = next(
        (e for e in bundle.extracts if e.provider == "wikidata_facts"),
        None,
    )

    if any(e.char_count >= _SINGLE_WIKI_THRESHOLD for e in wiki_extracts):
        return True

    combined = sum(e.char_count for e in wiki_extracts)
    if combined >= _COMBINED_WIKI_THRESHOLD:
        return True

    if facts is not None and _facts_have_storytelling_anchors(facts):
        return True

    return False


def _facts_have_storytelling_anchors(facts: SourceExtract) -> bool:
    """True if facts text contains P31 + (P571 OR P138).

    The pipeline serialises Wikidata claims as `"Key: value"` lines
    (e.g. `"Type: park"`, `"Founded: 2020"`, `"Named after: macaron"`).
    A bundle is anchor-worthy when it has a type plus either an
    inception year or a named-after referent.
    """
    text = facts.text
    has_type = "Type:" in text
    has_founded = "Founded:" in text
    has_named_after = "Named after:" in text
    return has_type and (has_founded or has_named_after)
