# Daily Story Card Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote `daily_stories.card_*` fields from IG-card-only to the canonical content schema used by IG, App, and both languages; backfill old rows; render new card-style layouts in the Flutter App.

**Architecture:** One migration renames `_ch`-suffixed columns. The backend prompt schema is unified across languages (both produce `card_*` fields; `story` is always derived from `card_paragraphs.join`). A one-off Python script backfills old/NULL rows. The Flutter `DailyStory` model gains 9 nullable fields; detail screen and home preview each fork: `hasCardLayout` → new card-style body, else legacy body.

**Tech Stack:** Supabase (Postgres) migrations, Python 3.12 + pytest + `uv`, Google Gemini structured-output, Flutter 3 + Riverpod + `google_fonts`, `flutter_test` widget tests.

**Spec:** `docs/superpowers/specs/2026-05-25-daily-story-card-unification-design.md`

---

## File Structure

**New files:**
- `supabase/migrations/20260525000000_unify_card_fields.sql` — column rename migration
- `backend/scripts/backfill_card_fields.py` — one-off backfill script
- `backend/tests/test_backfill_card_fields.py` — backfill script tests
- `frontend/lib/features/daily_story/domain/models/daily_story_card_mode.dart` — `hasCardLayout` extension
- `frontend/lib/features/daily_story/presentation/widgets/card_layout_body.dart` — `_CardLayoutBody` widget (photo plate + text plate)
- `frontend/lib/features/daily_story/presentation/widgets/card_preview_card.dart` — `_CardPreviewCard` for home preview

**Modified backend files:**
- `backend/src/lorescape_backend/daily_story/prompts.py` — rename `_ZH_CARD_PROPERTIES` → `_CARD_PROPERTIES`, unify schema, add en card body
- `backend/src/lorescape_backend/daily_story/gemini_client.py` — `GeneratedStory` rename + drop `story` field
- `backend/src/lorescape_backend/daily_story/story_writer.py` — `StoryRow` rename + drop conditional
- `backend/src/lorescape_backend/daily_story/job.py` — drop zh-TW only branch
- `backend/src/lorescape_backend/social/card/mapper.py` — column reads renamed
- Corresponding tests in `backend/tests/`

**Modified frontend files:**
- `frontend/lib/features/daily_story/domain/models/daily_story.dart` — add 9 nullable fields
- `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart` — join `daily_story_places`; parse new fields
- `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart` — fork on `hasCardLayout`
- `frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart` — fork on `hasCardLayout`
- `frontend/test/fakes/in_memory_daily_story_repository.dart` — no behavior change but tests use new model
- Existing daily_story widget tests adapt to new model
- `frontend/pubspec.yaml` — add `google_fonts` (if absent)

---

## Task 1: Add migration to rename `_ch` columns

**Files:**
- Create: `supabase/migrations/20260525000000_unify_card_fields.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Unify card_* columns across languages. The `_ch` suffix was added when
-- card_* fields only existed on zh-TW rows. Each row is already keyed by
-- (publish_date, language), so the suffix is redundant — and confusing
-- once en rows also produce card_* content.
--
-- Companion changes:
--   - backend prompts.py / gemini_client.py / story_writer.py / job.py
--     and social/card/mapper.py all switch to the new column names in the
--     same release.
--   - Frontend DailyStory model gains the new fields and the App renders
--     a card-style layout when they are present (see spec).
--
-- daily_story_places.card_city_ch / card_city_en stay as-is — they store
-- two language names for the *same* place in a single row, so the suffix
-- is meaningful there.

alter table public.daily_stories
  rename column card_title_ch              to card_title;
alter table public.daily_stories
  rename column card_title_sub_ch          to card_title_sub;
alter table public.daily_stories
  rename column card_paragraphs_ch         to card_paragraphs;
alter table public.daily_stories
  rename column card_pull_quote_ch         to card_pull_quote;
alter table public.daily_stories
  rename column card_pull_quote_attrib_ch  to card_pull_quote_attrib;
-- card_anno_roman already has no _ch suffix; leave as-is.
```

- [ ] **Step 2: Apply migration locally**

Run: `cd supabase && supabase db reset` (or `supabase migration up` if reset is too destructive for local state).
Expected: migration applies cleanly; `\d daily_stories` in psql shows the new column names.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260525000000_unify_card_fields.sql
git commit -m "feat(db): rename daily_stories card_*_ch columns

drop the _ch suffix now that en rows will also carry card fields.
companion backend + app changes ship in the same release.
"
```

---

## Task 2: Update `GeneratedStory` dataclass

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/gemini_client.py`
- Test: `backend/tests/test_gemini_client.py`

- [ ] **Step 1: Update the failing test in `test_gemini_client.py`**

Look for the test asserting on `card_*_ch` field names and the test asserting `story` is populated. Update them to:

```python
def test_generate_story_parses_card_fields():
    fake_response = json.dumps({
        "place_name": "羅馬競技場",
        "place_location": "義大利羅馬",
        "era": "公元 70-80 年",
        "threads_summary": "短摘要...",
        "hashtags": ["history", "rome"],
        "card_title": "血腥的盛宴",
        "card_title_sub": "從石灰岩堆砌出的命運舞台",
        "card_paragraphs": ["段一...", "段二...", "段三..."],
        "card_pull_quote": "「他們將死之人向您致敬」",
        "card_pull_quote_attrib": "── 蘇埃托尼烏斯，西元 121 年",
        "card_anno_roman": "LXXX",
    })
    # ... existing fake client wiring that returns fake_response ...
    result = generate_story(
        api_key="k",
        system_instruction="s",
        user_prompt="u",
        response_schema={},
    )
    assert result.card_title == "血腥的盛宴"
    assert result.card_paragraphs == ("段一...", "段二...", "段三...")
    assert result.card_pull_quote_attrib.startswith("── ")
    assert not hasattr(result, "story")  # story field removed
```

