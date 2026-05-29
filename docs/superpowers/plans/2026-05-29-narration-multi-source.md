# Narration 多源故事 Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 on-demand narration (`/api/hooks`、`/api/narration`) 從「單一英文 Wikipedia title 直查」升級為「以 Wikidata Q-id 為錨點、並行抓中文 + 英文 Wikipedia + Wikidata facts、pre-Gemini 品質擋線」的多源 pipeline，解掉「馬卡龍公園」這類台灣地方景點的「沒故事可講」bug。

**Architecture:** 新增 `backend/src/lorescape_backend/sources/` 模組（models / wikipedia / wikidata / quality / pipeline）；改 narration request 接受 `wikidata_id`、保留 `wikipedia_title` 為 deprecated 向下相容；shared prompt 改吃 SourceBundle；App 端從 `place.id`（`'wikidata:Q...'`）解出 Q-id 傳給後端。

**Tech Stack:** Python 3.11 + FastAPI + requests + cachetools + pytest + requests_mock；Dart + Flutter + http + flutter_test。

**Spec:** `docs/superpowers/specs/2026-05-29-narration-multi-source-design.md`

---

## File Structure

### Backend — Create

| File | Responsibility |
| --- | --- |
| `backend/src/lorescape_backend/sources/__init__.py` | Package marker |
| `backend/src/lorescape_backend/sources/models.py` | `SourceExtract`, `SourceBundle` dataclasses |
| `backend/src/lorescape_backend/sources/quality.py` | `assess_bundle(bundle) -> bool` |
| `backend/src/lorescape_backend/sources/wikipedia.py` | `fetch_extract_by_qid(qid, lang)` with TTL cache |
| `backend/src/lorescape_backend/sources/wikidata.py` | `fetch_entity_claims(qid)` + claim → narrative formatter, with TTL cache |
| `backend/src/lorescape_backend/sources/pipeline.py` | `build_source_bundle(...)`, `legacy_single_source_bundle(...)` |
| `backend/tests/sources/__init__.py` | Package marker |
| `backend/tests/sources/test_quality.py` | Quality rules tests |
| `backend/tests/sources/test_wikipedia.py` | Sitelinks + extract fetch tests |
| `backend/tests/sources/test_wikidata.py` | Claims parsing + formatter tests |
| `backend/tests/sources/test_pipeline.py` | Orchestration + graceful degrade tests |

### Backend — Modify

| File | What changes |
| --- | --- |
| `backend/pyproject.toml` | Add `cachetools>=5,<6` dependency |
| `backend/src/lorescape_backend/narration/models.py` | `wikidata_id: str \| None`、`wikipedia_title: str \| None deprecated`、`@model_validator` |
| `backend/src/lorescape_backend/narration/service.py` | Branch on `wikidata_id`; call `sources.build_source_bundle` or `legacy_single_source_bundle` |
| `backend/src/lorescape_backend/narration/prompts.py` | `build_*_user_prompt` takes `source_bundle`; output spec wording "Wikipedia extract" → "provided sources" |
| `backend/src/lorescape_backend/shared/story_prompt.py` | `build_story_user_prompt` signature: `source_bundle: SourceBundle`; new multi-source template |
| `backend/tests/narration/test_prompts.py` | Extend for new prompt structure |
| `backend/tests/narration/test_service.py` | Extend for new path + legacy + pre-Gemini gate |
| `backend/tests/narration/test_routes.py` | Extend for new contract + 400 case |
| `backend/tests/shared/test_story_prompt.py` | Extend for SourceBundle input |

### Frontend — Modify

| File | What changes |
| --- | --- |
| `frontend/lib/features/narration/data/narration_api_client.dart` | Method signature: drop `wikipediaTitle`, add `wikidataId`; JSON key `wikidata_id` |
| `frontend/lib/features/narration/data/narration_api_service.dart` | Add `_extractWikidataId(placeId)`; insufficient fallback when null |
| `frontend/lib/features/narration/data/story_hook_api_service.dart` | Same pattern as `narration_api_service.dart` |
| `frontend/test/features/narration/data/narration_api_client_test.dart` | Update existing tests for new body shape |
| `frontend/test/features/narration/data/narration_api_service_test.dart` | New file: `_extractWikidataId` + insufficient fallback |
| `frontend/test/features/narration/data/story_hook_api_service_test.dart` | New file: same pattern |

---

## Task 1: Add cachetools dependency

**Files:**
- Modify: `backend/pyproject.toml`

- [ ] **Step 1: Add `cachetools>=5,<6` to dependencies**

Edit `backend/pyproject.toml` — append to the `dependencies` list (after `"jinja2>=3.1,<4",`):

```toml
    "cachetools>=5,<6",
```

- [ ] **Step 2: Install the new dep**

Run from `backend/`:

```bash
uv sync --all-extras
```

Expected: cachetools resolved and installed without error.

- [ ] **Step 3: Verify import**

```bash
uv run python -c "from cachetools import TTLCache, cached; print('ok')"
```

Expected: prints `ok`.

- [ ] **Step 4: Commit**

```bash
git add backend/pyproject.toml backend/uv.lock
git commit -m "chore(backend): add cachetools dep for sources/ TTL cache"
```

---

## Task 2: `sources/` module + `SourceExtract`/`SourceBundle` models

**Files:**
- Create: `backend/src/lorescape_backend/sources/__init__.py`
- Create: `backend/src/lorescape_backend/sources/models.py`

- [ ] **Step 1: Create empty `__init__.py`**

```bash
mkdir -p backend/src/lorescape_backend/sources
touch backend/src/lorescape_backend/sources/__init__.py
```

- [ ] **Step 2: Write `models.py`**

Create `backend/src/lorescape_backend/sources/models.py`:

```python
"""Datatypes shared by sources/ pipeline."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

Provider = Literal["wikipedia_zh", "wikipedia_en", "wikidata_facts"]


@dataclass(frozen=True)
class SourceExtract:
    """One piece of raw source material from a single provider."""
    provider: Provider
    title: str | None
    text: str
    char_count: int
    has_named_entity: bool


@dataclass(frozen=True)
class SourceBundle:
    """Aggregated source materials passed to the Gemini prompt."""
    wikidata_id: str | None  # None for legacy path
    place_name: str
    extracts: list[SourceExtract]
    total_chars: int
    is_sufficient: bool
```

- [ ] **Step 3: Smoke test the import**

```bash
cd backend && uv run python -c "from lorescape_backend.sources.models import SourceExtract, SourceBundle; print('ok')"
```

