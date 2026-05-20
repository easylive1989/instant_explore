# IG Card Phase 2 — Schema & Gemini Prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `daily_stories` + `daily_story_places` schema and rewrite the zh-TW Gemini prompt so each newly-generated row carries every field Phase 1's `CardContent` needs.

**Architecture:** SQL migration adds 5 nullable columns to `daily_story_places` (place-static) and 6 nullable columns to `daily_stories` (story-dynamic, `card_` prefix). `prompts.py` becomes language-aware via `build_response_schema(language)` and a forked `build_user_prompt` body for zh-TW. `gemini_client.GeneratedStory` + `story_writer.StoryRow` grow matching optional fields. `job.py` derives the existing `story` column from joined paragraphs in the zh-TW path. The en path is untouched end-to-end.

**Tech Stack:** Python 3.12, pytest, Supabase Postgres migrations, `google-genai` structured output, `supabase-py`.

**Spec:** `docs/superpowers/specs/2026-05-21-ig-card-phase2-schema-prompt-design.md`

---

## File Map

**Create:**
- `supabase/migrations/20260521120000_add_card_fields_to_daily_stories.sql` — schema change
- `docs/operations/2026-05-21-backfill-card-fields-for-places.md` — manual backfill SQL guide

**Modify:**
- `backend/src/lorescape_backend/daily_story/prompts.py` — language-aware schema + prompt
- `backend/src/lorescape_backend/daily_story/gemini_client.py` — extend `GeneratedStory`
- `backend/src/lorescape_backend/daily_story/story_writer.py` — extend `StoryRow` + tuple→list
- `backend/src/lorescape_backend/daily_story/job.py` — zh-TW path passes language schema, joins paragraphs into `story`, propagates card fields
- `backend/tests/test_prompts.py` — language-aware tests
- `backend/tests/test_gemini_client.py` — new fields parsed
- `backend/tests/test_story_writer.py` — new fields round-trip
- `backend/tests/test_job.py` — zh-TW path derives `story`, passes card fields

---

## Commands

Run all backend commands from `backend/` (where `pyproject.toml` lives):

```bash
cd backend
uv run pytest path/to/test.py::test_name -v   # single test
uv run pytest tests/test_prompts.py -v        # one file
uv run pytest -q                              # full suite
```

Supabase commands run from the repo root.

---

## Task 1: Migration — add card_* columns

**Files:**
- Create: `supabase/migrations/20260521120000_add_card_fields_to_daily_stories.sql`

- [ ] **Step 1: Create the migration SQL**

Write file `supabase/migrations/20260521120000_add_card_fields_to_daily_stories.sql`:

```sql
-- Phase 2 of IG card auto-post: extend the daily story schema with the fields
-- that the IG card renderer (Phase 1) needs.
--
-- Two groups:
-- 1. daily_story_places: 5 static-per-place fields (English spine name,
--    single-char + uppercase city, lat/lng). These are admin-curated, not
--    LLM-generated.
-- 2. daily_stories: 6 story-dynamic fields produced by Gemini in the zh-TW
--    path. All `card_` prefixed for clarity vs existing `story` / `era`.
--
-- All columns nullable. Existing rows stay NULL. The Phase 3 publisher will
-- NULL-check before attempting an IG post; Threads keeps working without
-- these fields.

alter table public.daily_story_places
  add column card_location_en text,
  add column card_city_ch     text,
  add column card_city_en     text,
  add column latitude         numeric,
  add column longitude        numeric;

alter table public.daily_stories
  add column card_title_ch               text,
  add column card_title_sub_ch           text,
  add column card_paragraphs_ch          text[],
  add column card_pull_quote_ch          text,
  add column card_pull_quote_attrib_ch   text,
  add column card_anno_roman             text;
```

- [ ] **Step 2: Reset local Supabase and confirm migration applies**

Run from repo root:

```bash
supabase db reset
```

Expected: command succeeds; final output lists this migration alongside the existing ones, no SQL errors.

- [ ] **Step 3: Verify columns exist via psql**

Run from repo root:

```bash
supabase db psql -c "\d public.daily_story_places"
supabase db psql -c "\d public.daily_stories"
```

Expected: `daily_story_places` shows `card_location_en`, `card_city_ch`, `card_city_en`, `latitude`, `longitude`. `daily_stories` shows the six new `card_*` columns plus `card_paragraphs_ch` typed as `text[]`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260521120000_add_card_fields_to_daily_stories.sql
git commit -m "feat(db): add card_* columns to daily_stories and daily_story_places"
```

---

## Task 2: Refactor prompts.py to language-aware schema builder

This task is a **pure refactor** — the schema content for both languages stays identical (the current `GEMINI_RESPONSE_SCHEMA`). Task 3 will diverge them.

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/prompts.py`
- Modify: `backend/src/lorescape_backend/daily_story/job.py:55`
- Modify: `backend/tests/test_prompts.py`

- [ ] **Step 1: Write the failing test in `backend/tests/test_prompts.py`**

Replace the `test_response_schema_requires_six_fields` and `test_response_schema_hashtags_is_array_of_strings` tests, and remove the `GEMINI_RESPONSE_SCHEMA` import. New test block at top:

```python
import pytest

from lorescape_backend.daily_story.prompts import (
    SYSTEM_INSTRUCTION,
    build_response_schema,
    build_user_prompt,
)


def test_build_response_schema_en_requires_six_fields():
    schema = build_response_schema("en")
    assert set(schema["required"]) == {
        "place_name", "place_location", "era", "story",
        "threads_summary", "hashtags",
    }


def test_build_response_schema_zh_tw_requires_six_fields():
    schema = build_response_schema("zh-TW")
    # Same set as en for Task 2 — Task 3 will add card_* fields here.
    assert set(schema["required"]) == {
        "place_name", "place_location", "era", "story",
        "threads_summary", "hashtags",
    }


def test_build_response_schema_hashtags_is_array_of_strings():
    schema = build_response_schema("en")
    hashtags = schema["properties"]["hashtags"]
    assert hashtags["type"] == "ARRAY"
    assert hashtags["items"]["type"] == "STRING"


def test_build_response_schema_raises_on_unknown_language():
    with pytest.raises(KeyError):
        build_response_schema("ja")
```