(Adapt to whatever fake Gemini client pattern test_gemini_client.py already uses.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_gemini_client.py -v`
Expected: FAIL — `GeneratedStory` still has `_ch`-suffixed fields and `story` field.

- [ ] **Step 3: Update `GeneratedStory` in `gemini_client.py`**

Replace the dataclass and the parse return-statement:

```python
@dataclass(frozen=True)
class GeneratedStory:
    """Structured output from the Gemini story generation call.

    Both languages now produce card fields. The `story` text column is
    derived downstream by joining `card_paragraphs` with '\n\n'.
    """

    place_name: str
    place_location: str
    era: str
    threads_summary: str
    hashtags: tuple[str, ...]
    card_title: str
    card_title_sub: str
    card_paragraphs: tuple[str, ...]
    card_pull_quote: str
    card_pull_quote_attrib: str
    card_anno_roman: str
```

And the parse:

```python
data = json.loads(response.text)
return GeneratedStory(
    place_name=data["place_name"],
    place_location=data["place_location"],
    era=data["era"],
    threads_summary=data["threads_summary"],
    hashtags=tuple(data["hashtags"]),
    card_title=data["card_title"],
    card_title_sub=data["card_title_sub"],
    card_paragraphs=tuple(data["card_paragraphs"]),
    card_pull_quote=data["card_pull_quote"],
    card_pull_quote_attrib=data["card_pull_quote_attrib"],
    card_anno_roman=data["card_anno_roman"],
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_gemini_client.py -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/gemini_client.py backend/tests/test_gemini_client.py
git commit -m "feat(backend): unify GeneratedStory across languages

drop _ch suffix; remove standalone story field — both languages now
return card_paragraphs and downstream joins them into story.
"
```

---

## Task 3: Rename `_CARD_PROPERTIES` + unify base schema

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/prompts.py`
- Test: `backend/tests/test_prompts.py`

- [ ] **Step 1: Update `test_prompts.py` for the unified schema**

Replace the existing `ZH_CARD_FIELDS` block and the `test_build_response_schema_*` tests:

```python
CARD_FIELDS = {
    "card_title",
    "card_title_sub",
    "card_paragraphs",
    "card_pull_quote",
    "card_pull_quote_attrib",
    "card_anno_roman",
}

BASE_FIELDS = {
    "place_name", "place_location", "era",
    "threads_summary", "hashtags",
}


def test_build_response_schema_zh_tw_has_card_fields_and_no_story():
    schema = build_response_schema("zh-TW")
    required = set(schema["required"])
    assert CARD_FIELDS.issubset(required)
    assert BASE_FIELDS.issubset(required)
    assert "story" not in required
    assert "story" not in schema["properties"]


def test_build_response_schema_en_has_card_fields_and_no_story():
    schema = build_response_schema("en")
    required = set(schema["required"])
    assert CARD_FIELDS.issubset(required)
    assert BASE_FIELDS.issubset(required)
    assert "story" not in required
    assert "story" not in schema["properties"]


def test_build_response_schema_paragraphs_is_array_of_3_strings_both_langs():
    for lang in ("zh-TW", "en"):
        schema = build_response_schema(lang)
        paragraphs = schema["properties"]["card_paragraphs"]
        assert paragraphs["type"] == "ARRAY"
        assert paragraphs["items"]["type"] == "STRING"
        assert paragraphs.get("minItems") == 3
        assert paragraphs.get("maxItems") == 3


def test_build_user_prompt_zh_tw_lists_card_fields():
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
        language="zh-TW",
    )
    for field in CARD_FIELDS:
        assert field in prompt, f"zh-TW prompt missing field: {field}"
```

Delete the old `test_build_response_schema_en_unchanged` and
`test_build_user_prompt_en_does_not_mention_card_fields` tests entirely (en
now also carries card fields).

Keep `test_build_response_schema_raises_on_unknown_language` and
`test_build_user_prompt_includes_extract_and_language_name_zh_tw` as-is.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_prompts.py -v`
Expected: FAIL on schema structure assertions.

- [ ] **Step 3: Rewrite `prompts.py` schema section**

Replace `_BASE_PROPERTIES`, `_BASE_REQUIRED`, `_ZH_CARD_PROPERTIES`,
`_ZH_CARD_REQUIRED`, and `build_response_schema`:

```python
_BASE_PROPERTIES: dict = {
    "place_name": {"type": "STRING"},
    "place_location": {"type": "STRING"},
    "era": {"type": "STRING"},
    "threads_summary": {"type": "STRING"},
    "hashtags": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
    },
}

_BASE_REQUIRED = [
    "place_name", "place_location", "era",
    "threads_summary", "hashtags",
]

_CARD_PROPERTIES: dict = {
    "card_title":              {"type": "STRING"},
    "card_title_sub":          {"type": "STRING"},
    "card_paragraphs": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
    "card_pull_quote":         {"type": "STRING"},
    "card_pull_quote_attrib":  {"type": "STRING"},
    "card_anno_roman":         {"type": "STRING"},
}

_CARD_REQUIRED = [
    "card_title", "card_title_sub", "card_paragraphs",
    "card_pull_quote", "card_pull_quote_attrib", "card_anno_roman",
]


def build_response_schema(language: str) -> dict:
    """Return the Gemini structured-output schema for the given language.

    Both languages produce the base fields PLUS the card_* fields. The
    legacy `story` text column is derived by the writer from
    `card_paragraphs`.
    """
    if language not in _LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": {**_BASE_PROPERTIES, **_CARD_PROPERTIES},
        "required": _BASE_REQUIRED + _CARD_REQUIRED,
    }
```

- [ ] **Step 4: Run test to verify schema tests pass**

Run: `cd backend && uv run pytest tests/test_prompts.py -v`
Expected: schema tests PASS. Prompt body tests may still fail (next task) — that's OK for this commit.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/prompts.py backend/tests/test_prompts.py
git commit -m "feat(backend): unify card schema across zh-TW and en

both languages now produce card_* fields; story column dropped from
schema (derived from card_paragraphs at write time).
"
```

---

## Task 4: Rewrite en prompt body to produce card fields

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/prompts.py` (only `_en_body`)
- Test: `backend/tests/test_prompts.py`

- [ ] **Step 1: Update zh-TW prompt body to use new field names**

In `_zh_tw_body`, replace every `card_title_ch` → `card_title`, `card_title_sub_ch` → `card_title_sub`, `card_paragraphs_ch` → `card_paragraphs`, `card_pull_quote_ch` → `card_pull_quote`, `card_pull_quote_attrib_ch` → `card_pull_quote_attrib` (use Edit with replace_all = false on each, to avoid renaming markdown anchors).

- [ ] **Step 2: Write failing test for en card body**

Add to `test_prompts.py`:

```python
def test_build_user_prompt_en_lists_card_fields_and_drop_cap_rule():
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
        language="en",
    )
    for field in CARD_FIELDS:
        assert field in prompt, f"en prompt missing field: {field}"
    # 3 paragraphs constraint
    assert "3 paragraphs" in prompt
    # drop-cap function-word ban
    assert "drop-cap" in prompt.lower()
    assert '"The"' in prompt or "'The'" in prompt  # function-word example
    # pull quote uses double quotes
    assert '"..."' in prompt or "double quote" in prompt.lower()
    # em-dash for attribution
    assert "—" in prompt  # em-dash, not hyphen
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_prompts.py::test_build_user_prompt_en_lists_card_fields_and_drop_cap_rule -v`
Expected: FAIL — en prompt has no card field instructions.

- [ ] **Step 4: Rewrite `_en_body` in `prompts.py`**

Replace the entire `_en_body` function:

```python
def _en_body(language_name: str) -> str:
    return (
        f"Write a true historical short story in {language_name}, structured as "
        "exactly 3 paragraphs of 60-100 English words each.\n"
        "\n"
        "Style:\n"
        "- Each paragraph centres on a specific moment, person, or turning point.\n"
        "- Open paragraph 1 with a concrete scene — a dated event, a real person "
        "acting in a real place. The first word will be rendered as a large "
        "drop-cap; it must be a concrete noun or proper name, NOT a function "
        'word (avoid starting with "The", "A", "An", "In", "On", "At", "It", '
        '"This", "That").\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years or eras (e.g. '1492', '70-80 CE') and reference "
        "real named people from the source (rulers, architects, chroniclers).\n"
        "- Do NOT end with a redundant 'place name, location, era' summary — "
        "those values are returned as separate fields below.\n"
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
        "- card_title: a punchy English main title capturing the central "
        "tension (≤ 28 characters, must NOT just repeat the place name).\n"
        "- card_title_sub: a subtitle complementing the main title "
        "(≤ 50 characters).\n"
        "- card_paragraphs: the same 3 paragraphs above, returned as a JSON "
        "array of 3 strings (one paragraph per element, no leading/trailing "
        "whitespace).\n"
        "- card_pull_quote: one short, dramatic quote from the story, wrapped "
        'in straight double quotes "...". Prefer real quotes from the source '
        "over invented lines.\n"
        "- card_pull_quote_attrib: attribution for the pull quote, beginning "
        "with an em-dash —. Example: — Suetonius, 121 CE.\n"
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
        "- card_title, card_title_sub, card_paragraphs, card_pull_quote, "
        "card_pull_quote_attrib, card_anno_roman: as described above\n"
    )
```

- [ ] **Step 5: Run all prompt tests**

Run: `cd backend && uv run pytest tests/test_prompts.py -v`
Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/prompts.py backend/tests/test_prompts.py
git commit -m "feat(backend): rewrite en prompt body to produce card fields

mirrors zh-TW: 3 paragraphs, drop-cap rule (with function-word ban),
pull quote, em-dash attribution, Roman year. enables IG-card-style
rendering on en rows once the App is updated.
"
```

---