Expected: prints `ok`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/lorescape_backend/sources/
git commit -m "feat(sources): add SourceExtract and SourceBundle dataclasses"
```

---

## Task 3: `sources/quality.py` — bundle quality assessment

**Files:**
- Create: `backend/src/lorescape_backend/sources/quality.py`
- Create: `backend/tests/sources/__init__.py`
- Create: `backend/tests/sources/test_quality.py`

- [ ] **Step 1: Write failing tests**

```bash
touch backend/tests/sources/__init__.py
```

Create `backend/tests/sources/test_quality.py`:

```python
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
```

- [ ] **Step 2: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/sources/test_quality.py -v
```

Expected: ImportError (`lorescape_backend.sources.quality` not found).

- [ ] **Step 3: Implement `quality.py`**

Create `backend/src/lorescape_backend/sources/quality.py`:

```python
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
```

- [ ] **Step 4: Run tests to see them pass**

```bash
cd backend && uv run pytest tests/sources/test_quality.py -v
```

Expected: all 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/sources/quality.py backend/tests/sources/
git commit -m "feat(sources): add quality.assess_bundle with 3 OR-rules"
```

---

## Task 4: `sources/wikipedia.py` — extract by Q-id + sitelinks

**Files:**
- Create: `backend/src/lorescape_backend/sources/wikipedia.py`
- Create: `backend/tests/sources/test_wikipedia.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/sources/test_wikipedia.py`:

```python
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
```

- [ ] **Step 2: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/sources/test_wikipedia.py -v
```

Expected: ImportError (`sources.wikipedia` not found).

- [ ] **Step 3: Implement `wikipedia.py`**

Create `backend/src/lorescape_backend/sources/wikipedia.py`:

```python
"""Wikipedia extract fetcher anchored on Wikidata Q-id.

Two-step lookup:
  1. Wikidata wbgetentities → sitelinks → resolve Q-id to a wiki title
     in the requested language.
  2. MediaWiki `prop=extracts&exintro=1&explaintext=1` for that title.

Wraps both lookups in a 7-day TTL cache so the same Q-id+lang served
from memory on repeat requests within the same process.

Returns None (never raises) on:
  - missing sitelink for requested language
  - missing extract on the wiki page
  - any HTTP error
This is graceful-degrade by design: the source pipeline must tolerate
each individual provider failing.
"""
from __future__ import annotations

import logging

import requests
from cachetools import TTLCache, cached
from cachetools.keys import hashkey

logger = logging.getLogger(__name__)

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_WIKIDATA_API = "https://www.wikidata.org/w/api.php"
_TIMEOUT = 30

# 7-day TTL × 5000 entries × ~2KB ≈ 10MB max. Restart clears cache;
# Wikipedia/Wikidata APIs remain the source of truth.
_extract_cache: TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)


@cached(_extract_cache, key=lambda qid, lang: hashkey(qid, lang))
def fetch_extract_by_qid(qid: str, lang: str) -> str | None:
    """Resolve Q-id to a Wikipedia title in `lang`, then return its intro extract.

    `lang` is the wiki language code (e.g. `"zh"`, `"en"`) — NOT the
    request locale (e.g. `"zh-TW"`). Callers should strip region tags
    before invoking.
    """
    title = _resolve_sitelink_title(qid, lang)
    if title is None:
        return None
    return _fetch_intro_extract(title, lang)


def _resolve_sitelink_title(qid: str, lang: str) -> str | None:
    try:
        response = requests.get(
            _WIKIDATA_API,
            params={
                "action": "wbgetentities",
                "ids": qid,
                "props": "sitelinks",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning("sources.wikipedia.sitelinks_failed", extra={"qid": qid, "err": str(exc)})
        return None

    data = response.json()
    entity = (data.get("entities") or {}).get(qid)
    if not isinstance(entity, dict):
        return None
    sitelinks = entity.get("sitelinks") or {}
    link = sitelinks.get(f"{lang}wiki")
    if not isinstance(link, dict):
        return None
    title = link.get("title")
    return title if isinstance(title, str) else None


def _fetch_intro_extract(title: str, lang: str) -> str | None:
    try:
        response = requests.get(
            f"https://{lang}.wikipedia.org/w/api.php",
            params={
                "action": "query",
                "format": "json",
                "titles": title,
                "prop": "extracts",
                "explaintext": 1,
                "exintro": 1,
                "redirects": 1,
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.wikipedia.extract_failed",
            extra={"lang": lang, "title": title, "err": str(exc)},
        )
        return None

    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        extract = page.get("extract")
        if isinstance(extract, str) and extract:
            return extract
    return None
```

- [ ] **Step 4: Run tests to see them pass**

```bash
cd backend && uv run pytest tests/sources/test_wikipedia.py -v
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/sources/wikipedia.py backend/tests/sources/test_wikipedia.py
git commit -m "feat(sources): add Wikipedia extract fetch by Q-id with TTL cache"
```

---

## Task 5: `sources/wikidata.py` — entity claims + narrative formatter

**Files:**
- Create: `backend/src/lorescape_backend/sources/wikidata.py`
- Create: `backend/tests/sources/test_wikidata.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/sources/test_wikidata.py`:

```python
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
```

- [ ] **Step 2: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/sources/test_wikidata.py -v
```

Expected: ImportError (`sources.wikidata` not found).

- [ ] **Step 3: Implement `wikidata.py`**

Create `backend/src/lorescape_backend/sources/wikidata.py`:

```python
"""Wikidata claims fetcher + narrative formatter.

Fetches a small whitelist of properties for a Q-id and serialises them
into a `"Key: value"` plaintext block consumable by the story prompt.

Supported properties (whitelist; in display order):
  P31  → "Type: <label>"
  P571 → "Founded: <year>"
  P138 → "Named after: <label>"
  P131 → "Located in: <label>"
  P17  → "Country: <label>"
  P361 → "Part of: <label>"

Returns None (never raises) on:
  - missing entity
  - no whitelisted claims
  - any HTTP error
"""
from __future__ import annotations

import logging
import re
from typing import Iterable

import requests
from cachetools import TTLCache, cached
from cachetools.keys import hashkey

logger = logging.getLogger(__name__)

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_API = "https://www.wikidata.org/w/api.php"
_TIMEOUT = 30

# (property id, display label, value extractor)
_PROP_ORDER: list[tuple[str, str, str]] = [
    ("P31", "Type", "entity"),
    ("P571", "Founded", "year"),
    ("P138", "Named after", "entity"),
    ("P131", "Located in", "entity"),
    ("P17", "Country", "entity"),
    ("P361", "Part of", "entity"),
]

