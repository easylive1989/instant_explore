"""Multi-source bundle pipeline anchored on Wikidata Q-id.

Orchestrates three providers concurrently:
  - Chinese Wikipedia extract (via Q-id sitelink)
  - English Wikipedia extract (via Q-id sitelink)
  - Wikidata structured claims (P31/P571/P138/P131/P17/P361)

Failures from any single provider degrade gracefully — the bundle just
omits that extract. The quality gate then decides if the remaining
material is rich enough for storytelling.

Also provides `legacy_single_source_bundle` for the deprecated
`wikipedia_title` request path (old App versions). It wraps the
existing English-only extract path into the same SourceBundle shape
so the prompt template only has one input format.
"""
from __future__ import annotations

import logging
from concurrent.futures import ThreadPoolExecutor

from lorescape_backend.sources.wikipedia import fetch_intro_extract as fetch_intro_extract_legacy  # noqa: F401  (re-exported for monkeypatch in tests)
from lorescape_backend.sources.models import SourceBundle, SourceExtract
from lorescape_backend.sources.quality import assess_bundle
from lorescape_backend.sources.wikidata import fetch_entity_claims
from lorescape_backend.sources.wikipedia import fetch_extract_by_qid

logger = logging.getLogger(__name__)


def build_source_bundle(
    *, wikidata_id: str, language: str, place_name: str
) -> SourceBundle:
    """Fetch all three providers concurrently and assemble a SourceBundle."""
    wiki_lang = language.split("-")[0].lower()

    with ThreadPoolExecutor(max_workers=3) as pool:
        zh_future = pool.submit(_safe_fetch_extract, wikidata_id, "zh")
        en_future = pool.submit(_safe_fetch_extract, wikidata_id, "en")
        facts_future = pool.submit(_safe_fetch_facts, wikidata_id)
        zh_text = zh_future.result()
        en_text = en_future.result()
        facts_text = facts_future.result()

    extracts: list[SourceExtract] = []
    if zh_text:
        extracts.append(_wiki_extract("wikipedia_zh", zh_text))
    if en_text:
        extracts.append(_wiki_extract("wikipedia_en", en_text))
    if facts_text:
        extracts.append(
            SourceExtract(
                provider="wikidata_facts",
                title=None,
                text=facts_text,
                char_count=len(facts_text),
                has_named_entity=True,
            )
        )

    bundle = SourceBundle(
        wikidata_id=wikidata_id,
        place_name=place_name,
        extracts=extracts,
        total_chars=sum(e.char_count for e in extracts),
        is_sufficient=False,
    )
    sufficient = assess_bundle(bundle)
    logger.info(
        "narration.source_bundle_built",
        extra={
            "wikidata_id": wikidata_id,
            "providers_succeeded": [e.provider for e in extracts],
            "total_chars": bundle.total_chars,
            "is_sufficient": sufficient,
            "wiki_lang_requested": wiki_lang,
        },
    )
    return _with_sufficient(bundle, sufficient)


def legacy_single_source_bundle(*, title: str) -> SourceBundle:
    """Wrap the deprecated English-only extract path into a SourceBundle."""
    extract = fetch_intro_extract_legacy(title) or ""
    extracts: list[SourceExtract] = []
    if extract:
        extracts.append(_wiki_extract("wikipedia_en", extract, title=title))
    bundle = SourceBundle(
        wikidata_id=None,
        place_name=title,
        extracts=extracts,
        total_chars=sum(e.char_count for e in extracts),
        is_sufficient=False,
    )
    sufficient = assess_bundle(bundle)
    return _with_sufficient(bundle, sufficient)


def _safe_fetch_extract(qid: str, lang: str) -> str | None:
    try:
        return fetch_extract_by_qid(qid, lang)
    except Exception as exc:  # noqa: BLE001 — graceful degrade for any provider error
        logger.warning(
            "sources.pipeline.wiki_failed",
            extra={"qid": qid, "lang": lang, "err": str(exc)},
        )
        return None


def _safe_fetch_facts(qid: str) -> str | None:
    try:
        return fetch_entity_claims(qid)
    except Exception as exc:  # noqa: BLE001 — graceful degrade
        logger.warning(
            "sources.pipeline.wikidata_failed",
            extra={"qid": qid, "err": str(exc)},
        )
        return None


def _wiki_extract(provider: str, text: str, *, title: str | None = None) -> SourceExtract:
    return SourceExtract(
        provider=provider,  # type: ignore[arg-type]
        title=title,
        text=text,
        char_count=len(text),
        has_named_entity=_looks_named_entity(text),
    )


_YEAR_RE_TEXT = ("19", "20")


def _looks_named_entity(text: str) -> bool:
    """Heuristic: contains a 4-digit year starting with 19 or 20."""
    return any(prefix in text for prefix in _YEAR_RE_TEXT)


def _with_sufficient(bundle: SourceBundle, is_sufficient: bool) -> SourceBundle:
    return SourceBundle(
        wikidata_id=bundle.wikidata_id,
        place_name=bundle.place_name,
        extracts=bundle.extracts,
        total_chars=bundle.total_chars,
        is_sufficient=is_sufficient,
    )