## Task 5: Update `StoryRow` and `story_writer`

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/story_writer.py`
- Test: `backend/tests/test_story_writer.py`

- [ ] **Step 1: Update `test_story_writer.py`**

Search-and-replace inside `tests/test_story_writer.py`:
- `card_title_ch` → `card_title`
- `card_title_sub_ch` → `card_title_sub`
- `card_paragraphs_ch` → `card_paragraphs`
- `card_pull_quote_ch` → `card_pull_quote`
- `card_pull_quote_attrib_ch` → `card_pull_quote_attrib`

Also: any test that constructs a `StoryRow` with card fields as `None` (the en path) should now set them to real values like `card_title="主標"`, `card_paragraphs=("p1", "p2", "p3")`, etc., since both languages carry card fields.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_story_writer.py -v`
Expected: FAIL — `StoryRow` still has `_ch`-suffixed fields and optional/None defaults.

- [ ] **Step 3: Rewrite `StoryRow` and `insert_story`**

Replace `story_writer.py` contents:

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
    # IG card fields — populated on every row (both zh-TW and en).
    card_title: str = ""
    card_title_sub: str = ""
    card_paragraphs: tuple[str, ...] = field(default_factory=tuple)
    card_pull_quote: str = ""
    card_pull_quote_attrib: str = ""
    card_anno_roman: str = ""


def insert_story(supabase, row: StoryRow) -> None:
    """Upsert a row into daily_stories (idempotent on (publish_date, language)).

    The new social-publishing columns (discord_message_id, review_state, etc.)
    are written separately by the discord_review and publisher modules — this
    function only writes the story content itself.
    """
    payload = asdict(row)
    payload["publish_date"] = row.publish_date.isoformat()
    # asdict leaves tuple-typed fields as tuples, but the Supabase JSON
    # serializer needs lists for text[] / jsonb columns.
    payload["hashtags"] = list(row.hashtags)
    payload["card_paragraphs"] = list(row.card_paragraphs)
    (
        supabase.table("daily_stories")
        .upsert(payload, on_conflict="publish_date,language")
        .execute()
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_story_writer.py -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/story_writer.py backend/tests/test_story_writer.py
git commit -m "feat(backend): unify StoryRow card fields across languages

drop _ch suffix; payload always includes card_paragraphs (no longer
conditional on language).
"
```

---

## Task 6: Unify `job.py` story-text derivation across languages

**Files:**
- Modify: `backend/src/lorescape_backend/daily_story/job.py` (lines 47-87)
- Test: `backend/tests/test_job.py`

- [ ] **Step 1: Update `test_job.py`**

Search-and-replace inside `tests/test_job.py`:
- `card_title_ch` → `card_title`
- `card_title_sub_ch` → `card_title_sub`
- `card_paragraphs_ch` → `card_paragraphs`
- `card_pull_quote_ch` → `card_pull_quote`
- `card_pull_quote_attrib_ch` → `card_pull_quote_attrib`

Add a test ensuring en path also calls `insert_story` with non-empty
`card_paragraphs`:

```python
def test_run_once_en_path_writes_card_paragraphs(monkeypatch):
    # ... existing fixture setup that fakes gemini + supabase ...
    # The fake generate_story should return a GeneratedStory with
    # card_paragraphs=("p1", "p2", "p3") for BOTH zh-TW and en.
    # ... call run_once ...
    en_call = next(c for c in inserted_rows if c.language == "en")
    assert en_call.card_paragraphs == ("p1", "p2", "p3")
    assert en_call.story == "p1\n\np2\n\np3"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_job.py -v`
Expected: FAIL — `job.py` still references `card_paragraphs_ch` and branches on language.

- [ ] **Step 3: Simplify `job.py` story-text derivation**

In `job.py` replace lines 58-86 (the `if story.card_paragraphs_ch is not
None:` block and the entire `insert_story` call) with:

```python
        story_text = "\n\n".join(story.card_paragraphs)

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
                card_title=story.card_title,
                card_title_sub=story.card_title_sub,
                card_paragraphs=story.card_paragraphs,
                card_pull_quote=story.card_pull_quote,
                card_pull_quote_attrib=story.card_pull_quote_attrib,
                card_anno_roman=story.card_anno_roman,
            ),
        )
```

(Note: no conditional, no `assert story.story is not None`.)

- [ ] **Step 4: Run all backend tests**

Run: `cd backend && uv run pytest -v`
Expected: ALL PASS (job + dependencies).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/daily_story/job.py backend/tests/test_job.py
git commit -m "feat(backend): unify daily story job across languages

drop zh-TW-only branch; story column is always joined from
card_paragraphs.
"
```

---

## Task 7: Rename column reads in IG card mapper

**Files:**
- Modify: `backend/src/lorescape_backend/social/card/mapper.py` (lines 26-30)
- Test: `backend/tests/test_card_mapper.py`

- [ ] **Step 1: Update `test_card_mapper.py`**

Search-and-replace inside that file:
- `"card_title_ch"` → `"card_title"`
- `"card_title_sub_ch"` → `"card_title_sub"`
- `"card_paragraphs_ch"` → `"card_paragraphs"`
- `"card_pull_quote_ch"` → `"card_pull_quote"`
- `"card_pull_quote_attrib_ch"` → `"card_pull_quote_attrib"`