_entity_cache: TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)


@cached(_entity_cache, key=lambda qid: hashkey(qid))
def fetch_entity_claims(qid: str) -> str | None:
    """Return a `"Key: value"` block of whitelisted claims, or None."""
    entity = _fetch_entity(qid)
    if entity is None:
        return None

    claims = entity.get("claims") or {}
    extracted: list[tuple[str, str]] = []
    referenced_ids: list[str] = []

    for prop_id, label, kind in _PROP_ORDER:
        statements = claims.get(prop_id)
        if not isinstance(statements, list) or not statements:
            continue
        first = statements[0]
        mainsnak = first.get("mainsnak") or {}
        if mainsnak.get("snaktype") != "value":
            continue
        value_payload = (mainsnak.get("datavalue") or {}).get("value")
        if value_payload is None:
            continue

        if kind == "year":
            year = _extract_year(value_payload)
            if year:
                extracted.append((label, year))
        elif kind == "entity":
            entity_id = value_payload.get("id") if isinstance(value_payload, dict) else None
            if isinstance(entity_id, str):
                extracted.append((label, entity_id))
                referenced_ids.append(entity_id)

    if not extracted:
        return None

    labels = _fetch_labels(referenced_ids) if referenced_ids else {}

    lines: list[str] = []
    for prop_label, value in extracted:
        if prop_label == "Founded":
            lines.append(f"Founded: {value}")
        else:
            human = labels.get(value, value)
            lines.append(f"{prop_label}: {human}")
    return "\n".join(lines)