Leave the other existing tests in `test_prompts.py` untouched.

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_prompts.py -v
```

Expected: `ImportError` because `build_response_schema` does not exist yet, plus any test that imports `GEMINI_RESPONSE_SCHEMA` now fails (we removed that import).

- [ ] **Step 3: Refactor `prompts.py`**

Replace `backend/src/lorescape_backend/daily_story/prompts.py` body so `GEMINI_RESPONSE_SCHEMA` becomes a function. Final file:

```python
"""Gemini prompt + structured-output schema for daily story generation.

Goal: produce vivid, narrative-rich historical stories grounded strictly in
the provided Wikipedia extract — concrete moments, named figures, dated
events, in the style of a popular history book — while minimising
hallucination.
"""
from __future__ import annotations


SYSTEM_INSTRUCTION = (
    "You are a historian and storyteller. Write a vivid, narrative-rich "
    "historical short story about a famous landmark, based STRICTLY on the "
    "Wikipedia content provided. Do NOT introduce any historical facts, names, "
    "or events that do not appear in the source material. If the source is "
    "insufficient for a specific claim, omit it rather than invent. Strive for "
    "the dramatic, multi-paragraph storytelling style of a popular history "
    "book — open with a concrete scene, name real historical figures, cite "
    "specific dates, and use evocative imagery drawn from the source."
)


_LANGUAGE_NAMES = {
    "zh-TW": "Traditional Chinese (zh-TW)",
    "en": "English (en)",
}


_BASE_PROPERTIES: dict = {
    "place_name": {"type": "STRING"},
    "place_location": {"type": "STRING"},
    "era": {"type": "STRING"},
    "story": {"type": "STRING"},
    "threads_summary": {"type": "STRING"},
    "hashtags": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
    },
}

_BASE_REQUIRED = [
    "place_name",
    "place_location",
    "era",
    "story",
    "threads_summary",
    "hashtags",
]


def build_response_schema(language: str) -> dict:
    """Return the Gemini structured-output schema for the given language.

    Phase 2 keeps both languages identical; Phase 2 follow-up (Task 3) adds
    card-specific fields to the zh-TW schema.
    """
    if language not in _LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": dict(_BASE_PROPERTIES),
        "required": list(_BASE_REQUIRED),
    }


