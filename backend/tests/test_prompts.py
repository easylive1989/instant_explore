import pytest

from lorescape_backend.daily_story.prompts import (
    SYSTEM_INSTRUCTION,
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
    for lang in ("en", "zh-TW"):
        prompt = build_user_prompt(
            wikipedia_title="X", wikipedia_extract="Y", language=lang
        )
        for field in BASE_FIELDS:
            assert field in prompt, f"{lang} prompt missing base field: {field}"
        for field in CARD_FIELDS:
            assert field in prompt, f"{lang} prompt missing card field: {field}"
        assert "story:" not in prompt, (
            f"{lang} prompt should no longer list `story` as an output field"
        )


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


def test_build_user_prompt_zh_tw_no_longer_uses_ch_suffix():
    prompt = build_user_prompt(
        wikipedia_title="Eiffel Tower",
        wikipedia_extract="Built in 1889 by Gustave Eiffel.",
        language="zh-TW",
    )
    for old_field in (
        "card_title_ch",
        "card_title_sub_ch",
        "card_paragraphs_ch",
        "card_pull_quote_ch",
        "card_pull_quote_attrib_ch",
    ):
        assert old_field not in prompt, f"zh-TW prompt still mentions {old_field}"



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