def _fetch_entity(qid: str) -> dict | None:
    try:
        response = requests.get(
            _API,
            params={
                "action": "wbgetentities",
                "ids": qid,
                "props": "claims",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning("sources.wikidata.entity_failed", extra={"qid": qid, "err": str(exc)})
        return None
    entity = (response.json().get("entities") or {}).get(qid)
    if not isinstance(entity, dict) or "missing" in entity:
        return None
    return entity


def _fetch_labels(ids: Iterable[str]) -> dict[str, str]:
    unique_ids = list(dict.fromkeys(ids))  # preserve order, dedupe
    if not unique_ids:
        return {}
    try:
        response = requests.get(
            _API,
            params={
                "action": "wbgetentities",
                "ids": "|".join(unique_ids),
                "props": "labels",
                "languages": "en",
                "format": "json",
            },
            headers={"User-Agent": USER_AGENT},
            timeout=_TIMEOUT,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning("sources.wikidata.labels_failed", extra={"ids": unique_ids, "err": str(exc)})
        return {}

    out: dict[str, str] = {}
    entities = response.json().get("entities") or {}
    for entity_id, payload in entities.items():
        label = ((payload.get("labels") or {}).get("en") or {}).get("value")
        if isinstance(label, str):
            out[entity_id] = label
    return out


_YEAR_RE = re.compile(r"^[+-]?(\d{1,4})")


def _extract_year(value_payload: object) -> str | None:
    if not isinstance(value_payload, dict):
        return None
    time_str = value_payload.get("time")
    if not isinstance(time_str, str):
        return None
    match = _YEAR_RE.match(time_str)
    return match.group(1) if match else None
```

- [ ] **Step 4: Run tests to see them pass**

```bash
cd backend && uv run pytest tests/sources/test_wikidata.py -v
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/sources/wikidata.py backend/tests/sources/test_wikidata.py
git commit -m "feat(sources): add Wikidata claims fetcher + narrative formatter"
```

---

## Task 6: `sources/pipeline.py` — orchestrate multi-source bundle

**Files:**
- Create: `backend/src/lorescape_backend/sources/pipeline.py`
- Create: `backend/tests/sources/test_pipeline.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/sources/test_pipeline.py`:

```python
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
```

- [ ] **Step 2: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/sources/test_pipeline.py -v
```

Expected: ImportError (`sources.pipeline` not found).

- [ ] **Step 3: Implement `pipeline.py`**

Create `backend/src/lorescape_backend/sources/pipeline.py`:

```python
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

from lorescape_backend.daily_story.wikipedia import fetch_intro_extract as fetch_intro_extract_legacy  # noqa: F401  (re-exported for monkeypatch in tests)
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
```

- [ ] **Step 4: Run tests to see them pass**

```bash
cd backend && uv run pytest tests/sources/ -v
```

Expected: all sources tests pass (quality + wikipedia + wikidata + pipeline).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/sources/pipeline.py backend/tests/sources/test_pipeline.py
git commit -m "feat(sources): add multi-source pipeline + legacy single-source bundle"
```

---

## Task 7: Refactor `shared/story_prompt.py` to consume `SourceBundle`

**Files:**
- Modify: `backend/src/lorescape_backend/shared/story_prompt.py`
- Modify: `backend/tests/shared/test_story_prompt.py`

- [ ] **Step 1: Read current implementation**

```bash
sed -n '150,180p' backend/src/lorescape_backend/shared/story_prompt.py
```

You should see the existing `build_story_user_prompt` taking `wikipedia_title` / `wikipedia_extract` parameters.

- [ ] **Step 2: Write failing tests**

Append to `backend/tests/shared/test_story_prompt.py`:

```python
from lorescape_backend.shared.story_prompt import build_story_user_prompt, StoryHook
from lorescape_backend.sources.models import SourceBundle, SourceExtract


def _zh_extract(text: str = "馬卡龍公園是…") -> SourceExtract:
    return SourceExtract(
        provider="wikipedia_zh", title="馬卡龍公園", text=text,
        char_count=len(text), has_named_entity=True,
    )


def _en_extract(text: str = "Macaron Park is …") -> SourceExtract:
    return SourceExtract(
        provider="wikipedia_en", title="Macaron Park", text=text,
        char_count=len(text), has_named_entity=True,
    )


def _facts(text: str = "Type: urban park\nFounded: 2020") -> SourceExtract:
    return SourceExtract(
        provider="wikidata_facts", title=None, text=text,
        char_count=len(text), has_named_entity=True,
    )


def _bundle(extracts):
    return SourceBundle(
        wikidata_id="Q1", place_name="馬卡龍公園",
        extracts=extracts, total_chars=sum(e.char_count for e in extracts),
        is_sufficient=True,
    )


def test_build_story_user_prompt_includes_zh_section_when_zh_extract_present():
    prompt = build_story_user_prompt(
        place_name="馬卡龍公園", location="桃園", source_bundle=_bundle([_zh_extract()]),
        hook=None,
    )
    assert "Chinese Wikipedia extract (zh)" in prompt
    assert "馬卡龍公園是…" in prompt


def test_build_story_user_prompt_includes_en_section_when_en_extract_present():
    prompt = build_story_user_prompt(
        place_name="x", location="y", source_bundle=_bundle([_en_extract()]), hook=None,
    )
    assert "English Wikipedia extract (en)" in prompt
    assert "Macaron Park is …" in prompt


def test_build_story_user_prompt_includes_facts_section_when_facts_present():
    prompt = build_story_user_prompt(
        place_name="x", location="y", source_bundle=_bundle([_facts()]), hook=None,
    )
    assert "Structured facts (Wikidata)" in prompt
    assert "Type: urban park" in prompt
    assert "Founded: 2020" in prompt


def test_build_story_user_prompt_skips_missing_sections():
    prompt = build_story_user_prompt(
        place_name="x", location="y", source_bundle=_bundle([_en_extract()]), hook=None,
    )
    assert "Chinese Wikipedia extract" not in prompt
    assert "Structured facts" not in prompt


def test_build_story_user_prompt_renders_wikidata_id_when_present():
    prompt = build_story_user_prompt(
        place_name="x", location="y", source_bundle=_bundle([_en_extract()]), hook=None,
    )
    assert "Wikidata ID: Q1" in prompt
```

- [ ] **Step 3: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/shared/test_story_prompt.py -v
```

Expected: TypeError or AssertionError because `build_story_user_prompt` still takes `wikipedia_title` / `wikipedia_extract`.

- [ ] **Step 4: Replace `build_story_user_prompt` to consume `SourceBundle`**

Edit `backend/src/lorescape_backend/shared/story_prompt.py`. Find the existing `build_story_user_prompt` function (around line 156) and replace its body with:

```python
def build_story_user_prompt(
    *,
    place_name: str,
    location: str,
    source_bundle: "SourceBundle",
    hook: StoryHook | None = None,
) -> str:
    """Render the multi-source user prompt for the story call."""
    lines: list[str] = [f"Place: {place_name}", f"Location: {location}"]
    if source_bundle.wikidata_id:
        lines.append(f"Wikidata ID: {source_bundle.wikidata_id}")
    lines.append("")
    lines.append(
        "Source materials (multiple providers; use any/all to ground the story):"
    )

    zh = _find_extract(source_bundle, "wikipedia_zh")
    en = _find_extract(source_bundle, "wikipedia_en")
    facts = _find_extract(source_bundle, "wikidata_facts")

    if zh is not None:
        lines += [
            "",
            f'[1] Chinese Wikipedia extract (zh) — title: "{zh.title}"',
            "<<<",
            zh.text,
            ">>>",
        ]
    if en is not None:
        lines += [
            "",
            f'[2] English Wikipedia extract (en) — title: "{en.title}"',
            "<<<",
            en.text,
            ">>>",
        ]
    if facts is not None:
        lines += [
            "",
            "[3] Structured facts (Wikidata)",
            facts.text,
        ]

    lines += [
        "",
        "GROUNDING RULES:",
        "- Prefer concrete facts (years, named entities, events) from the sources above.",
        "- If sources are in a different language than the output, translate facts; do NOT invent.",
        "- Treat structured facts as ground truth even if Wiki extracts are short.",
        "- If you cannot find at least one named entity (person/year/event) to ground the story, return insufficient_source=true.",
    ]

    if hook is not None:
        lines += [
            "",
            f"HOOK to expand: {hook.title}",
            f"Teaser: {hook.teaser}",
        ]

    return "\n".join(lines)


def _find_extract(bundle: "SourceBundle", provider: str):
    for e in bundle.extracts:
        if e.provider == provider:
            return e
    return None
```

At the top of the file, add the typing import (guarded to avoid circular import at runtime):

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from lorescape_backend.sources.models import SourceBundle
```

- [ ] **Step 5: Run tests to see them pass**

```bash
cd backend && uv run pytest tests/shared/test_story_prompt.py -v
```

Expected: new SourceBundle tests pass. Pre-existing tests in this file that called the old signature will fail — that's expected and fixed in Task 9 (the callers move to SourceBundle too).

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/shared/story_prompt.py backend/tests/shared/test_story_prompt.py
git commit -m "refactor(prompt): story user prompt consumes SourceBundle"
```

---

## Task 8: Update `narration/prompts.py` output spec wording + callers

**Files:**
- Modify: `backend/src/lorescape_backend/narration/prompts.py`
- Modify: `backend/tests/narration/test_prompts.py`

- [ ] **Step 1: Update output spec wording**

Edit `backend/src/lorescape_backend/narration/prompts.py`:

Find the line in `_en_output_spec()`:

```python
        "- insufficient_source: true when the Wikipedia extract is too "
        "thin to support the story-spine constraints. When true, leave "
```

Replace with:

```python
        "- insufficient_source: true when the provided sources are too "
        "thin to support the story-spine constraints. When true, leave "
```

Find the line in `_zh_tw_output_spec()`:

```python
        "- insufficient_source: 當 Wikipedia 內容不足以撐起故事骨架時"
```

Replace with:

```python
        "- insufficient_source: 當提供的來源內容不足以撐起故事骨架時"
```

- [ ] **Step 2: Update `build_narration_user_prompt` and `build_hooks_user_prompt` signatures**

In the same file, find `build_narration_user_prompt`. Replace its signature + body with:

```python
def build_narration_user_prompt(
    *,
    place_name: str,
    location: str,
    source_bundle: "SourceBundle",
    language: str,
    hook: StoryHook | None = None,
) -> str:
    """Story user prompt + narration-specific output spec tail."""
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    base = build_story_user_prompt(
        place_name=place_name, location=location,
        source_bundle=source_bundle, hook=hook,
    )
    tail = _zh_tw_output_spec() if language == "zh-TW" else _en_output_spec()
    return base + "\n\n" + tail
```

Find `build_hooks_user_prompt`. Replace its signature + body with:

```python
def build_hooks_user_prompt(
    *,
    place_name: str,
    location: str,
    source_bundle: "SourceBundle",
) -> str:
    return build_story_user_prompt(
        place_name=place_name, location=location,
        source_bundle=source_bundle, hook=None,
    )
```

Add at the top of `narration/prompts.py`:

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from lorescape_backend.sources.models import SourceBundle
```

- [ ] **Step 3: Update test_prompts.py tests for new signature**

Read `backend/tests/narration/test_prompts.py` and rewrite each test that constructs a narration/hooks user prompt to pass `source_bundle` instead of `wikipedia_title`/`wikipedia_extract`. Pattern:

```python
from lorescape_backend.sources.models import SourceBundle, SourceExtract


def _bundle_en(extract_text: str, title: str = "Macaron Park") -> SourceBundle:
    ex = SourceExtract(
        provider="wikipedia_en", title=title, text=extract_text,
        char_count=len(extract_text), has_named_entity=True,
    )
    return SourceBundle(
        wikidata_id="Q1", place_name=title,
        extracts=[ex], total_chars=len(extract_text), is_sufficient=True,
    )


# example rewrite of an existing test:
def test_build_narration_user_prompt_includes_extract_text():
    prompt = build_narration_user_prompt(
        place_name="Macaron Park", location="Taoyuan",
        source_bundle=_bundle_en("Some extract about the park."),
        language="en",
    )
    assert "Some extract about the park." in prompt
    assert "the provided sources are too" in prompt  # new wording
```

Iterate through every test in the file with this pattern.

- [ ] **Step 4: Run tests to verify the file is green**

```bash
cd backend && uv run pytest tests/narration/test_prompts.py -v
```

Expected: all tests pass with the new signature and updated wording.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/narration/prompts.py backend/tests/narration/test_prompts.py
git commit -m "refactor(narration): prompt builders take SourceBundle; output spec source-agnostic"
```

---

## Task 9: Update `narration/models.py` for new API contract

**Files:**
- Modify: `backend/src/lorescape_backend/narration/models.py`
- Modify: `backend/tests/narration/test_routes.py`

- [ ] **Step 1: Write failing tests for contract validation**

Append to `backend/tests/narration/test_routes.py` (read it first for existing fixtures):

```python
from fastapi.testclient import TestClient
import pytest

from lorescape_backend.api import app  # adjust if app lives elsewhere


@pytest.fixture
def client():
    return TestClient(app)


def test_narration_route_accepts_wikidata_id(monkeypatch, client):
    # Stub the service to a known response so we only test contract here.
    from lorescape_backend.narration import service as narration_service

    def fake_generate(*, api_key, request):
        from lorescape_backend.narration.models import NarrationResponse
        return NarrationResponse(
            place_name=request.place_name, location=request.location,
            era="modern", paragraphs=["a"] * 3, pull_quote="x",
            insufficient_source=False,
        )
    monkeypatch.setattr(narration_service, "generate_narration", fake_generate)

    res = client.post(
        "/api/narration",
        json={
            "wikidata_id": "Q1",
            "place_name": "Test",
            "location": "Somewhere",
            "language": "en",
        },
    )
    assert res.status_code == 200


def test_narration_route_accepts_legacy_wikipedia_title(monkeypatch, client):
    from lorescape_backend.narration import service as narration_service

    monkeypatch.setattr(
        narration_service, "generate_narration",
        lambda *, api_key, request: __import__(
            "lorescape_backend.narration.models", fromlist=["NarrationResponse"],
        ).NarrationResponse(
            place_name=request.place_name, location=request.location,
            era="modern", paragraphs=["a"] * 3, pull_quote="x",
            insufficient_source=False,
        ),
    )

    res = client.post(
        "/api/narration",
        json={
            "wikipedia_title": "Macaron Park",
            "place_name": "Macaron Park",
            "location": "Taoyuan",
            "language": "en",
        },
    )
    assert res.status_code == 200


def test_narration_route_400_when_no_identity_provided(client):
    res = client.post(
        "/api/narration",
        json={
            "place_name": "x",
            "location": "y",
            "language": "en",
        },
    )
    assert res.status_code in (400, 422)
```

(Note: the import path for `app` is `lorescape_backend.api`; if `test_routes.py` already imports it, reuse the existing fixture.)

- [ ] **Step 2: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/narration/test_routes.py -v
```

Expected: 400 test passes accidentally (existing strict validation might 422 on missing wikipedia_title), wikidata_id test fails (field not defined yet).

- [ ] **Step 3: Update models**

Replace the existing `HooksRequest` and `NarrationRequest` classes in `backend/src/lorescape_backend/narration/models.py` with:

```python
class HooksRequest(BaseModel):
    place_name: str
    location: str = ""
    wikidata_id: str | None = Field(
        default=None, description="Wikidata Q-id, e.g. 'Q12345'.",
    )
    wikipedia_title: str | None = Field(
        default=None,
        deprecated=True,
        description=(
            "Deprecated since 2026-05-29. Old App versions only. "
            "Remove after legacy clients phase out."
        ),
    )
    language: str = Field(..., description="zh-TW or en")

    @model_validator(mode="after")
    def _require_one_identity(self):
        if not self.wikidata_id and not self.wikipedia_title:
            raise ValueError("Either wikidata_id or wikipedia_title must be provided")
        return self


class NarrationRequest(BaseModel):
    place_name: str
    location: str = ""
    wikidata_id: str | None = Field(
        default=None, description="Wikidata Q-id, e.g. 'Q12345'.",
    )
    wikipedia_title: str | None = Field(
        default=None,
        deprecated=True,
        description=(
            "Deprecated since 2026-05-29. Old App versions only. "
            "Remove after legacy clients phase out."
        ),
    )
    language: str = Field(..., description="zh-TW or en")
    hook: HookItem | None = None

    @model_validator(mode="after")
    def _require_one_identity(self):
        if not self.wikidata_id and not self.wikipedia_title:
            raise ValueError("Either wikidata_id or wikipedia_title must be provided")
        return self
```

Update the import at the top of the file:

```python
from pydantic import BaseModel, Field, model_validator
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd backend && uv run pytest tests/narration/test_routes.py -v
```

Expected: all three new contract tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/narration/models.py backend/tests/narration/test_routes.py
git commit -m "feat(narration): API accepts wikidata_id; wikipedia_title marked deprecated"
```

---

## Task 10: Wire `narration/service.py` to the new pipeline

**Files:**
- Modify: `backend/src/lorescape_backend/narration/service.py`
- Modify: `backend/tests/narration/test_service.py`

- [ ] **Step 1: Read existing service code + tests**

```bash
cat backend/src/lorescape_backend/narration/service.py
sed -n '1,80p' backend/tests/narration/test_service.py
```

- [ ] **Step 2: Write failing tests for new + legacy + gate paths**

Append to `backend/tests/narration/test_service.py`:

```python
from lorescape_backend.narration import service as narration_service
from lorescape_backend.narration.models import HooksRequest, NarrationRequest, HookItem
from lorescape_backend.sources.models import SourceBundle, SourceExtract


def _sufficient_bundle() -> SourceBundle:
    extract_text = "马卡龙公园是位于桃园市的主题公园，建于2020年。" * 10
    return SourceBundle(
        wikidata_id="Q108234567", place_name="馬卡龍公園",
        extracts=[SourceExtract(
            provider="wikipedia_zh", title="馬卡龍公園", text=extract_text,
            char_count=len(extract_text), has_named_entity=True,
        )],
        total_chars=len(extract_text), is_sufficient=True,
    )


def _insufficient_bundle() -> SourceBundle:
    return SourceBundle(
        wikidata_id="Q1", place_name="x", extracts=[],
        total_chars=0, is_sufficient=False,
    )


def test_generate_narration_with_wikidata_id_invokes_pipeline_and_gemini(monkeypatch):
    gemini_calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _sufficient_bundle(),
    )

    def fake_generate_structured(**kwargs):
        gemini_calls.append(kwargs)
        return {
            "place_name": "馬卡龍公園", "place_location": "桃園", "era": "modern",
            "paragraphs": ["a", "b", "c"], "pull_quote": "「q」",
            "insufficient_source": False,
        }

    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = NarrationRequest(
        wikidata_id="Q108234567", place_name="馬卡龍公園",
        location="桃園", language="zh-TW",
    )
    res = narration_service.generate_narration(api_key="k", request=req)

    assert len(gemini_calls) == 1
    assert res.insufficient_source is False
    assert res.paragraphs == ["a", "b", "c"]


def test_generate_narration_pre_gemini_gate_short_circuits(monkeypatch):
    gemini_calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )

    def fake_generate_structured(**kwargs):
        gemini_calls.append(kwargs)
        return {}

    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = NarrationRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_narration(api_key="k", request=req)

    assert gemini_calls == []  # critical: Gemini NOT called
    assert res.insufficient_source is True
    assert res.paragraphs == []


def test_generate_narration_legacy_title_path_uses_single_source_bundle(monkeypatch, caplog):
    monkeypatch.setattr(
        narration_service, "legacy_single_source_bundle",
        lambda *, title: _sufficient_bundle(),
    )
    monkeypatch.setattr(
        narration_service.gemini_client, "generate_structured",
        lambda **kw: {
            "place_name": "Macaron Park", "place_location": "Taoyuan", "era": "modern",
            "paragraphs": ["a", "b", "c"], "pull_quote": "q",
            "insufficient_source": False,
        },
    )

    req = NarrationRequest(
        wikipedia_title="Macaron Park", place_name="Macaron Park",
        location="Taoyuan", language="en",
    )
    with caplog.at_level("WARNING"):
        narration_service.generate_narration(api_key="k", request=req)

    assert any("narration.legacy_title_path" in rec.message for rec in caplog.records)


def test_generate_hooks_with_wikidata_id_uses_pipeline(monkeypatch):
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _sufficient_bundle(),
    )

    def fake_generate_structured(**kw):
        return {
            "hooks": [{"id": "a", "title": "T", "teaser": "tz"}],
            "insufficient_source": False,
        }
    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = HooksRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_hooks(api_key="k", request=req)
    assert len(res.hooks) == 1


def test_generate_hooks_pre_gemini_gate_short_circuits(monkeypatch):
    calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )
    monkeypatch.setattr(narration_service.gemini_client, "generate_structured",
                        lambda **kw: calls.append(kw) or {})

    req = HooksRequest(wikidata_id="Q1", place_name="x", location="y", language="en")
    res = narration_service.generate_hooks(api_key="k", request=req)

    assert calls == []
    assert res.hooks == []
    assert res.insufficient_source is True
```

- [ ] **Step 3: Run tests to see them fail**

```bash
cd backend && uv run pytest tests/narration/test_service.py -v
```

Expected: new tests fail (service still uses `wikipedia_title` only).

- [ ] **Step 4: Replace `service.py` body**

Overwrite `backend/src/lorescape_backend/narration/service.py`:

```python
"""Orchestrate on-demand narration: source pipeline → Gemini → response model."""
from __future__ import annotations

import logging

from lorescape_backend.narration import gemini_client, prompts
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    HooksResponse,
    NarrationRequest,
    NarrationResponse,
    SUPPORTED_LANGUAGES,
)
from lorescape_backend.shared.story_prompt import StoryHook
from lorescape_backend.sources.models import SourceBundle
from lorescape_backend.sources.pipeline import (
    build_source_bundle,
    legacy_single_source_bundle,
)

logger = logging.getLogger(__name__)


class UnsupportedLanguageError(ValueError):
    """Raised when the request language is not one of SUPPORTED_LANGUAGES."""


def _validate_language(language: str) -> None:
    if language not in SUPPORTED_LANGUAGES:
        raise UnsupportedLanguageError(
            f"Unsupported language {language!r}; expected one of {SUPPORTED_LANGUAGES}"
        )


def _resolve_bundle(request) -> SourceBundle:
    """Build SourceBundle from either the new wikidata_id or legacy title."""
    if request.wikidata_id:
        return build_source_bundle(
            wikidata_id=request.wikidata_id,
            language=request.language,
            place_name=request.place_name,
        )
    logger.warning(
        "narration.legacy_title_path",
        extra={
            "title": request.wikipedia_title,
            "deprecated_remove_after": "2026-XX-XX",
        },
    )
    return legacy_single_source_bundle(title=request.wikipedia_title)


def generate_hooks(*, api_key: str, request: HooksRequest) -> HooksResponse:
    """Surface 2-3 narrative angles for the request's place."""
    _validate_language(request.language)
    bundle = _resolve_bundle(request)
    if not bundle.is_sufficient:
        logger.info(
            "narration.pre_gemini_gate", extra={"wikidata_id": bundle.wikidata_id},
        )
        return HooksResponse(hooks=[], insufficient_source=True)

    payload = gemini_client.generate_structured(
        api_key=api_key,
        system_instruction=prompts.hooks_system_instruction(request.language),
        user_prompt=prompts.build_hooks_user_prompt(
            place_name=request.place_name,
            location=request.location,
            source_bundle=bundle,
        ),
        response_schema=prompts.hooks_response_schema(request.language),
    )
    hooks = [HookItem(**item) for item in payload.get("hooks", [])]
    return HooksResponse(
        hooks=hooks,
        insufficient_source=bool(payload.get("insufficient_source", False)),
    )


def generate_narration(
    *, api_key: str, request: NarrationRequest
) -> NarrationResponse:
    """Generate the long-form 3-paragraph story for `request`."""
    _validate_language(request.language)
    bundle = _resolve_bundle(request)
    if not bundle.is_sufficient:
        logger.info(
            "narration.pre_gemini_gate", extra={"wikidata_id": bundle.wikidata_id},
        )
        return NarrationResponse(
            place_name=request.place_name,
            location=request.location,
            era="",
            paragraphs=[],
            pull_quote="",
            insufficient_source=True,
        )

    hook = (
        StoryHook(title=request.hook.title, teaser=request.hook.teaser)
        if request.hook is not None
        else None
    )
    payload = gemini_client.generate_structured(
        api_key=api_key,
        system_instruction=prompts.narration_system_instruction(request.language),
        user_prompt=prompts.build_narration_user_prompt(
            place_name=request.place_name,
            location=request.location,
            source_bundle=bundle,
            language=request.language,
            hook=hook,
        ),
        response_schema=prompts.narration_response_schema(request.language),
    )
    insufficient = bool(payload.get("insufficient_source", False))
    # Defence-in-depth: when the model flagged insufficient_source, ignore
    # whatever it placed in `paragraphs` (observed: model regurgitates the
    # in-prompt example).
    raw_paragraphs = payload.get("paragraphs", []) if not insufficient else []
    return NarrationResponse(
        place_name=payload["place_name"],
        location=payload["place_location"],
        era=payload["era"],
        paragraphs=list(raw_paragraphs),
        pull_quote=payload.get("pull_quote", "") if not insufficient else "",
        insufficient_source=insufficient,
    )
```

- [ ] **Step 5: Run tests to verify everything passes**

```bash
cd backend && uv run pytest tests/narration/ tests/sources/ tests/shared/ -v
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/narration/service.py backend/tests/narration/test_service.py
git commit -m "feat(narration): wire service to multi-source pipeline + pre-Gemini gate"
```

---

## Task 11: Full backend test suite + analyze

**Files:** (no edits — verification only)

- [ ] **Step 1: Run the full backend suite**

```bash
cd backend && uv run pytest -v
```

Expected: all tests pass. If anything in `test_api.py`, `test_prompts.py`, or other touched-but-not-updated files fails, fix the call site to use the new signature (it should already be updated; this is the catch-all check).

- [ ] **Step 2: Commit any final fixes**

```bash
git status
# If anything new, commit with a fix-up message; if nothing, skip.
```

---

## Task 12: Frontend — `narration_api_client.dart`

**Files:**
- Modify: `frontend/lib/features/narration/data/narration_api_client.dart`
- Modify: `frontend/test/features/narration/data/narration_api_client_test.dart`

- [ ] **Step 1: Read existing client + test**

```bash
cat frontend/lib/features/narration/data/narration_api_client.dart
sed -n '1,80p' frontend/test/features/narration/data/narration_api_client_test.dart
```

- [ ] **Step 2: Update the existing tests for new body shape**

In `narration_api_client_test.dart`, change every test that calls `client.fetchHooks(...)` or `client.fetchNarration(...)` from:

```dart
await client.fetchHooks(
  wikipediaTitle: 'Macaron Park',
  placeName: 'Macaron Park',
  location: 'Taoyuan',
  language: 'zh-TW',
);
```

to:

```dart
await client.fetchHooks(
  wikidataId: 'Q108234567',
  placeName: 'Macaron Park',
  location: 'Taoyuan',
  language: 'zh-TW',
);
```

…and update the request-body assertion to check `body['wikidata_id'] == 'Q108234567'` and `body.containsKey('wikipedia_title') == false`.

- [ ] **Step 3: Run tests to see them fail**

```bash
fvm flutter test test/features/narration/data/narration_api_client_test.dart
```

Expected: compile error (parameter `wikipediaTitle` no longer matches — but signature not yet updated, so it actually fails the opposite way: the test code mentions a non-existent `wikidataId` param). Both directions of failure are OK; the point is RED → GREEN.

- [ ] **Step 4: Update the client signature**

Edit `frontend/lib/features/narration/data/narration_api_client.dart`. Change every method that takes `required String wikipediaTitle` to take `required String wikidataId` instead, and change the JSON body to send `'wikidata_id': wikidataId` (removing `'wikipedia_title'`).

Example for `fetchHooks`:

```dart
Future<HooksResponseDto> fetchHooks({
  required String wikidataId,
  required String placeName,
  required String location,
  required String language,
}) async {
  final body = jsonEncode({
    'wikidata_id': wikidataId,
    'place_name': placeName,
    'location': location,
    'language': language,
  });
  // ... rest unchanged
}
```

Apply the same shape to `fetchNarration`. Preserve all other behavior (headers, error handling, dto parsing).

- [ ] **Step 5: Run tests to verify GREEN**

```bash
cd frontend && fvm flutter test test/features/narration/data/narration_api_client_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/narration/data/narration_api_client.dart \
        frontend/test/features/narration/data/narration_api_client_test.dart
git commit -m "feat(app): narration API client sends wikidata_id instead of wikipedia_title"
```

---

## Task 13: Frontend — `narration_api_service.dart` + `_extractWikidataId`

**Files:**
- Modify: `frontend/lib/features/narration/data/narration_api_service.dart`
- Create: `frontend/test/features/narration/data/narration_api_service_test.dart`

- [ ] **Step 1: Read existing service**

```bash
cat frontend/lib/features/narration/data/narration_api_service.dart
```

- [ ] **Step 2: Write failing tests**

Create `frontend/test/features/narration/data/narration_api_service_test.dart`:

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/data/narration_api_client.dart';
import 'package:context_app/features/narration/data/narration_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements NarrationApiClient {}

Place _place({required String id, String name = 'Macaron Park'}) {
  return Place(
    id: id,
    name: name,
    address: 'Taoyuan',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.0),
    tags: const [],
    photos: const [],
    category: PlaceCategory.modernUrban,
  );
}

void main() {
  late _MockClient client;
  late NarrationApiService service;

  setUp(() {
    client = _MockClient();
    service = NarrationApiService(client);
  });

  test(
    'Given a Place with wikidata-prefixed id '
    'When service.generateNarration is called '
    'Then client receives wikidataId extracted from the id',
    () async {
      // Read the existing NarrationResponseDto class to pick the right
      // constructor + required fields. Pattern: use the same shape that
      // existing passing tests use for the happy-path response.
      when(() => client.fetchNarration(
        wikidataId: any(named: 'wikidataId'),
        placeName: any(named: 'placeName'),
        location: any(named: 'location'),
        language: any(named: 'language'),
      )).thenAnswer((_) async => _happyNarrationResponse());

      await service.generateNarration(
        place: _place(id: 'wikidata:Q108234567'),
        language: 'zh-TW',
      );

      verify(() => client.fetchNarration(
        wikidataId: 'Q108234567',
        placeName: 'Macaron Park',
        location: any(named: 'location'),
        language: 'zh-TW',
      )).called(1);
    },
  );

  test(
    'Given a Place whose id does NOT start with wikidata: prefix '
    'When service.generateNarration is called '
    'Then service short-circuits to insufficient_source without calling the client',
    () async {
      final res = await service.generateNarration(
        place: _place(id: 'someOtherId'),
        language: 'en',
      );

      verifyNever(() => client.fetchNarration(
        wikidataId: any(named: 'wikidataId'),
        placeName: any(named: 'placeName'),
        location: any(named: 'location'),
        language: any(named: 'language'),
      ));
      expect(res.insufficientSource, isTrue);
    },
  );
}

// Local helper. Implement by reading the actual NarrationResponseDto
// constructor in lib/features/narration/data/ — match the field names
// (`placeName`, `location`, `era`, `paragraphs`, `pullQuote`,
// `insufficientSource` or whatever the existing dto exposes).
NarrationResponseDto _happyNarrationResponse() {
  return NarrationResponseDto(
    // Fill from real dto. Example shape only:
    // placeName: 'Macaron Park',
    // location: 'Taoyuan',
    // era: 'modern',
    // paragraphs: const ['a', 'b', 'c'],
    // pullQuote: 'q',
    // insufficientSource: false,
  );
}
```

The `NarrationResponseDto` constructor exists in `frontend/lib/features/narration/data/`; read it first so the helper matches the real field names. The test cares about the call, not the response shape.

- [ ] **Step 3: Run tests to see them fail**

```bash
cd frontend && fvm flutter test test/features/narration/data/narration_api_service_test.dart
```

Expected: compile error or assertion failure.

- [ ] **Step 4: Update the service**

Edit `frontend/lib/features/narration/data/narration_api_service.dart`:

1. Add this top-level private helper at the bottom of the file:

```dart
String? _extractWikidataId(String placeId) {
  const prefix = 'wikidata:';
  if (!placeId.startsWith(prefix)) return null;
  return placeId.substring(prefix.length);
}
```

2. In the `generateNarration` (or equivalent) method, replace the line that previously did `wikipediaTitle: place.name` with this branch:

```dart
final wikidataId = _extractWikidataId(place.id);
if (wikidataId == null) {
  // Defensive: current Explore flow always emits `wikidata:` prefixed ids.
  // If we land here it indicates an upstream bug; degrade to the same
  // UX as a backend insufficient_source response.
  // logger.severe('Place without wikidata_id reached narration: ${place.id}');
  return NarrationResponseDto.insufficientSource(
    placeName: place.name,
    location: ...,
  );
}

final response = await _client.fetchNarration(
  wikidataId: wikidataId,
  placeName: place.name,
  location: ...,
  language: language,
);
```

(Use the existing logger and the existing insufficient factory shape if they exist; otherwise construct an equivalent insufficient response with empty paragraphs + `insufficientSource: true`. Read the DTO/state to choose the right shape.)

- [ ] **Step 5: Run tests to verify GREEN**

```bash
cd frontend && fvm flutter test test/features/narration/data/narration_api_service_test.dart
```

Expected: both tests pass.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/narration/data/narration_api_service.dart \
        frontend/test/features/narration/data/narration_api_service_test.dart
git commit -m "feat(app): extract wikidata_id from place.id; fail-safe insufficient fallback"
```

---

## Task 14: Frontend — `story_hook_api_service.dart` + test

**Files:**
- Modify: `frontend/lib/features/narration/data/story_hook_api_service.dart`
- Create: `frontend/test/features/narration/data/story_hook_api_service_test.dart`

Apply exactly the same pattern as Task 13 to `story_hook_api_service.dart`:

- [ ] **Step 1: Read existing service**

```bash
cat frontend/lib/features/narration/data/story_hook_api_service.dart
```

- [ ] **Step 2: Write failing test**

Create `frontend/test/features/narration/data/story_hook_api_service_test.dart` mirroring Task 13's pattern (mock the client, assert it's called with `wikidataId` extracted from `place.id`, second test asserts insufficient-fallback when prefix missing).

- [ ] **Step 3: Run test to see it fail**

```bash
cd frontend && fvm flutter test test/features/narration/data/story_hook_api_service_test.dart
```

- [ ] **Step 4: Update the service**

Add the same private helper at the bottom of `story_hook_api_service.dart`:

```dart
String? _extractWikidataId(String placeId) {
  const prefix = 'wikidata:';
  if (!placeId.startsWith(prefix)) return null;
  return placeId.substring(prefix.length);
}
```

Replace the `wikipediaTitle: place.name` argument site to use the helper + insufficient fallback, mirroring Task 13.

- [ ] **Step 5: Verify GREEN**

```bash
cd frontend && fvm flutter test test/features/narration/data/story_hook_api_service_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/narration/data/story_hook_api_service.dart \
        frontend/test/features/narration/data/story_hook_api_service_test.dart
git commit -m "feat(app): story hook service extracts wikidata_id from place.id"
```

---

## Task 15: Full frontend suite + analyze + manual smoke

**Files:** (no edits — verification only)

- [ ] **Step 1: Run full Flutter test suite**

```bash
cd frontend && fvm flutter test
```

Expected: all green.

- [ ] **Step 2: Run static analysis**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: no errors / warnings / infos.

- [ ] **Step 3: Manual smoke test (per spec §9.5)**

Run the app against the deployed-or-local backend (whichever is configured). Tick each item:

- [ ] App near 桃園青埔 → 找到「馬卡龍公園」→ 進 narration → 看到實際故事
- [ ] App 搜尋 "Sydney Opera House" → 看到實際故事（驗證 en 路徑沒壞）
- [ ] Backend log 沒有 `narration.legacy_title_path`（驗證新 App 不走老路徑）
- [ ] 手動讓 App 送老 contract（暫改 client 送 `wikipedia_title`）→ 後端 handle、log 有 warning
- [ ] 真的沒料的偏門地方 → 顯示 insufficient UI

- [ ] **Step 4: Commit final cleanup (if any) + announce**

```bash
git status
# If smoke test surfaced anything, commit fixes. Otherwise nothing to commit.
```

---

## Done. What's next

- Deploy backend first (向下相容 → 老 App 不掛)
- Push App update through stores
- Periodically grep VPS log for `narration.legacy_title_path`; when frequency drops below your tolerance, open a follow-up PR to remove the legacy path