def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair."""
    language_name = _LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    return (
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):\n'
        f"<<<\n{wikipedia_extract}\n>>>\n\n"
        f"Write a 700-1200 character true historical short story in {language_name}.\n"
        "\n"
        "Style:\n"
        "- Multiple short paragraphs, each centred on a specific moment, "
        "person, or turning point.\n"
        "- Open with a concrete scene — a dated event, a person acting in a "
        'place — not a textbook summary like "X is a landmark in Y".\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years or eras (e.g. '1492', '70-80 CE', '明朝') "
        "when stating events.\n"
        "- Reference real named people from the source (rulers, architects, "
        "chroniclers, generals, etc).\n"
        "- Close with one short reflective line about the landmark's enduring "
        "significance.\n"
        "- Do NOT end the story with a redundant 'place name, location, era' "
        "summary — those values are returned as separate fields below.\n"
        "\n"
        f"Also produce a punchier 300-400 character version of the same story "
        f"in {language_name}, ending on a hook or open question rather than "
        "wrapping up neatly. This shorter version must fit comfortably under "
        "500 characters total — it will be posted as a single Threads post.\n"
        "\n"
        "Also produce 3-5 hashtags drawn from the country, era, and theme "
        "of this place. Each tag should be a single lowerCamelCase word "
        "without the '#' prefix, ASCII letters/digits only (so they work as "
        "hashtags on English-language social media regardless of the story "
        "language).\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- story: the 700-1200 character narrative\n"
        "- threads_summary: the 300-400 character punchier version\n"
        "- hashtags: array of 3-5 lowerCamelCase ASCII hashtag strings "
        "(no '#' prefix)\n"
    )
```

Note: `GEMINI_RESPONSE_SCHEMA` (the old module-level constant) is **deleted**; downstream uses `build_response_schema(language)`.

- [ ] **Step 4: Update the call site in `job.py:55`**

In `backend/src/lorescape_backend/daily_story/job.py`, replace this line inside the `for language in LANGUAGES:` loop:

```python
        response_schema=prompts.GEMINI_RESPONSE_SCHEMA,
```

with:

```python
        response_schema=prompts.build_response_schema(language),
```

- [ ] **Step 5: Run prompts tests**

```bash
cd backend && uv run pytest tests/test_prompts.py -v
```

Expected: all tests pass.

- [ ] **Step 6: Run job tests to confirm refactor didn't break them**

```bash
cd backend && uv run pytest tests/test_job.py -v
```

Expected: all tests pass (they mock `generate_story`, so the schema change is irrelevant to them).

- [ ] **Step 7: Run full backend test suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/prompts.py \
        backend/src/lorescape_backend/daily_story/job.py \
        backend/tests/test_prompts.py
git commit -m "refactor(prompts): replace GEMINI_RESPONSE_SCHEMA with build_response_schema(language)"
```

---

## Task 3: Add zh-TW card fields to prompts.py

Diverge zh-TW from en: add 6 card fields to the zh-TW schema (and drop `story` from the zh-TW required set, since Phase 2 derives it from joined paragraphs), and rewrite the zh-TW prompt body to instruct on the card fields.

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/prompts.py`
- Modify: `backend/tests/test_prompts.py`

- [ ] **Step 1: Write failing tests for zh-TW schema divergence**

Replace `test_build_response_schema_zh_tw_requires_six_fields` in `tests/test_prompts.py` (added in Task 2) with the following new tests:

```python
ZH_CARD_FIELDS = {
    "card_title_ch",
    "card_title_sub_ch",
    "card_paragraphs_ch",
    "card_pull_quote_ch",
    "card_pull_quote_attrib_ch",
    "card_anno_roman",
}


def test_build_response_schema_zh_tw_has_card_fields_but_not_story():
    schema = build_response_schema("zh-TW")
    required = set(schema["required"])
    # All card fields required
    assert ZH_CARD_FIELDS.issubset(required)
    # story is replaced by paragraphs — must not be required in zh-TW
    assert "story" not in required
    # base fields still required (story removed)
    assert {"place_name", "place_location", "era", "threads_summary",
            "hashtags"}.issubset(required)


def test_build_response_schema_zh_tw_paragraphs_is_array_of_strings():
    schema = build_response_schema("zh-TW")
    paragraphs = schema["properties"]["card_paragraphs_ch"]
    assert paragraphs["type"] == "ARRAY"
    assert paragraphs["items"]["type"] == "STRING"
    # Spec calls for exactly 3 paragraphs.
    assert paragraphs.get("minItems") == 3
    assert paragraphs.get("maxItems") == 3


def test_build_response_schema_en_unchanged():
    schema = build_response_schema("en")
    required = set(schema["required"])
    assert "story" in required
    # English path must NOT carry the zh-TW card fields.
    assert ZH_CARD_FIELDS.isdisjoint(required)
    assert ZH_CARD_FIELDS.isdisjoint(schema["properties"].keys())


def test_build_user_prompt_zh_tw_lists_card_fields():
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
        language="zh-TW",
    )
    for field in ZH_CARD_FIELDS:
        assert field in prompt, f"zh-TW prompt missing field guidance: {field}"
    # zh-TW must instruct on exactly 3 paragraphs
    assert "3" in prompt or "三段" in prompt or "三" in prompt


def test_build_user_prompt_en_does_not_mention_card_fields():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    for field in ZH_CARD_FIELDS:
        assert field not in prompt, f"en prompt leaked card field: {field}"
```

Also update the existing `test_build_user_prompt_lists_required_fields` so the `story` check only runs for the `en` language (zh-TW no longer has it):

```python
def test_build_user_prompt_lists_required_fields():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    for field in ("place_name", "place_location", "era", "story"):
        assert field in prompt
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_prompts.py -v
```

Expected: the four new tests fail (missing fields / story still present in zh-TW); the en-unchanged test passes.

- [ ] **Step 3: Add zh-TW card properties and a forked builder**

In `prompts.py`, after the existing `_BASE_REQUIRED` block, add:

```python
_ZH_CARD_PROPERTIES: dict = {
    "card_title_ch": {"type": "STRING"},
    "card_title_sub_ch": {"type": "STRING"},
    "card_paragraphs_ch": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
    "card_pull_quote_ch": {"type": "STRING"},
    "card_pull_quote_attrib_ch": {"type": "STRING"},
    "card_anno_roman": {"type": "STRING"},
}

_ZH_CARD_REQUIRED = [
    "card_title_ch",
    "card_title_sub_ch",
    "card_paragraphs_ch",
    "card_pull_quote_ch",
    "card_pull_quote_attrib_ch",
    "card_anno_roman",
]
```

Replace `build_response_schema`:

```python
def build_response_schema(language: str) -> dict:
    """Return the Gemini structured-output schema for the given language.

    zh-TW returns the base fields *minus* `story` *plus* six `card_*` fields
    used by the IG card renderer. The writer derives `story` from the joined
    `card_paragraphs_ch`. en keeps the original story-in-a-single-string
    shape.
    """
    if language == "zh-TW":
        # Drop `story` from base — zh-TW returns paragraphs instead.
        base_props = {k: v for k, v in _BASE_PROPERTIES.items() if k != "story"}
        base_required = [k for k in _BASE_REQUIRED if k != "story"]
        return {
            "type": "OBJECT",
            "properties": {**base_props, **_ZH_CARD_PROPERTIES},
            "required": base_required + _ZH_CARD_REQUIRED,
        }
    if language == "en":
        return {
            "type": "OBJECT",
            "properties": dict(_BASE_PROPERTIES),
            "required": list(_BASE_REQUIRED),
        }
    raise KeyError(f"Unknown language: {language!r}")
```

- [ ] **Step 4: Fork `build_user_prompt` by language**

Replace `build_user_prompt` in `prompts.py` with two private builders + a public dispatcher. Final shape:

```python
def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair."""
    language_name = _LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    intro = (
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):\n'
        f"<<<\n{wikipedia_extract}\n>>>\n\n"
    )
    if language == "zh-TW":
        return intro + _zh_tw_body(language_name)
    return intro + _en_body(language_name)


def _en_body(language_name: str) -> str:
    return (
        f"Write a 700-1200 character true historical short story in {language_name}.\n"
        "\n"
        "Style:\n"
        "- Multiple short paragraphs, each centred on a specific moment, "
        "person, or turning point.\n"
        "- Open with a concrete scene — a dated event, a person acting in a "
        'place — not a textbook summary like "X is a landmark in Y".\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years or eras (e.g. '1492', '70-80 CE', '明朝') "
        "when stating events.\n"
        "- Reference real named people from the source (rulers, architects, "
        "chroniclers, generals, etc).\n"
        "- Close with one short reflective line about the landmark's enduring "
        "significance.\n"
        "- Do NOT end the story with a redundant 'place name, location, era' "
        "summary — those values are returned as separate fields below.\n"
        "\n"
        f"Also produce a punchier 300-400 character version of the same story "
        f"in {language_name}, ending on a hook or open question rather than "
        "wrapping up neatly. This shorter version must fit comfortably under "
        "500 characters total — it will be posted as a single Threads post.\n"
        "\n"
        "Also produce 3-5 hashtags drawn from the country, era, and theme "
        "of this place. Each tag should be a single lowerCamelCase word "
        "without the '#' prefix, ASCII letters/digits only (so they work as "
        "hashtags on English-language social media regardless of the story "
        "language).\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- story: the 700-1200 character narrative\n"
        "- threads_summary: the 300-400 character punchier version\n"
        "- hashtags: array of 3-5 lowerCamelCase ASCII hashtag strings "
        "(no '#' prefix)\n"
    )


