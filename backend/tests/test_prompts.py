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
