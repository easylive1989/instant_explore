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


def test_build_user_prompt_raises_on_unknown_language():
    with pytest.raises(KeyError):
        build_user_prompt(wikipedia_title="X", wikipedia_extract="Y", language="ja")