def _zh_tw_body(language_name: str) -> str:
    # Tailored for the IG card layout: 3 short paragraphs (drop-cap on first),
    # a pull quote, attribution, and a Roman-numeral year for the masthead.
    return (
        f"Write a true historical short story in {language_name}, structured as "
        "exactly 3 paragraphs of 60-100 Traditional Chinese characters each.\n"
        "\n"
        "Style:\n"
        "- Each paragraph centres on a specific moment, person, or turning point.\n"
        "- Open paragraph 1 with a concrete scene — a dated event, a real person "
        "acting in a real place. The first character should be a concrete noun "
        "or name (it will be rendered as a large drop-cap), not a function word "
        '(e.g. avoid starting with "在", "當", "這", "那").\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years (use Han numerals for years in body text, "
        "e.g. 一八八九年) and reference real named people from the source.\n"
        "- Do NOT end with a redundant '地名, 地點, 年代' summary — those "
        "values are returned as separate fields below.\n"
        "\n"
        f"Also produce a punchier 300-400 character version of the same story "
        f"in {language_name} as `threads_summary`, ending on a hook or open "
        "question. This shorter version must fit under 500 characters total — "
        "it will be posted as a single Threads post.\n"
        "\n"
        "Also produce 3-5 hashtags drawn from the country, era, and theme. "
        "Each tag is a single lowerCamelCase word without the '#' prefix, "
        "ASCII letters/digits only.\n"
        "\n"
        "ADDITIONALLY, produce the following Instagram-card fields:\n"
        "- card_title_ch: a punchy Traditional Chinese main title that captures "
        "the central tension of the story (≤ 14 characters, must NOT just "
        "repeat the place name).\n"
        "- card_title_sub_ch: a subtitle that complements the main title "
        "(≤ 20 characters; full-width quotes 「」allowed).\n"
        "- card_paragraphs_ch: the same 3 paragraphs above, returned as a "
        "JSON array of 3 strings (one paragraph per element, no leading/"
        "trailing whitespace).\n"
        "- card_pull_quote_ch: one short, dramatic quote from the story, "
        "wrapped in full-width Chinese quotation marks 「」 or 『』. Prefer "
        "real quotes from the source over invented lines.\n"
        "- card_pull_quote_attrib_ch: attribution for the pull quote, "
        "beginning with the full-width em-dash ──. Use Han numerals for "
        "years (example: ── 莫泊桑，一八八九).\n"
        "- card_anno_roman: the representative year of the story as Roman "
        "numerals (example: 1889 → MDCCCLXXXIX). If the story spans a range, "
        "pick one representative year.\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- threads_summary: the 300-400 character punchier version\n"
        "- hashtags: array of 3-5 lowerCamelCase ASCII hashtag strings\n"
        "- card_title_ch, card_title_sub_ch, card_paragraphs_ch, "
        "card_pull_quote_ch, card_pull_quote_attrib_ch, card_anno_roman: "
        "as described above\n"
    )
```

- [ ] **Step 5: Run prompts tests**

```bash
cd backend && uv run pytest tests/test_prompts.py -v
```

Expected: all tests pass (including the 5 new zh-TW ones).

- [ ] **Step 6: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green. `test_job.py` still passes because it mocks `generate_story` — it doesn't see the schema change.

- [ ] **Step 7: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/prompts.py \
        backend/tests/test_prompts.py
git commit -m "feat(prompts): add zh-TW card fields to Gemini schema and prompt"
```

---