(Also any local variable named `title_ch` / `paragraphs_ch` if the
test creates dicts using those keys — keep the variable name local,
just change the dict key.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_card_mapper.py -v`
Expected: FAIL — mapper still reads `_ch` keys from the dict.

- [ ] **Step 3: Update `mapper.py` column reads**

Edit lines 26-30 of `mapper.py`:

```python
    title_ch = daily_story_row.get("card_title")
    title_ch_sub = daily_story_row.get("card_title_sub")
    paragraphs = daily_story_row.get("card_paragraphs")
    pull_quote_ch = daily_story_row.get("card_pull_quote")
    pull_quote_attrib_ch = daily_story_row.get("card_pull_quote_attrib")
```

(Variable names — `title_ch`, `pull_quote_ch`, etc. — stay the same; the
`CardContent` and Jinja template still expect those local names for the
zh-TW IG card. Only the *dict key* changes.)

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_card_mapper.py tests/test_publisher.py -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/card/mapper.py backend/tests/test_card_mapper.py
git commit -m "fix(card): read renamed daily_stories columns

mapper still scopes to zh-TW rows in the publisher; IG card output
unchanged.
"
```

---

## Task 8: Write the backfill script

**Files:**
- Create: `backend/scripts/backfill_card_fields.py`
- Create: `backend/tests/test_backfill_card_fields.py`

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_backfill_card_fields.py`:

```python
"""Tests for the one-off backfill script."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import pytest

from scripts import backfill_card_fields


@dataclass
class _FakeStoryRow:
    id: str
    language: str
    place_id: str
    card_paragraphs: list[str] | None


@dataclass
class _FakePlaceRow:
    id: str
    wikipedia_title_en: str


class _FakeSupabase:
    def __init__(self, story_rows: list[dict], place_rows: list[dict]):
        self.story_rows = story_rows
        self.place_rows = place_rows
        self.updates: list[tuple[str, dict]] = []

    def table(self, name: str):
        return _FakeTable(self, name)


class _FakeTable:
    def __init__(self, db: _FakeSupabase, name: str):
        self.db = db
        self.name = name
        self._filters: dict[str, Any] = {}
        self._select_called = False
        self._update_payload: dict | None = None

    def select(self, *_args, **_kwargs):
        self._select_called = True
        return self

    def is_(self, col: str, val):
        self._filters[col] = ("is", val)
        return self

    def eq(self, col: str, val):
        self._filters[col] = ("eq", val)
        return self

    def update(self, payload: dict):
        self._update_payload = payload
        return self

    def execute(self):
        if self._update_payload is not None:
            row_id = self._filters["id"][1]
            self.db.updates.append((row_id, self._update_payload))
            return _Result(data=[{"id": row_id}])
        if self.name == "daily_stories":
            rows = [r for r in self.db.story_rows if r["card_paragraphs"] is None]
            return _Result(data=rows)
        if self.name == "daily_story_places":
            target_id = self._filters["id"][1]
            rows = [r for r in self.db.place_rows if r["id"] == target_id]
            return _Result(data=rows)
        return _Result(data=[])


@dataclass
class _Result:
    data: list[dict]


def _fake_generate_story(**_kwargs):
    from lorescape_backend.daily_story.gemini_client import GeneratedStory
    return GeneratedStory(
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        threads_summary="短摘要",
        hashtags=("history",),
        card_title="血腥的盛宴",
        card_title_sub="從石灰岩堆砌的命運舞台",
        card_paragraphs=("段一", "段二", "段三"),
        card_pull_quote="「他們將死之人向您致敬」",
        card_pull_quote_attrib="── 蘇埃托尼烏斯，西元 121 年",
        card_anno_roman="LXXX",
    )


def _fake_fetch_summary(_title: str):
    from lorescape_backend.daily_story.wikipedia import WikipediaSummary
    return WikipediaSummary(
        title="Colosseum",
        extract="Built in 70-80 CE by Vespasian.",
        image_url=None,
        en_url="https://en.wikipedia.org/wiki/Colosseum",
    )


@pytest.fixture
def fake_db():
    return _FakeSupabase(
        story_rows=[
            {"id": "r1", "language": "zh-TW", "place_id": "p1", "card_paragraphs": None},
            {"id": "r2", "language": "en",    "place_id": "p1", "card_paragraphs": None},
            {"id": "r3", "language": "zh-TW", "place_id": "p1", "card_paragraphs": ["a", "b", "c"]},
        ],
        place_rows=[{"id": "p1", "wikipedia_title_en": "Colosseum"}],
    )


def test_run_backfills_only_null_rows(monkeypatch, fake_db):
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _fake_generate_story)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=False)

    assert result.processed == 2
    assert result.failed == 0
    updated_ids = {row_id for row_id, _ in fake_db.updates}
    assert updated_ids == {"r1", "r2"}


def test_run_writes_joined_story_and_all_card_fields(monkeypatch, fake_db):
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _fake_generate_story)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    backfill_card_fields.run(fake_db, dry_run=False)

    _, payload = fake_db.updates[0]
    assert payload["card_paragraphs"] == ["段一", "段二", "段三"]
    assert payload["story"] == "段一\n\n段二\n\n段三"
    assert payload["card_title"] == "血腥的盛宴"
    assert payload["card_anno_roman"] == "LXXX"
    assert payload["place_name"] == "羅馬競技場"


def test_dry_run_does_not_call_gemini_or_write(monkeypatch, fake_db):
    called = []
    def _spy(**kwargs):
        called.append(kwargs)
        return _fake_generate_story(**kwargs)
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _spy)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=True)

    assert result.processed == 2  # would-process count
    assert called == []
    assert fake_db.updates == []


def test_single_row_failure_does_not_stop_run(monkeypatch, fake_db):
    call_count = {"n": 0}
    def _flaky(**kwargs):
        call_count["n"] += 1
        if call_count["n"] == 1:
            raise RuntimeError("simulated Gemini failure")
        return _fake_generate_story(**kwargs)
    monkeypatch.setattr(backfill_card_fields, "_generate_story", _flaky)
    monkeypatch.setattr(backfill_card_fields, "_fetch_summary", _fake_fetch_summary)

    result = backfill_card_fields.run(fake_db, dry_run=False)

    assert result.processed == 1
    assert result.failed == 1
    assert len(fake_db.updates) == 1
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && uv run pytest tests/test_backfill_card_fields.py -v`
Expected: FAIL — `scripts.backfill_card_fields` does not exist.

- [ ] **Step 3: Write the backfill script**

Create `backend/scripts/backfill_card_fields.py`:

```python
"""One-off backfill: regenerate card_* fields for rows where they are NULL.

Covers:
- All en rows (never had card_* fields).
- Pre-20260521 zh-TW rows (card_paragraphs_ch column did not exist yet).

For each NULL row:
  1. Look up the place's English Wikipedia title.
  2. Re-fetch the Wikipedia extract.
  3. Call Gemini in the row's language to produce card_* fields.
  4. UPDATE the row with all card_* fields PLUS:
     - story  = "\n\n".join(card_paragraphs)
     - place_name / place_location / era (same Gemini output)

Idempotent: re-running picks up only rows with card_paragraphs IS NULL.

Place-level fields on `daily_story_places` (card_location_en,
card_city_ch, card_city_en, latitude, longitude) are admin-curated and
NOT touched by this script. After running, the operator should fill any
NULLs via the Supabase Dashboard.

Usage:
    cd backend
    uv run python -m scripts.backfill_card_fields --dry-run   # estimate
    uv run python -m scripts.backfill_card_fields             # real run
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from dataclasses import dataclass

from supabase import create_client

from lorescape_backend.daily_story import gemini_client, prompts, wikipedia

logger = logging.getLogger(__name__)


@dataclass
class BackfillResult:
    processed: int
    failed: int
    errors: list[str]


# Indirection seams so tests can monkeypatch.
def _generate_story(**kwargs):
    return gemini_client.generate_story(**kwargs)


def _fetch_summary(title: str):
    return wikipedia.fetch_summary(title)


def run(supabase, *, dry_run: bool, gemini_api_key: str = "") -> BackfillResult:
    """Run the backfill once. Returns a result summary; never raises mid-run."""
    null_rows = (
        supabase.table("daily_stories")
        .select("id, language, place_id")
        .is_("card_paragraphs", None)
        .execute()
        .data
        or []
    )

    if dry_run:
        logger.info("[dry-run] would process %d rows", len(null_rows))
        return BackfillResult(processed=len(null_rows), failed=0, errors=[])

    processed = 0
    errors: list[str] = []

    for idx, row in enumerate(null_rows, start=1):
        row_id = row["id"]
        language = row["language"]
        place_id = row["place_id"]
        try:
            place_rows = (
                supabase.table("daily_story_places")
                .select("wikipedia_title_en")
                .eq("id", place_id)
                .execute()
                .data
                or []
            )
            if not place_rows:
                raise RuntimeError(f"place {place_id} not found")
            wiki_title = place_rows[0]["wikipedia_title_en"]

            summary = _fetch_summary(wiki_title)
            story = _generate_story(
                api_key=gemini_api_key,
                system_instruction=prompts.SYSTEM_INSTRUCTION,
                user_prompt=prompts.build_user_prompt(
                    wikipedia_title=wiki_title,
                    wikipedia_extract=summary.extract,
                    language=language,
                ),
                response_schema=prompts.build_response_schema(language),
            )

            payload = {
                "card_title": story.card_title,
                "card_title_sub": story.card_title_sub,
                "card_paragraphs": list(story.card_paragraphs),
                "card_pull_quote": story.card_pull_quote,
                "card_pull_quote_attrib": story.card_pull_quote_attrib,
                "card_anno_roman": story.card_anno_roman,
                "story": "\n\n".join(story.card_paragraphs),
                "place_name": story.place_name,
                "place_location": story.place_location,
                "era": story.era,
            }
            supabase.table("daily_stories").update(payload).eq("id", row_id).execute()

            processed += 1
            logger.info(
                "[%d/%d] %s %s OK", idx, len(null_rows), language, row_id
            )
        except Exception as exc:  # noqa: BLE001
            msg = f"row {row_id} ({language}): {exc}"
            errors.append(msg)
            logger.warning("[%d/%d] FAIL %s", idx, len(null_rows), msg)

    return BackfillResult(
        processed=processed, failed=len(errors), errors=errors
    )


def _main() -> int:
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
    )
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    url = os.environ["SUPABASE_URL"]
    service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    gemini_key = "" if args.dry_run else os.environ["GEMINI_API_KEY"]

    supabase = create_client(url, service_key)
    result = run(supabase, dry_run=args.dry_run, gemini_api_key=gemini_key)

    logger.info(
        "summary: processed=%d failed=%d", result.processed, result.failed
    )
    for err in result.errors:
        logger.error("  %s", err)

    logger.info(
        "reminder: backfill does not touch daily_story_places.card_location_en"
        " / card_city_* / latitude / longitude — fill manually via Supabase"
        " Dashboard for any new places."
    )
    return 0 if result.failed == 0 else 1


