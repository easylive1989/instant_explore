import pytest

from lorescape_backend.shared.story_prompt import (
    StoryHook,
    build_story_system_instruction,
    build_story_user_prompt,
)


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


def test_user_prompt_includes_place_and_extract():
    prompt = build_story_user_prompt(
        place_name="Eiffel Tower",
        location="Paris, France",
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
    )
    assert "Eiffel Tower" in prompt
    assert "Paris, France" in prompt
    assert "Built in 1889 by Gustave Eiffel." in prompt


def test_user_prompt_without_hook_invites_self_pick():
    prompt = build_story_user_prompt(
        place_name="X",
        location="Y",
        wikipedia_title="X",
        wikipedia_extract="Z",
    )
    assert "No specific narrative anchor" in prompt


def test_user_prompt_with_hook_locks_thread():
    prompt = build_story_user_prompt(
        place_name="Arles",
        location="Provence, France",
        wikipedia_title="Arles",
        wikipedia_extract="...",
        hook=StoryHook(
            title="梵谷的黃色小屋",
            teaser="他在亞爾的四百四十四天，最後以瘋狂收場",
        ),
    )
    assert "梵谷的黃色小屋" in prompt
    assert "do not bounce between unrelated topics" in prompt
