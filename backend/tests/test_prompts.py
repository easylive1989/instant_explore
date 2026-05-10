from lorescape_backend.daily_story.prompts import (
    GEMINI_RESPONSE_SCHEMA,
    SYSTEM_INSTRUCTION,
    build_user_prompt,
)


def test_build_user_prompt_includes_extract_and_language_name_zh_tw():
    prompt = build_user_prompt(
        wikipedia_title="Colosseum",
        wikipedia_extract="Built in 70-80 CE by Vespasian.",
        language="zh-TW",
    )
    assert "Colosseum" in prompt
    assert "Built in 70-80 CE by Vespasian." in prompt
    assert "Traditional Chinese" in prompt or "zh-TW" in prompt


def test_build_user_prompt_includes_language_name_en():
    prompt = build_user_prompt(
        wikipedia_title="Colosseum",
        wikipedia_extract="Built in 70-80 CE.",
        language="en",
    )
    assert "English" in prompt


def test_build_user_prompt_lists_required_fields():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    for field in ("place_name", "place_location", "era", "story"):
        assert field in prompt


def test_build_user_prompt_states_anti_hallucination_constraint():
    prompt = build_user_prompt(
        wikipedia_title="X", wikipedia_extract="Y", language="en"
    )
    # Should mention real historical figure / specific year / concrete event
    lower = prompt.lower()
    assert "historical figure" in lower or "real" in lower
    assert "year" in lower or "era" in lower


def test_system_instruction_forbids_inventing_facts():
    lower = SYSTEM_INSTRUCTION.lower()
    assert "strictly" in lower or "do not introduce" in lower or "do not invent" in lower


def test_response_schema_requires_four_fields():
    required = GEMINI_RESPONSE_SCHEMA.get("required", [])
    assert set(required) == {"place_name", "place_location", "era", "story"}


def test_build_user_prompt_raises_on_unknown_language():
    import pytest
    with pytest.raises(KeyError):
        build_user_prompt(wikipedia_title="X", wikipedia_extract="Y", language="ja")
