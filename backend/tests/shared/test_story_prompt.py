import pytest

from lorescape_backend.shared.story_prompt import (
    StoryHook,
    build_story_system_instruction,
    build_story_user_prompt,
)
from lorescape_backend.sources.models import SourceBundle, SourceExtract


# ---------------------------------------------------------------------------
# Helpers shared by old and new tests
# ---------------------------------------------------------------------------

def _en_extract_simple(
    title: str = "Eiffel Tower",
    text: str = "Built in 1889 by Gustave Eiffel.",
) -> SourceExtract:
    return SourceExtract(
        provider="wikipedia_en", title=title, text=text,
        char_count=len(text), has_named_entity=True,
    )


def _bundle_simple(extract: SourceExtract, place_name: str = "Eiffel Tower") -> SourceBundle:
    return SourceBundle(
        wikidata_id=None, place_name=place_name,
        extracts=[extract], total_chars=extract.char_count,
        is_sufficient=True,
    )


# ---------------------------------------------------------------------------
# System instruction tests (unchanged — no signature involved)
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_system_instruction_enforces_fact_boundary(language):
    instruction = build_story_system_instruction(language)
    lower = instruction.lower()
    assert "strictly" in lower
    assert "do not introduce" in lower
    assert "insufficient_source" in instruction


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_system_instruction_lists_four_story_beats(language):
    instruction = build_story_system_instruction(language)
    for beat in ("PROTAGONIST", "MOTIVATION", "CONFLICT", "OUTCOME"):
        assert beat in instruction, (
            f"{language} system instruction missing story beat {beat}"
        )


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_system_instruction_lists_layered_fallback(language):
    instruction = build_story_system_instruction(language)
    assert "SUBJECT PRIORITY" in instruction
    # Four levels of fallback
    for marker in ("1.", "2.", "3.", "4."):
        assert marker in instruction


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_system_instruction_forbids_meta_narration_about_absence(language):
    """When the source is thin, the model must emit insufficient_source — not
    write apologetic meta-prose ("we don't know...") to fill paragraphs."""
    instruction = build_story_system_instruction(language)
    lower = instruction.lower()
    assert "meta-narration" in lower
    assert "insufficient_source" in instruction
    # Forbid the actual failure mode we observed
    assert "we do not know" in lower or "do not write meta" in lower


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_system_instruction_requires_3_paragraph_format(language):
    instruction = build_story_system_instruction(language)
    assert "3 paragraphs" in instruction
    assert "blank line" in instruction.lower()
    # forbid generic openers
    lower = instruction.lower()
    assert "welcome to" in lower or "let me tell you" in lower


def test_system_instruction_zh_tw_uses_han_numerals_rule():
    instruction = build_story_system_instruction("zh-TW")
    assert "Han numerals" in instruction
    assert "一八八八年" in instruction
    assert "「」" in instruction


def test_system_instruction_en_uses_arabic_numerals_rule():
    instruction = build_story_system_instruction("en")
    assert "Arabic numerals" in instruction


def test_system_instruction_includes_positive_example_zh():
    instruction = build_story_system_instruction("zh-TW")
    # The Arles/Van Gogh example mentions the protagonist
    assert "梵谷" in instruction


def test_system_instruction_includes_positive_example_en():
    instruction = build_story_system_instruction("en")
    assert "Vincent van Gogh" in instruction
    assert "Arles" in instruction


def test_system_instruction_raises_on_unknown_language():
    with pytest.raises(KeyError):
        build_story_system_instruction("ja")


# ---------------------------------------------------------------------------
# User prompt tests — updated to new SourceBundle signature
# ---------------------------------------------------------------------------

def test_user_prompt_includes_place_and_extract():
    extract = _en_extract_simple(
        title="Eiffel Tower", text="Built in 1889 by Gustave Eiffel."
    )
    prompt = build_story_user_prompt(
        place_name="Eiffel Tower",
        location="Paris, France",
        source_bundle=_bundle_simple(extract),
        hook=None,
    )
    assert "Eiffel Tower" in prompt
    assert "Paris, France" in prompt
    assert "Built in 1889 by Gustave Eiffel." in prompt


def test_user_prompt_without_hook_has_no_hook_section():
    extract = _en_extract_simple(title="X", text="Z")
    prompt = build_story_user_prompt(
        place_name="X",
        location="Y",
        source_bundle=_bundle_simple(extract, place_name="X"),
        hook=None,
    )
    assert "HOOK to expand" not in prompt


def test_user_prompt_with_hook_locks_thread():
    extract = _en_extract_simple(title="Arles", text="...")
    bundle = SourceBundle(
        wikidata_id=None, place_name="Arles",
        extracts=[extract], total_chars=extract.char_count,
        is_sufficient=True,
    )
    prompt = build_story_user_prompt(
        place_name="Arles",
        location="Provence, France",
        source_bundle=bundle,
        hook=StoryHook(
            title="梵谷的黃色小屋",
            teaser="他在亞爾的四百四十四天，最後以瘋狂收場",
        ),
    )
    assert "梵谷的黃色小屋" in prompt
    assert "HOOK to expand" in prompt


# ---------------------------------------------------------------------------
# New SourceBundle-specific tests
# ---------------------------------------------------------------------------

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