if __name__ == "__main__":
    sys.exit(_main())
```

- [ ] **Step 4: Add `__init__.py` so `scripts` is importable**

If `backend/scripts/__init__.py` does not exist, create it as an empty file:

```python
```

(Run `ls backend/scripts/` first to check.)

- [ ] **Step 5: Run test to verify it passes**

Run: `cd backend && uv run pytest tests/test_backfill_card_fields.py -v`
Expected: PASS (all 4 tests).

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/backfill_card_fields.py backend/scripts/__init__.py backend/tests/test_backfill_card_fields.py
git commit -m "feat(backend): add one-off backfill script for card_* fields

regenerates card_* + joined story for every row where card_paragraphs
is null. idempotent, dry-run flag, single-row failures isolated.
"
```

---

## Task 9: Add card fields to `DailyStory` model

**Files:**
- Modify: `frontend/lib/features/daily_story/domain/models/daily_story.dart`
- Test: existing tests that construct `DailyStory` (compile-only — no behavioral test here; widget tests will exercise this)

- [ ] **Step 1: Add the new fields to the model**

Replace `frontend/lib/features/daily_story/domain/models/daily_story.dart`:

```dart
import 'package:equatable/equatable.dart';

/// A daily-place story shown to the user once per day in their app language.
///
/// Mirrors a row in Supabase `public.daily_stories` joined with the matching
/// `daily_story_places` row. One day has one `DailyStory` per supported
/// language (zh-TW, en).
class DailyStory extends Equatable {
  final DateTime publishDate;
  final String language;
  final String placeName;
  final String placeLocation;
  final String era;

  /// Legacy plain-text body, joined from [cardParagraphs] when card fields
  /// are present. Kept as a fallback for old App versions and as the body
  /// the legacy layout renders when [cardParagraphs] is null.
  final String story;

  final String? imageUrl;
  final String wikipediaUrl;

  // Card content fields (story-level). All nullable so the App can fall
  // back to the legacy layout when any of cardTitle / cardTitleSub /
  // cardParagraphs is missing.
  final String? cardTitle;
  final String? cardTitleSub;
  final List<String>? cardParagraphs;
  final String? cardPullQuote;
  final String? cardPullQuoteAttrib;
  final String? cardAnnoRoman;

  // Card location fields (place-level, joined from daily_story_places).
  // Decorative — the card layout renders without them if null.
  final String? cardLocationEn;
  final String? cardCityCh;
  final String? cardCityEn;

  const DailyStory({
    required this.publishDate,
    required this.language,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    required this.story,
    required this.imageUrl,
    required this.wikipediaUrl,
    this.cardTitle,
    this.cardTitleSub,
    this.cardParagraphs,
    this.cardPullQuote,
    this.cardPullQuoteAttrib,
    this.cardAnnoRoman,
    this.cardLocationEn,
    this.cardCityCh,
    this.cardCityEn,
  });

  @override
  List<Object?> get props => [
    publishDate,
    language,
    placeName,
    placeLocation,
    era,
    story,
    imageUrl,
    wikipediaUrl,
    cardTitle,
    cardTitleSub,
    cardParagraphs,
    cardPullQuote,
    cardPullQuoteAttrib,
    cardAnnoRoman,
    cardLocationEn,
    cardCityCh,
    cardCityEn,
  ];
}
```

- [ ] **Step 2: Verify compile**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: PASS. No errors (all new fields are nullable with named-arg defaults, so existing callers compile).

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/daily_story/domain/models/daily_story.dart
git commit -m "feat(daily_story): add nullable card_* fields to DailyStory

backwards compatible: new fields default null so existing constructors
keep compiling. App rendering will fork on cardTitle/Sub/Paragraphs
presence in a later commit.
"
```

---

## Task 10: Update Supabase repository to fetch new fields

**Files:**
- Modify: `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart`
- Test: create `frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart` (if absent)

- [ ] **Step 1: Add a test that exercises `_fromRow` with card fields**

Create `frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart`:

```dart
import 'package:context_app/features/daily_story/data/supabase_daily_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// `_fromRow` is private; the test exercises it indirectly by exposing a
// thin wrapper. If that proves awkward, change `_fromRow` to a public
// helper (e.g. `static DailyStory rowToStory(Map row)`) and call it.

void main() {
  group('SupabaseDailyStoryRepository.rowToStory', () {
    test(
      'given a row with all card fields and joined place fields, '
      'when parsed, '
      'then DailyStory carries every value',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'zh-TW',
          'place_name': '羅馬競技場',
          'place_location': '義大利羅馬',
          'era': '公元 70-80 年',
          'story': 'p1\n\np2\n\np3',
          'image_url': null,
          'wikipedia_url': 'https://zh.wikipedia.org/wiki/Colosseum',
          'card_title': '血腥的盛宴',
          'card_title_sub': '從石灰岩堆砌的命運舞台',
          'card_paragraphs': ['p1', 'p2', 'p3'],
          'card_pull_quote': '「他們將死之人向您致敬」',
          'card_pull_quote_attrib': '── 蘇埃托尼烏斯，西元 121 年',
          'card_anno_roman': 'LXXX',
          'daily_story_places': {
            'card_location_en': 'COLOSSEUM',
            'card_city_ch': '羅馬',
            'card_city_en': 'Rome',
          },
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardTitle, '血腥的盛宴');
        expect(story.cardParagraphs, ['p1', 'p2', 'p3']);
        expect(story.cardLocationEn, 'COLOSSEUM');
        expect(story.cardCityCh, '羅馬');
        expect(story.cardCityEn, 'Rome');
      },
    );

    test(
      'given a row missing card fields and place join, '
      'when parsed, '
      'then card_* fields are null',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'en',
          'place_name': 'Colosseum',
          'place_location': 'Rome, Italy',
          'era': '70-80 CE',
          'story': 'A plain text story.',
          'image_url': 'https://example.com/img.jpg',
          'wikipedia_url': 'https://en.wikipedia.org/wiki/Colosseum',
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardTitle, isNull);
        expect(story.cardParagraphs, isNull);
        expect(story.cardLocationEn, isNull);
      },
    );

    test(
      'given a place join with some null city fields, '
      'when parsed, '
      'then nulls propagate without crashing',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'zh-TW',
          'place_name': '羅馬競技場',
          'place_location': '義大利羅馬',
          'era': '公元 70-80 年',
          'story': 'x',
          'image_url': null,
          'wikipedia_url': 'https://zh.wikipedia.org/wiki/Colosseum',
          'daily_story_places': {
            'card_location_en': null,
            'card_city_ch': '羅馬',
            'card_city_en': null,
          },
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardLocationEn, isNull);
        expect(story.cardCityCh, '羅馬');
        expect(story.cardCityEn, isNull);
      },
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart`
Expected: FAIL — `rowToStory` does not exist (it's currently private `_fromRow`).

- [ ] **Step 3: Update repository to join + parse new fields**

Rewrite `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart`:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDailyStoryRepository implements DailyStoryRepository {
  final SupabaseClient _client;

  SupabaseDailyStoryRepository(this._client);

  static const _table = 'daily_stories';
  // Pull the daily_story_places row alongside each story so the App can
  // render card spine / footer fields without a second round-trip.
  // `!left` so we still get the story row even if the place join is empty.
  static const _select =
      '*, daily_story_places!left(card_location_en, card_city_ch, card_city_en)';

  @override
  Future<DailyStory?> fetchLatest({required String language}) async {
    final rows = await _client
        .from(_table)
        .select(_select)
        .eq('language', language)
        .order('publish_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return rowToStory(rows.first);
  }

  @override
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from(_table)
        .select(_select)
        .eq('language', language)
        .lt('publish_date', _isoDate(before))
        .order('publish_date', ascending: false)
        .limit(limit);
    return rows.map(rowToStory).toList();
  }

  /// Public for testability. Parses a single row (possibly with the
  /// `daily_story_places` join expanded) into a [DailyStory].
  static DailyStory rowToStory(Map<String, dynamic> row) {
    final place = row['daily_story_places'] as Map<String, dynamic>?;
    final paragraphsRaw = row['card_paragraphs'];
    return DailyStory(
      publishDate: DateTime.parse(row['publish_date'] as String),
      language: row['language'] as String,
      placeName: row['place_name'] as String,
      placeLocation: row['place_location'] as String,
      era: row['era'] as String,
      story: row['story'] as String,
      imageUrl: row['image_url'] as String?,
      wikipediaUrl: row['wikipedia_url'] as String,
      cardTitle: row['card_title'] as String?,
      cardTitleSub: row['card_title_sub'] as String?,
      cardParagraphs: paragraphsRaw == null
          ? null
          : (paragraphsRaw as List).cast<String>(),
      cardPullQuote: row['card_pull_quote'] as String?,
      cardPullQuoteAttrib: row['card_pull_quote_attrib'] as String?,
      cardAnnoRoman: row['card_anno_roman'] as String?,
      cardLocationEn: place?['card_location_en'] as String?,
      cardCityCh: place?['card_city_ch'] as String?,
      cardCityEn: place?['card_city_en'] as String?,
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Run analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart
git commit -m "feat(daily_story): fetch card_* fields + join daily_story_places

repository now selects the renamed columns and joins the place row so
the App can render spine / footer without a second query.
"
```