## Task 4: Extend `GeneratedStory` dataclass with optional card fields

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/gemini_client.py`
- Modify: `backend/tests/test_gemini_client.py`

- [ ] **Step 1: Write failing test for zh-TW JSON parsing**

Append to `backend/tests/test_gemini_client.py`:

```python
@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_parses_zh_tw_card_fields(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "艾菲爾鐵塔",
            "place_location": "巴黎",
            "era": "十九世紀末",
            "threads_summary": "短摘",
            "hashtags": ["paris", "eiffelTower"],
            "card_title_ch": "討厭鐵塔的文學大師",
            "card_title_sub_ch": "莫泊桑的「專屬午餐位」",
            "card_paragraphs_ch": ["第一段", "第二段", "第三段"],
            "card_pull_quote_ch": "「看不見艾菲爾鐵塔的地方。」",
            "card_pull_quote_attrib_ch": "—— 莫泊桑，一八八九",
            "card_anno_roman": "MDCCCLXXXIX",
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    result = generate_story(
        api_key="key",
        system_instruction="sys",
        user_prompt="user",
        response_schema={"type": "OBJECT"},
    )

    # story is None for zh-TW path (writer derives it from paragraphs)
    assert result.story is None
    assert result.card_title_ch == "討厭鐵塔的文學大師"
    assert result.card_title_sub_ch == "莫泊桑的「專屬午餐位」"
    assert result.card_paragraphs_ch == ("第一段", "第二段", "第三段")
    assert result.card_pull_quote_ch == "「看不見艾菲爾鐵塔的地方。」"
    assert result.card_pull_quote_attrib_ch == "—— 莫泊桑，一八八九"
    assert result.card_anno_roman == "MDCCCLXXXIX"


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_leaves_card_fields_none_when_absent(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "X",
            "place_location": "Y",
            "era": "Z",
            "story": "english story",
            "threads_summary": "T",
            "hashtags": [],
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    result = generate_story(
        api_key="key",
        system_instruction="sys",
        user_prompt="user",
        response_schema={"type": "OBJECT"},
    )

    assert result.story == "english story"
    assert result.card_title_ch is None
    assert result.card_title_sub_ch is None
    assert result.card_paragraphs_ch is None
    assert result.card_pull_quote_ch is None
    assert result.card_pull_quote_attrib_ch is None
    assert result.card_anno_roman is None
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_gemini_client.py -v
```

Expected: both new tests fail (`AttributeError` on `result.card_title_ch` or `TypeError` on `GeneratedStory(...)` missing the new attribute).

- [ ] **Step 3: Extend `GeneratedStory` and parsing**

Replace `backend/src/lorescape_backend/daily_story/gemini_client.py` body:

```python
"""Gemini API wrapper using google-genai SDK with structured JSON output."""
from __future__ import annotations

import json
from dataclasses import dataclass, field

from google import genai
from google.genai import types

GEMINI_MODEL = "gemini-2.5-pro"
GEMINI_TEMPERATURE = 0.3


@dataclass(frozen=True)
class GeneratedStory:
    """Structured output from the Gemini story generation call.

    Card fields are populated only on the zh-TW path; en leaves them None.
    For zh-TW, `story` is also None — the writer derives it by joining
    `card_paragraphs_ch`.
    """

    place_name: str
    place_location: str
    era: str
    story: str | None
    threads_summary: str
    hashtags: tuple[str, ...]
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None


def generate_story(
    *,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: dict,
) -> GeneratedStory:
    """Call Gemini and parse the JSON response into a GeneratedStory.

    Uses structured JSON output mode so the response is always valid JSON
    matching the provided schema.
    """
    client = genai.Client(api_key=api_key)

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=GEMINI_TEMPERATURE,
        response_mime_type="application/json",
        response_schema=response_schema,
    )

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[user_prompt],
        config=config,
    )

    data = json.loads(response.text)
    paragraphs = data.get("card_paragraphs_ch")
    return GeneratedStory(
        place_name=data["place_name"],
        place_location=data["place_location"],
        era=data["era"],
        story=data.get("story"),
        threads_summary=data["threads_summary"],
        hashtags=tuple(data["hashtags"]),
        card_title_ch=data.get("card_title_ch"),
        card_title_sub_ch=data.get("card_title_sub_ch"),
        card_paragraphs_ch=tuple(paragraphs) if paragraphs is not None else None,
        card_pull_quote_ch=data.get("card_pull_quote_ch"),
        card_pull_quote_attrib_ch=data.get("card_pull_quote_attrib_ch"),
        card_anno_roman=data.get("card_anno_roman"),
    )
```

Also fix the existing positional `GeneratedStory(...)` constructions in tests — the `story` argument is now type `str | None` but existing tests pass a string, so they still work. Verify the existing `test_generate_story_parses_json_response` assertion still matches: the expected `GeneratedStory(...)` literal uses keyword args and a `story="..."` value, so it stays valid (new card fields default to None).

- [ ] **Step 4: Run gemini_client tests**

```bash
cd backend && uv run pytest tests/test_gemini_client.py -v
```

Expected: all 4 tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green. `test_job.py` uses `GeneratedStory("...", "...", "...", "...", threads_summary=..., hashtags=...)` — those 4 positional args still align with the dataclass field order (`place_name, place_location, era, story`), and the new fields default to None.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/gemini_client.py \
        backend/tests/test_gemini_client.py
git commit -m "feat(gemini): parse zh-TW card_* fields into GeneratedStory"
```

---

## Task 5: Extend `StoryRow` + `insert_story` for card fields

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/story_writer.py`
- Modify: `backend/tests/test_story_writer.py`

- [ ] **Step 1: Write failing tests**

Append to `backend/tests/test_story_writer.py`:

```python
def test_insert_story_writes_zh_tw_card_fields_with_paragraphs_as_list():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 21),
        language="zh-TW",
        place_id="place-1",
        place_name="艾菲爾鐵塔",
        place_location="巴黎",
        era="十九世紀末",
        story="第一段\n\n第二段\n\n第三段",
        image_url=None,
        wikipedia_url="https://zh.wikipedia.org/wiki/...",
        threads_summary="短摘",
        hashtags=("paris", "eiffelTower"),
        card_title_ch="討厭鐵塔的文學大師",
        card_title_sub_ch="莫泊桑的「專屬午餐位」",
        card_paragraphs_ch=("第一段", "第二段", "第三段"),
        card_pull_quote_ch="「看不見艾菲爾鐵塔的地方。」",
        card_pull_quote_attrib_ch="—— 莫泊桑，一八八九",
        card_anno_roman="MDCCCLXXXIX",
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    # text[] columns must be JSON arrays, not tuples
    assert payload["card_paragraphs_ch"] == ["第一段", "第二段", "第三段"]
    assert isinstance(payload["card_paragraphs_ch"], list)
    assert payload["card_title_ch"] == "討厭鐵塔的文學大師"
    assert payload["card_title_sub_ch"] == "莫泊桑的「專屬午餐位」"
    assert payload["card_pull_quote_ch"] == "「看不見艾菲爾鐵塔的地方。」"
    assert payload["card_pull_quote_attrib_ch"] == "—— 莫泊桑，一八八九"
    assert payload["card_anno_roman"] == "MDCCCLXXXIX"


