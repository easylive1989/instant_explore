import pytest

from lorescape_backend.daily_story.prompts import (
    SYSTEM_INSTRUCTION,
    SYSTEM_INSTRUCTION_FOR,
    build_response_schema,
    build_user_prompt,
)


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

STORY_FIELDS = {"paragraphs"}


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_build_response_schema_has_base_story_and_card_fields(language):
    schema = build_response_schema(language)
    required = set(schema["required"])
    assert BASE_FIELDS.issubset(required)
    assert STORY_FIELDS.issubset(required)
    assert CARD_FIELDS.issubset(required)
    assert "story" not in required
    assert "story" not in schema["properties"]


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_build_response_schema_paragraphs_is_array_of_3_strings(language):
    schema = build_response_schema(language)
    paragraphs = schema["properties"]["paragraphs"]
    assert paragraphs["type"] == "ARRAY"
    assert paragraphs["items"]["type"] == "STRING"
    assert paragraphs.get("minItems") == 3
    assert paragraphs.get("maxItems") == 3


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_build_response_schema_card_paragraphs_is_array_of_3_strings(language):
    schema = build_response_schema(language)
    paragraphs = schema["properties"]["card_paragraphs"]
    assert paragraphs["type"] == "ARRAY"
    assert paragraphs["items"]["type"] == "STRING"
    assert paragraphs.get("minItems") == 3
    assert paragraphs.get("maxItems") == 3


def test_build_response_schema_hashtags_is_array_of_strings():
    schema = build_response_schema("en")
    hashtags = schema["properties"]["hashtags"]
    assert hashtags["type"] == "ARRAY"
    assert hashtags["items"]["type"] == "STRING"


def test_build_response_schema_raises_on_unknown_language():
    with pytest.raises(KeyError):
        build_response_schema("ja")


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_build_user_prompt_lists_all_output_fields(language):
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
        language=language,
    )
    for field in BASE_FIELDS | STORY_FIELDS | CARD_FIELDS:
        assert field in prompt, f"{language} prompt missing field: {field}"


def test_build_user_prompt_zh_tw_specifies_long_paragraph_length():
    prompt = build_user_prompt(
        wikipedia_title="Arles",
        wikipedia_extract="...",
        language="zh-TW",
    )
    assert "200-300" in prompt
    # short version still spec'd
    assert "60-100" in prompt


def test_build_user_prompt_en_specifies_long_paragraph_length():
    prompt = build_user_prompt(
        wikipedia_title="Arles",
        wikipedia_extract="...",
        language="en",
    )
    assert "80-130 English words" in prompt
    assert "60-100 English words" in prompt


def test_build_user_prompt_includes_extract():
    prompt = build_user_prompt(
        wikipedia_title="Colosseum",
        wikipedia_extract="Built in 70-80 CE by Vespasian.",
        language="zh-TW",
    )
    assert "Colosseum" in prompt
    assert "Built in 70-80 CE by Vespasian." in prompt


def test_build_user_prompt_raises_on_unknown_language():
    with pytest.raises(KeyError):
        build_user_prompt(wikipedia_title="X", wikipedia_extract="Y", language="ja")


def test_system_instruction_constants_match_zh_tw_skeleton():
    assert SYSTEM_INSTRUCTION == SYSTEM_INSTRUCTION_FOR("zh-TW")
    # And the skeleton still forbids inventing facts.
    lower = SYSTEM_INSTRUCTION.lower()
    assert "strictly" in lower
    assert "do not introduce" in lower


def test_system_instruction_for_includes_story_spine_beats():
    for language in ("zh-TW", "en"):
        instruction = SYSTEM_INSTRUCTION_FOR(language)
        for beat in ("PROTAGONIST", "MOTIVATION", "CONFLICT", "OUTCOME"):
            assert beat in instruction


def test_build_user_prompt_zh_tw_has_no_legacy_ch_suffix():
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="...",
        language="zh-TW",
    )
    for legacy in (
        "card_title_ch",
        "card_title_sub_ch",
        "card_paragraphs_ch",
        "card_pull_quote_ch",
    ):
        assert legacy not in prompt