---

## Task 11: Add `hasCardLayout` extension

**Files:**
- Create: `frontend/lib/features/daily_story/domain/models/daily_story_card_mode.dart`
- Test: `frontend/test/features/daily_story/domain/models/daily_story_card_mode_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/daily_story/domain/models/daily_story_card_mode_test.dart`:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story_card_mode.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _baseStory({
  String? cardTitle,
  String? cardTitleSub,
  List<String>? cardParagraphs,
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 25),
    language: 'zh-TW',
    placeName: '羅馬競技場',
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: 'p1\n\np2\n\np3',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
    cardTitle: cardTitle,
    cardTitleSub: cardTitleSub,
    cardParagraphs: cardParagraphs,
  );
}

void main() {
  group('DailyStory.hasCardLayout', () {
    test('returns true when title, sub, and 3 paragraphs are all present', () {
      final story = _baseStory(
        cardTitle: '血腥的盛宴',
        cardTitleSub: '副標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isTrue);
    });

    test('returns false when cardTitle is null', () {
      final story = _baseStory(
        cardTitleSub: '副標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardTitleSub is null', () {
      final story = _baseStory(
        cardTitle: '主標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardParagraphs is null', () {
      final story = _baseStory(cardTitle: '主標', cardTitleSub: '副標');
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardParagraphs has the wrong length', () {
      final story = _baseStory(
        cardTitle: '主標',
        cardTitleSub: '副標',
        cardParagraphs: ['only one'],
      );
      expect(story.hasCardLayout, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/domain/models/daily_story_card_mode_test.dart`
Expected: FAIL — `daily_story_card_mode.dart` does not exist.

- [ ] **Step 3: Write the extension**

Create `frontend/lib/features/daily_story/domain/models/daily_story_card_mode.dart`:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

/// True when the row has the three story-core card fields needed to render
/// the new IG-style layout. Decorative fields (pull quote, Roman year,
/// place-level spine / footer) are NOT part of this check — they degrade
/// individually inside the card layout.
extension DailyStoryCardMode on DailyStory {
  bool get hasCardLayout =>
      cardTitle != null &&
      cardTitleSub != null &&
      cardParagraphs != null &&
      cardParagraphs!.length == 3;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/domain/models/daily_story_card_mode_test.dart`
Expected: PASS (all 5 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/daily_story/domain/models/daily_story_card_mode.dart frontend/test/features/daily_story/domain/models/daily_story_card_mode_test.dart
git commit -m "feat(daily_story): add hasCardLayout extension

guards the new card layout on the three story-core fields. used by the
detail screen and home preview to fork between card and legacy bodies.
"
```

---

## Task 12: Ensure `google_fonts` is in pubspec

**Files:**
- Modify: `frontend/pubspec.yaml` (if absent)

- [ ] **Step 1: Check if `google_fonts` is already a dependency**

Run: `grep -n google_fonts frontend/pubspec.yaml`
- If a line appears, SKIP the rest of this task.
- If empty, proceed.

- [ ] **Step 2: Add `google_fonts`**

Run: `cd frontend && fvm flutter pub add google_fonts`
Expected: pubspec.yaml gets `google_fonts: ^6.x.x` (latest); pubspec.lock updates.

- [ ] **Step 3: Verify it resolves**

Run: `cd frontend && fvm flutter pub get`
Expected: no error.

- [ ] **Step 4: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "chore(deps): add google_fonts for Noto Serif TC

used by the new daily story card layout to match the IG card brand
typography.
"
```

---

## Task 13: Build `_CardLayoutBody` widget (photo plate + text plate)

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/widgets/card_layout_body.dart`
- Test: `frontend/test/features/daily_story/presentation/widgets/card_layout_body_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `frontend/test/features/daily_story/presentation/widgets/card_layout_body_test.dart`:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_layout_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _fullCardStory({
  String? cardLocationEn = 'COLOSSEUM',
  String? cardCityCh = '羅馬',
  String? cardCityEn = 'Rome',
  String? cardPullQuote = '「他們將死之人向您致敬」',
  String? cardAnnoRoman = 'LXXX',
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 25),
    language: 'zh-TW',
    placeName: '羅馬競技場',
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: 'p1\n\np2\n\np3',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
    cardTitle: '血腥的盛宴',
    cardTitleSub: '從石灰岩堆砌的命運舞台',
    cardParagraphs: const [
      '維斯帕先在西元七十年下令...',
      '工匠們夜以繼日地堆砌...',
      '今日的競技場斷垣殘壁...',
    ],
    cardPullQuote: cardPullQuote,
    cardPullQuoteAttrib: '── 蘇埃托尼烏斯，西元 121 年',
    cardAnnoRoman: cardAnnoRoman,
    cardLocationEn: cardLocationEn,
    cardCityCh: cardCityCh,
    cardCityEn: cardCityEn,
  );
}

Future<void> _pump(WidgetTester tester, DailyStory story) async {
  await pumpApp(
    tester,
    Scaffold(body: CardLayoutBody(story: story)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('CardLayoutBody', () {
    testWidgets(
      'given full card data, '
      'when rendered, '
      'then title, subtitle, all paragraphs, pull quote, and anno roman are visible',
      (tester) async {
        await _pump(tester, _fullCardStory());

        expect(find.text('血腥的盛宴'), findsOneWidget);
        expect(find.text('從石灰岩堆砌的命運舞台'), findsOneWidget);
        expect(find.textContaining('維斯帕先在西元七十年'), findsOneWidget);
        expect(find.textContaining('工匠們夜以繼日'), findsOneWidget);
        expect(find.textContaining('今日的競技場'), findsOneWidget);
        expect(find.text('「他們將死之人向您致敬」'), findsOneWidget);
        expect(find.text('── 蘇埃托尼烏斯，西元 121 年'), findsOneWidget);
        expect(find.textContaining('LXXX'), findsOneWidget);
        expect(find.textContaining('COLOSSEUM'), findsOneWidget);
      },
    );

    testWidgets(
      'given pull quote is null, '
      'when rendered, '
      'then no quote block appears',
      (tester) async {
        await _pump(tester, _fullCardStory(cardPullQuote: null));
        expect(find.textContaining('將死之人'), findsNothing);
        expect(find.textContaining('蘇埃托尼烏斯'), findsNothing);
      },
    );

    testWidgets(
      'given cardLocationEn is null, '
      'when rendered, '
      'then the spine is omitted',
      (tester) async {
        await _pump(tester, _fullCardStory(cardLocationEn: null));
        expect(find.text('COLOSSEUM'), findsNothing);
      },
    );

    testWidgets(
      'given cardAnnoRoman is null, '
      'when rendered, '
      'then the Anno block is omitted',
      (tester) async {
        await _pump(tester, _fullCardStory(cardAnnoRoman: null));
        expect(find.textContaining('Anno'), findsNothing);
      },
    );

    testWidgets(
      'given both city fields are null, '
      'when rendered, '
      'then footer shows only the place location',
      (tester) async {
        await _pump(
          tester,
          _fullCardStory(cardCityCh: null, cardCityEn: null),
        );
        expect(find.text('義大利羅馬'), findsOneWidget);
        expect(find.textContaining('羅馬 Rome'), findsNothing);
      },
    );

    testWidgets(
      'given only cardCityEn is null, '
      'when rendered, '
      'then footer shows place location + cardCityCh',
      (tester) async {
        await _pump(tester, _fullCardStory(cardCityEn: null));
        expect(find.textContaining('義大利羅馬'), findsOneWidget);
        expect(find.textContaining('羅馬'), findsAtLeastNWidgets(1));
      },
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/card_layout_body_test.dart`
Expected: FAIL — `card_layout_body.dart` does not exist.

- [ ] **Step 3: Write `_CardLayoutBody`**

Create `frontend/lib/features/daily_story/presentation/widgets/card_layout_body.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IG-card-style detail body for a daily story.
///
/// Mirrors the visual structure of the Instagram card (photo plate +
/// text plate) without being a pixel-perfect clone. Decorative fields
/// (spine, Anno year, pull quote, city footer extras) gracefully omit
/// when null; the layout never collapses to a broken state.
///
/// Caller must guarantee `story.hasCardLayout == true`.
class CardLayoutBody extends StatelessWidget {
  final DailyStory story;
  const CardLayoutBody({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoPlate(story: story),
          _TextPlate(story: story),
        ],
      ),
    );
  }
}

class _PhotoPlate extends StatelessWidget {
  final DailyStory story;
  const _PhotoPlate({required this.story});

  @override
  Widget build(BuildContext context) {
    final imageUrl = story.imageUrl;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.black54),
            )
          else
            Container(color: Colors.black87),
          // Tint overlay so light photos still show white text.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x99000000),
                ],
              ),
            ),
          ),
          if (story.cardLocationEn != null)
            Positioned(
              left: 20,
              bottom: 160,
              child: _SpineLabel(text: story.cardLocationEn!),
            ),
          if (story.cardAnnoRoman != null)
            Positioned(
              top: 20,
              right: 20,
              child: _AnnoBadge(roman: story.cardAnnoRoman!),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.cardTitle!,
                  style: GoogleFonts.notoSerifTc(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  story.cardTitleSub!,
                  style: GoogleFonts.notoSerifTc(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpineLabel extends StatelessWidget {
  final String text;
  const _SpineLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        letterSpacing: 3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AnnoBadge extends StatelessWidget {
  final String roman;
  const _AnnoBadge({required this.roman});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 0.8),
      ),
      child: Text(
        'Anno · $roman',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _TextPlate extends StatelessWidget {
  final DailyStory story;
  const _TextPlate({required this.story});

  @override
  Widget build(BuildContext context) {
    final paragraphs = story.cardParagraphs!;
    return Container(
      color: const Color(0xFFFAF7F1),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            i == 0
                ? _DropCapParagraph(text: paragraphs[i])
                : _BodyParagraph(text: paragraphs[i]),
          ],
          if (story.cardPullQuote != null) ...[
            const SizedBox(height: 28),
            _PullQuote(
              quote: story.cardPullQuote!,
              attrib: story.cardPullQuoteAttrib,
            ),
          ],
          const SizedBox(height: 32),
          _Footer(story: story),
        ],
      ),
    );
  }
}

class _DropCapParagraph extends StatelessWidget {
  final String text;
  const _DropCapParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return _BodyParagraph(text: text);
    final first = text.substring(0, 1);
    final rest = text.substring(1);
    return RichText(
      text: TextSpan(
        style: GoogleFonts.notoSerifTc(
          color: const Color(0xFF1B1B1B),
          fontSize: 16,
          height: 1.8,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                first,
                style: GoogleFonts.notoSerifTc(
                  color: const Color(0xFF1B1B1B),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}

class _BodyParagraph extends StatelessWidget {
  final String text;
  const _BodyParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSerifTc(
        color: const Color(0xFF1B1B1B),
        fontSize: 16,
        height: 1.8,
      ),
    );
  }
}

class _PullQuote extends StatelessWidget {
  final String quote;
  final String? attrib;
  const _PullQuote({required this.quote, required this.attrib});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF8B6F3E), width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote,
              style: GoogleFonts.notoSerifTc(
                color: const Color(0xFF1B1B1B),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            if (attrib != null) ...[
              const SizedBox(height: 6),
              Text(
                attrib!,
                style: GoogleFonts.notoSerifTc(
                  color: const Color(0xFF6B5C42),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final DailyStory story;
  const _Footer({required this.story});

  @override
  Widget build(BuildContext context) {
    final cityCh = story.cardCityCh;
    final cityEn = story.cardCityEn;
    final cityPart = [
      if (cityCh != null) cityCh,
      if (cityEn != null) cityEn,
    ].join(' ');
    final text = cityPart.isEmpty
        ? story.placeLocation
        : '${story.placeLocation} · $cityPart';
    return Text(
      text,
      style: GoogleFonts.notoSerifTc(
        color: const Color(0xFF6B5C42),
        fontSize: 12,
        letterSpacing: 0.6,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/card_layout_body_test.dart`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Run analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/widgets/card_layout_body.dart frontend/test/features/daily_story/presentation/widgets/card_layout_body_test.dart
git commit -m "feat(daily_story): add CardLayoutBody widget

photo plate + text plate detail body matching the IG card brand
treatment. decorative fields (spine, Anno, pull quote, city footer)
omit individually when null.
"
```

---

## Task 14: Fork detail screen on `hasCardLayout`

**Files:**
- Modify: `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
- Modify: `frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`

- [ ] **Step 1: Update the existing detail screen test**

Open `frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`.

Rename the existing `_story()` helper to `_legacyStory()` (it already
constructs a story without card fields — that's the legacy path).

Add a new helper:

```dart
DailyStory _cardStory() => DailyStory(
  publishDate: DateTime(2026, 5, 11),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: 'p1\n\np2\n\np3',
  imageUrl: null,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  cardTitle: '血腥的盛宴',
  cardTitleSub: '從石灰岩堆砌的命運舞台',
  cardParagraphs: const ['p1...', 'p2...', 'p3...'],
);
```

Add inside the existing `group('DailyStoryDetailScreen', ...)`:

```dart
testWidgets(
  'given a story without card fields, when the screen loads, '
  'then the legacy layout (placeName / meta rows / story body) is shown',
  (tester) async {
    final story = _legacyStory();
    await _pumpDetail(tester, story: story);

    expect(find.text(story.placeName), findsOneWidget);
    expect(find.text(story.placeLocation), findsOneWidget);
    expect(find.text(story.era), findsOneWidget);
  },
);

testWidgets(
  'given a story with full card fields, when the screen loads, '
  'then the card layout title and subtitle are shown',
  (tester) async {
    final story = _cardStory();
    await _pumpDetail(tester, story: story);

    expect(find.text('血腥的盛宴'), findsOneWidget);
    expect(find.text('從石灰岩堆砌的命運舞台'), findsOneWidget);
    // legacy meta rows should NOT appear in card layout
    expect(find.text('daily_story.detail_location_label'), findsNothing);
  },
);
```

Also update the existing `_story()` reference in the first test (the one
checking placeName / placeLocation / era is visible) to call
`_legacyStory()` so the assertion still matches the legacy body.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`
Expected: FAIL — the card-layout test fails because the screen still
always renders the legacy layout.

- [ ] **Step 3: Fork the screen body**

Rewrite `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story_card_mode.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_layout_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DailyStoryDetailScreen extends StatelessWidget {
  final DailyStory story;
  const DailyStoryDetailScreen({super.key, required this.story});

  static const _historyRoute = '/daily-story/history';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('daily_story.detail_title'.tr()),
        actions: [
          TextButton(
            onPressed: () => context.push(_historyRoute),
            child: Text('daily_story.detail_history_button'.tr()),
          ),
        ],
      ),
      body: story.hasCardLayout
          ? CardLayoutBody(story: story)
          : _LegacyLayoutBody(story: story),
    );
  }
}

class _LegacyLayoutBody extends StatelessWidget {
  final DailyStory story;
  const _LegacyLayoutBody({required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (story.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(story.placeName, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          _MetaRow(
            label: 'daily_story.detail_location_label'.tr(),
            value: story.placeLocation,
          ),
          _MetaRow(
            label: 'daily_story.detail_era_label'.tr(),
            value: story.era,
          ),
          const SizedBox(height: 16),
          _StoryBody(text: story.story, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _StoryBody extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _StoryBody({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final paragraphs = _splitIntoParagraphs(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(paragraphs[i], style: style),
        ],
      ],
    );
  }

  static List<String> _splitIntoParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    final parts = normalized
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? [normalized] : parts;
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart
git commit -m "feat(daily_story): fork detail screen on hasCardLayout

new card layout for rows with full card_* fields; legacy layout
preserved for rows without (transition period + future languages).
"
```

---

## Task 15: Fork home preview card on `hasCardLayout`

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/widgets/card_preview_card.dart`
- Modify: `frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart`
- Modify: `frontend/test/features/daily_story/presentation/widgets/daily_story_card_test.dart`

- [ ] **Step 1: Update `daily_story_card_test.dart`**

Add a card-story helper at the top:

```dart
DailyStory _cardStory({String? imageUrl}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 11),
    language: 'zh-TW',
    placeName: '羅馬競技場',
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: 'p1\n\np2\n\np3',
    imageUrl: imageUrl,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
    cardTitle: '血腥的盛宴',
    cardTitleSub: '從石灰岩堆砌的命運舞台',
    cardParagraphs: const [
      '維斯帕先在西元七十年下令動工，巨大的石灰岩塊從幾十里外的'
          '採石場運抵羅馬城。',
      'p2',
      'p3',
    ],
  );
}
```

Add tests inside the existing group:

```dart
testWidgets(
  'given a story with full card fields, when the card loads, '
  'then cardTitle is shown as the main heading',
  (tester) async {
    final repo = InMemoryDailyStoryRepository()..seed([_cardStory()]);
    await _pumpCard(tester, repo: repo);

    expect(find.text('血腥的盛宴'), findsOneWidget);
    expect(find.text('從石灰岩堆砌的命運舞台'), findsOneWidget);
    // placeName should NOT be the heading in card preview
    expect(find.text('羅馬競技場'), findsNothing);
  },
);

testWidgets(
  'given a story with full card fields, when the user taps, '
  'then the detail route receives the story as extra',
  (tester) async {
    final story = _cardStory();
    final repo = InMemoryDailyStoryRepository()..seed([story]);
    final extras = <Object?>[];
    await _pumpCard(tester, repo: repo, extras: extras);

    await tester.tap(find.text('血腥的盛宴'));
    await tester.pumpAndSettle();

    expect(extras, [story]);
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_card_test.dart`
Expected: FAIL — new card preview is not yet implemented; `find.text('血腥的盛宴')` finds nothing.

- [ ] **Step 3: Create `CardPreviewCard`**

Create `frontend/lib/features/daily_story/presentation/widgets/card_preview_card.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Home-screen preview when the story has the full card_* fields.
///
/// Shows cardTitle as the main heading (replacing placeName) and the
/// first ~60 chars of paragraph 1 as a teaser. Deliberately omits the
/// drop-cap / Roman year / pull quote — those belong to the detail page.
class CardPreviewCard extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const CardPreviewCard({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstParagraph = story.cardParagraphs!.first;
    final teaser = firstParagraph.length > 60
        ? '${firstParagraph.substring(0, 60)}…'
        : firstParagraph;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily_story.card_label'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.cardTitle!,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    story.cardTitleSub!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teaser,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'daily_story.card_cta'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Fork `daily_story_card.dart` on `hasCardLayout`**

In `frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart`, find the `_StoryCard` reference inside `DailyStoryCard.build`:

```dart
        return _StoryCard(
          story: story,
          onTap: () => context.push(_detailRoute, extra: story),
        );
```

Replace it with:

```dart
        void onTap() => context.push(_detailRoute, extra: story);
        return story.hasCardLayout
            ? CardPreviewCard(story: story, onTap: onTap)
            : _StoryCard(story: story, onTap: onTap);
```

And add these imports at the top:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story_card_mode.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_preview_card.dart';
```

(Existing `_StoryCard` private widget stays as the legacy preview.)

- [ ] **Step 5: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_card_test.dart`
Expected: PASS (existing 4 + new 2 tests).

- [ ] **Step 6: Run analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/widgets/card_preview_card.dart frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart frontend/test/features/daily_story/presentation/widgets/daily_story_card_test.dart
git commit -m "feat(daily_story): fork home preview on hasCardLayout

card preview uses cardTitle/cardTitleSub + 60-char teaser of paragraph
1. legacy preview kept for rows without card fields.
"
```

---

## Task 16: Run the full test suites + manual verification list

**Files:** none (verification + commit a runbook note)

- [ ] **Step 1: Run all backend tests**

Run: `cd backend && uv run pytest -v`
Expected: ALL PASS.

- [ ] **Step 2: Run all frontend tests**

Run: `cd frontend && fvm flutter test`
Expected: ALL PASS.

- [ ] **Step 3: Run analyze + format check**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: no issues.

- [ ] **Step 4: Manual verification (operator runs after PR merge)**

Append the following checklist to the PR description (do NOT mark items
ticked until each is done in staging / prod):

```markdown
## Manual deploy & verification

Deploy order (per spec §8):

- [ ] 1. Merge PR to master (code shipped, not yet deployed)
- [ ] 2. Run migration on prod Supabase:
       `supabase migration up --linked` (or admin Dashboard SQL editor)
- [ ] 3. Immediately deploy backend to VPS (within seconds of step 2):
       `ssh vps "cd lorescape-backend && git pull && systemctl restart lorescape-backend"`
- [ ] 4. Backfill dry-run from local:
       `cd backend && uv run python -m scripts.backfill_card_fields --dry-run`
       confirm expected row count
- [ ] 5. Backfill real run:
       `cd backend && uv run python -m scripts.backfill_card_fields`
       capture log; verify summary line `processed=N failed=0`
- [ ] 6. Admin: in Supabase Dashboard, fill any new `daily_story_places`
       rows that are missing `card_location_en` / `card_city_ch` /
       `card_city_en` / `latitude` / `longitude`
- [ ] 7. Trigger one IG card publish manually (or wait for 21:00 cron)
       and confirm the IG card still renders correctly
- [ ] 8. App: ship new version to TestFlight / Play internal track
       - [ ] zh-TW locale → see new card layout (title / subtitle /
              drop-cap / 3 paragraphs / pull quote / Anno block)
       - [ ] en locale → see new card layout
       - [ ] Old App version (production) still works (legacy layout)
- [ ] 9. Spot-check: in Supabase Dashboard, set one row's
       `card_paragraphs` to NULL; in App, confirm that row falls back
       to legacy layout; restore the value
```

- [ ] **Step 5: (No commit needed for this task — it's verification only.)**

---

## Self-review notes (for plan author)

- Task 5 sets default values for new `StoryRow` fields (`""` / empty tuple) for backwards compatibility with any test that omits them. The job in Task 6 always passes them explicitly, so production paths never hit the defaults.
- Task 8 uses indirection seams (`_generate_story` / `_fetch_summary`) so tests can monkeypatch without touching the underlying modules — this matches the project's existing test pattern.
- Task 13 omits a CSS-grain texture by design (Q3 ruled out C / strict fidelity). The plate uses solid colors + a linear gradient tint only.
- Task 16 manual checklist is intentionally a TODO list inside the PR body, not Dart/Python code — the deploy is a human operation.