def test_insert_story_leaves_card_fields_null_for_en_row():
    chain = MagicMock()
    chain.upsert.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "x"}])
    client = MagicMock()
    client.table.return_value = chain

    row = StoryRow(
        publish_date=date(2026, 5, 21),
        language="en",
        place_id="place-1",
        place_name="Eiffel Tower",
        place_location="Paris",
        era="Late 19th century",
        story="English story",
        image_url=None,
        wikipedia_url="https://en.wikipedia.org/wiki/Eiffel_Tower",
        threads_summary="t",
        hashtags=(),
    )

    insert_story(client, row)

    payload = chain.upsert.call_args[0][0]
    for field in (
        "card_title_ch",
        "card_title_sub_ch",
        "card_paragraphs_ch",
        "card_pull_quote_ch",
        "card_pull_quote_attrib_ch",
        "card_anno_roman",
    ):
        assert payload[field] is None, f"expected {field} to be None for en row"
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_story_writer.py -v
```

Expected: both new tests fail (`TypeError` on `StoryRow(...)` with unknown kwargs, or `KeyError` on payload assertions).

- [ ] **Step 3: Extend `StoryRow` + `insert_story`**

Replace `backend/src/lorescape_backend/daily_story/story_writer.py`:

```python
"""Insert daily story rows into Supabase."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import date


@dataclass(frozen=True)
class StoryRow:
    publish_date: date
    language: str
    place_id: str
    place_name: str
    place_location: str
    era: str
    story: str
    image_url: str | None
    wikipedia_url: str
    threads_summary: str
    hashtags: tuple[str, ...] = field(default_factory=tuple)
    # IG card fields — populated only on the zh-TW path.
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language)).

    The new social-publishing columns (discord_message_id, review_state, etc.)
    are written separately by the discord_review and publisher modules — this
    function only writes the story content itself.
    """
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    payload["hashtags"] = list(row.hashtags)
    if row.card_paragraphs_ch is not None:
        payload["card_paragraphs_ch"] = list(row.card_paragraphs_ch)
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
```

Note: `asdict` already converts tuples to lists for `hashtags`-style fields by recursion, but the explicit re-assignment matches the existing pattern and makes the conversion intent obvious. The `card_paragraphs_ch` line guards `None` since `list(None)` would raise.

- [ ] **Step 4: Run writer tests**

```bash
cd backend && uv run pytest tests/test_story_writer.py -v
```

Expected: all 4 tests pass. The existing `test_insert_story_upserts_with_publish_date_language_conflict_key` asserts the payload equals a specific dict — that dict does NOT include the new card columns. We need to update it.

- [ ] **Step 5: Update the existing payload-equality test**

In `tests/test_story_writer.py`, replace the body of `test_insert_story_upserts_with_publish_date_language_conflict_key` so the expected payload includes the new fields as None:

```python
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
        "threads_summary": "短摘",
        "hashtags": ["rome", "colosseum"],
        "card_title_ch": None,
        "card_title_sub_ch": None,
        "card_paragraphs_ch": None,
        "card_pull_quote_ch": None,
        "card_pull_quote_attrib_ch": None,
        "card_anno_roman": None,
    }
```

- [ ] **Step 6: Run writer tests again**

```bash
cd backend && uv run pytest tests/test_story_writer.py -v
```

Expected: all 4 tests pass.

- [ ] **Step 7: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/story_writer.py \
        backend/tests/test_story_writer.py
git commit -m "feat(writer): persist card_* fields with text[] paragraphs"
```

---

## Task 6: Wire `job.py` — zh-TW joins paragraphs into `story` and propagates card fields

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/job.py`
- Modify: `backend/tests/test_job.py`

- [ ] **Step 1: Write the failing test**

Append to `backend/tests/test_job.py`:

```python
@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_zh_tw_joins_paragraphs_and_passes_card_fields(
    mark_used, insert_story, generate_story, fetch_langlink,
    fetch_summary, pick_next, create_client, fake_config,
):
    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Eiffel Tower")
    fetch_summary.return_value = WikipediaSummary(
        title="Eiffel Tower",
        extract="Built 1889 by Gustave Eiffel.",
        image_url="https://upload.wikimedia.org/x.jpg",
        en_url="https://en.wikipedia.org/wiki/Eiffel_Tower",
    )
    fetch_langlink.side_effect = lambda title, lang: (
        f"https://{lang}.wikipedia.org/wiki/{title}"
    )
    generate_story.side_effect = [
        # zh-TW: paragraphs + card fields, story is None
        GeneratedStory(
            place_name="艾菲爾鐵塔",
            place_location="巴黎",
            era="十九世紀末",
            story=None,
            threads_summary="短摘",
            hashtags=("paris", "eiffelTower"),
            card_title_ch="討厭鐵塔的文學大師",
            card_title_sub_ch="莫泊桑的「專屬午餐位」",
            card_paragraphs_ch=("第一段", "第二段", "第三段"),
            card_pull_quote_ch="「看不見鐵塔的地方。」",
            card_pull_quote_attrib_ch="—— 莫泊桑，一八八九",
            card_anno_roman="MDCCCLXXXIX",
        ),
        # en: original shape
        GeneratedStory(
            place_name="Eiffel Tower",
            place_location="Paris",
            era="Late 19th century",
            story="english story",
            threads_summary="en short",
            hashtags=("paris",),
        ),
    ]

    run_once(fake_config, date(2026, 5, 21))

    # zh-TW row: schema is the zh-TW one, story is the joined paragraphs,
    # and all card fields are passed through.
    zh_call, en_call = insert_story.call_args_list
    zh_row = zh_call.args[1]
    assert zh_row.language == "zh-TW"
    assert zh_row.story == "第一段\n\n第二段\n\n第三段"
    assert zh_row.card_title_ch == "討厭鐵塔的文學大師"
    assert zh_row.card_paragraphs_ch == ("第一段", "第二段", "第三段")
    assert zh_row.card_anno_roman == "MDCCCLXXXIX"

    # en row: story unchanged, card fields all None
    en_row = en_call.args[1]
    assert en_row.language == "en"
    assert en_row.story == "english story"
    assert en_row.card_title_ch is None
    assert en_row.card_paragraphs_ch is None


@patch("lorescape_backend.daily_story.job.create_client")
@patch("lorescape_backend.daily_story.job.place_picker.pick_next_place")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_summary")
@patch("lorescape_backend.daily_story.job.wikipedia.fetch_langlink_url")
@patch("lorescape_backend.daily_story.job.gemini_client.generate_story")
@patch("lorescape_backend.daily_story.job.story_writer.insert_story")
@patch("lorescape_backend.daily_story.job.place_picker.mark_place_used")
def test_run_once_passes_per_language_response_schema(
    mark_used, insert_story, generate_story, fetch_langlink,
    fetch_summary, pick_next, create_client, fake_config,
):
    from lorescape_backend.daily_story import prompts

    pick_next.return_value = PickedPlace(id="p1", wikipedia_title_en="Colosseum")
    fetch_summary.return_value = WikipediaSummary(
        title="Colosseum", extract="...", image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )
    fetch_langlink.return_value = None
    generate_story.return_value = GeneratedStory(
        place_name="X", place_location="Y", era="Z",
        story="s", threads_summary="t", hashtags=(),
        card_paragraphs_ch=("a", "b", "c"),
    )

    run_once(fake_config, date(2026, 5, 21))

    # First call (zh-TW) gets the zh-TW schema; second call (en) gets en schema.
    zh_schema = generate_story.call_args_list[0].kwargs["response_schema"]
    en_schema = generate_story.call_args_list[1].kwargs["response_schema"]
    assert zh_schema == prompts.build_response_schema("zh-TW")
    assert en_schema == prompts.build_response_schema("en")
    # Sanity: they differ
    assert zh_schema != en_schema
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && uv run pytest tests/test_job.py::test_run_once_zh_tw_joins_paragraphs_and_passes_card_fields tests/test_job.py::test_run_once_passes_per_language_response_schema -v
```

Expected: both fail. The zh-TW test fails because `StoryRow` does not yet receive card fields from job.py (assertion on `zh_row.card_title_ch` returns None or `zh_row.story` is `None`/empty). The schema test fails because job currently calls `build_response_schema(language)` but might produce identical schemas — wait: after Task 3 the schemas DO differ, so this test actually passes only after Task 6 wires nothing new. Re-check: Task 2 already updated job.py to call `prompts.build_response_schema(language)`, so the schema test should pass even without Task 6 changes. Run it; if it passes, move on without changing job.py for that test.

- [ ] **Step 3: Update `job.py` zh-TW path**

In `backend/src/lorescape_backend/daily_story/job.py`, replace the body of the `for language in LANGUAGES:` loop (current lines 40-73) with:

```python
    for language in LANGUAGES:
        target_lang = language.split("-")[0]  # 'zh-TW' → 'zh', 'en' → 'en'
        wiki_url = (
            wikipedia.fetch_langlink_url(place.wikipedia_title_en, target_lang)
            or summary.en_url
        )

        story = gemini_client.generate_story(
            api_key=config.gemini_api_key,
            system_instruction=prompts.SYSTEM_INSTRUCTION,
            user_prompt=prompts.build_user_prompt(
                wikipedia_title=place.wikipedia_title_en,
                wikipedia_extract=summary.extract,
                language=language,
            ),
            response_schema=prompts.build_response_schema(language),
        )

        if story.card_paragraphs_ch is not None:
            # zh-TW path: derive the back-compat `story` column from paragraphs.
            story_text = "\n\n".join(story.card_paragraphs_ch)
        else:
            # en path: Gemini returns `story` directly.
            assert story.story is not None
            story_text = story.story

        story_writer.insert_story(
            supabase,
            story_writer.StoryRow(
                publish_date=target_date,
                language=language,
                place_id=place.id,
                place_name=story.place_name,
                place_location=story.place_location,
                era=story.era,
                story=story_text,
                image_url=summary.image_url,
                wikipedia_url=wiki_url,
                threads_summary=story.threads_summary,
                hashtags=story.hashtags,
                card_title_ch=story.card_title_ch,
                card_title_sub_ch=story.card_title_sub_ch,
                card_paragraphs_ch=story.card_paragraphs_ch,
                card_pull_quote_ch=story.card_pull_quote_ch,
                card_pull_quote_attrib_ch=story.card_pull_quote_attrib_ch,
                card_anno_roman=story.card_anno_roman,
            ),
        )

    place_picker.mark_place_used(supabase, place.id)
```

- [ ] **Step 4: Run job tests**

```bash
cd backend && uv run pytest tests/test_job.py -v
```

Expected: all pass. The existing tests (`test_run_once_happy_path_calls_each_step`, `test_run_once_falls_back_to_en_url_when_no_langlink`) pass because they pass `GeneratedStory` instances with `card_paragraphs_ch` defaulting to `None`, so the en branch is taken; `story_text` comes from `story.story` (a real string).

- [ ] **Step 5: Run full suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/job.py \
        backend/tests/test_job.py
git commit -m "feat(job): derive story from paragraphs in zh-TW path and pass card fields"
```

---

## Task 7: Manual backfill operations doc

**Files:**
- Create: `docs/operations/2026-05-21-backfill-card-fields-for-places.md`

- [ ] **Step 1: Check active places**

Run from repo root (just for awareness — the doc will instruct the operator to do this):

```bash
supabase db psql -c "select id, name, country, is_active, used_at from public.daily_story_places where is_active = true order by created_at;"
```

Capture output for the doc.

- [ ] **Step 2: Write the operations doc**

Create `docs/operations/2026-05-21-backfill-card-fields-for-places.md` with the following content (the outer fence below is 4 backticks so the SQL fences inside use the normal 3):

````markdown
# Backfill `daily_story_places` card fields (Phase 2)

The Phase 2 migration (`20260521120000_add_card_fields_to_daily_stories.sql`)
adds 5 nullable columns to `daily_story_places`:

- `card_location_en` — spine / footer display string, e.g. `TOUR EIFFEL · PARIS`
- `card_city_ch` — single Chinese character, e.g. `巴`
- `card_city_en` — uppercase city name, e.g. `PARIS`
- `latitude` — numeric, used to format `lat°N/S`
- `longitude` — numeric, used to format `lng°E/W`

New rows are filled in by the admin when adding a place. Existing rows must
be backfilled manually before the Phase 3 publisher can render IG cards for
them — rows missing any of the five values will be skipped at publish time
(Threads still posts).

## Run this in Supabase Dashboard → SQL Editor (prod)

List active places that still need backfill:

```sql
select id, name, country
from public.daily_story_places
where is_active = true
  and (card_location_en is null
    or card_city_ch is null
    or card_city_en is null
    or latitude is null
    or longitude is null)
order by created_at;
```

For each row, run an update like the Eiffel example below. Use Wikipedia /
GeoHack for lat/lng coordinates and the place's canonical city.

```sql
update public.daily_story_places
set card_location_en = 'TOUR EIFFEL · PARIS',
    card_city_ch     = '巴',
    card_city_en     = 'PARIS',
    latitude         =  48.8584,
    longitude        =   2.2945
where name = 'Eiffel Tower';
```

## Conventions

- `card_location_en`: ALL CAPS, format `<LANDMARK NAME> · <CITY>`. Use the
  middle dot `·` (U+00B7) as separator. Diacritics may be dropped if they
  would prevent the chosen IG card font from rendering correctly.
- `card_city_ch`: exactly one Traditional Chinese character. Pick the
  character most representative of the city (e.g. Paris → 巴, Tokyo → 東,
  Rome → 羅).
- `card_city_en`: city only (no country), ALL CAPS, ASCII where possible.
- `latitude` / `longitude`: decimal degrees, signed (north / east positive,
  south / west negative). 4 decimal places is the convention from the Eiffel
  demo (≈11 m accuracy).

## Verifying

After the update, re-run the listing query — expected output is empty (all
active rows have the five columns populated).
````

(The `````markdown` and `````` fences above exist only so this plan can show the file content with the inner ```` ```sql ```` blocks intact — the actual saved file uses normal triple-backtick fences with no backslash escapes.)

- [ ] **Step 3: Commit**

```bash
git add docs/operations/2026-05-21-backfill-card-fields-for-places.md
git commit -m "docs(ops): manual backfill guide for daily_story_places card fields"
```

---

## Final Verification

- [ ] **Step 1: Full backend test suite**

```bash
cd backend && uv run pytest -q
```

Expected: all green, no skips, no warnings about deprecated APIs introduced.

- [ ] **Step 2: Confirm migration applies on a clean DB**

```bash
supabase db reset
supabase db psql -c "select column_name, data_type from information_schema.columns where table_schema='public' and table_name in ('daily_stories','daily_story_places') and column_name like 'card_%' or column_name in ('latitude','longitude') order by table_name, column_name;"
```

Expected: rows for all 11 new columns, with `card_paragraphs_ch` showing `ARRAY` data type.

- [ ] **Step 3: Manual end-to-end smoke test (optional, requires real Gemini key)**

Pick one active zh-TW place via `daily_story.__main__`, run the job locally:

```bash
cd backend && uv run python -m lorescape_backend.daily_story 2026-05-22
```

Then in Supabase Dashboard, inspect the `daily_stories` row for `2026-05-22`, language `zh-TW`. Sanity-check:

- `card_title_ch` is a punchy ≤14-char title (not just the place name)
- `card_paragraphs_ch` has exactly 3 entries, each ~60-100 characters
- `card_pull_quote_ch` is wrapped in 「」 or 『』
- `card_pull_quote_attrib_ch` starts with `──`
- `card_anno_roman` is a Roman-numeral year string (uppercase ASCII)
- `story` equals `"\n\n".join(card_paragraphs_ch)`

If any field is off, refine the prompt in Task 3 and re-run. (Capture observations as a follow-up commit if needed — not a blocker for Phase 2 PR if the structure is correct and the content is "close enough".)

- [ ] **Step 4: Push & open PR**

```bash
git push -u origin feature/ig-card-phase2-schema-prompt
gh pr create --title "feat(card): Phase 2 — daily_stories schema + Gemini prompt for IG card" \
  --body "$(cat <<'EOF'
## Summary
- Add 5 static columns to `daily_story_places` (English spine, city char, city EN, lat/lng) and 6 card-content columns to `daily_stories` (title, subtitle, paragraphs, pull quote, attribution, Roman-numeral year).
- Make `prompts.py` language-aware: `build_response_schema(language)` + forked `_zh_tw_body`.
- Gemini's zh-TW path now returns `card_*` fields; writer joins `card_paragraphs_ch` to fill the existing `story` column (back-compat for app UI / Threads).
- `en` path is byte-for-byte unchanged.
- Manual backfill guide for the 5 `daily_story_places` columns added at `docs/operations/2026-05-21-backfill-card-fields-for-places.md`.

Spec: `docs/superpowers/specs/2026-05-21-ig-card-phase2-schema-prompt-design.md`

## Test plan
- [ ] `uv run pytest -q` passes
- [ ] `supabase db reset` applies cleanly
- [ ] Manual smoke: run `python -m lorescape_backend.daily_story <date>` against a real Gemini key; inspect the new zh-TW row in Supabase
EOF
)"
```

---

## Self-Review Notes

- **Spec coverage:** All schema columns from spec § "Schema 變更" → Task 1. `build_response_schema` + zh-TW prompt → Tasks 2–3. `GeneratedStory` + `StoryRow` extensions → Tasks 4–5. `job.py` rewiring + `story` derivation → Task 6. Manual backfill doc → Task 7. zh-TW `story` removal from required, paragraphs as text[], all card fields nullable — all covered.
- **Type consistency:** `card_paragraphs_ch` is `tuple[str, ...] | None` in Python dataclasses, `list` in JSON / DB payloads, `text[]` in SQL — conversion happens in `gemini_client.generate_story` (json list → tuple) and `story_writer.insert_story` (tuple → list). `story` is `str | None` in `GeneratedStory`, always `str` in `StoryRow` (`job.py` ensures one of the two branches fills it).
- **No placeholders:** No "TODO", "TBD", or "implement later" in any step. Every code step shows the full code; every test step shows the assertion code.
