import pytest

from lorescape_backend.narration import prompts
from lorescape_backend.shared.story_prompt import StoryHook
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


def _bundle_zh(extract_text: str, title: str = "亞爾") -> SourceBundle:
    ex = SourceExtract(
        provider="wikipedia_en", title=title, text=extract_text,
        char_count=len(extract_text), has_named_entity=True,
    )
    return SourceBundle(
        wikidata_id="Q2", place_name=title,
        extracts=[ex], total_chars=len(extract_text), is_sufficient=True,
    )


# ---------- narration (long-form story) ----------


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_narration_schema_has_required_fields(language):
    schema = prompts.narration_response_schema(language)
    required = set(schema["required"])
    for field in (
        "place_name", "place_location", "era",
        "paragraphs", "pull_quote", "insufficient_source",
    ):
        assert field in required


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_narration_schema_paragraphs_is_array_of_3_strings(language):
    schema = prompts.narration_response_schema(language)
    paragraphs = schema["properties"]["paragraphs"]
    assert paragraphs["type"] == "ARRAY"
    assert paragraphs["items"]["type"] == "STRING"
    assert paragraphs.get("minItems") == 3
    assert paragraphs.get("maxItems") == 3


def test_narration_schema_raises_on_unknown_language():
    with pytest.raises(KeyError):
        prompts.narration_response_schema("ja")


def test_narration_system_instruction_reuses_shared_skeleton():
    instruction = prompts.narration_system_instruction("zh-TW")
    # Shared skeleton requires the four story beats
    for beat in ("PROTAGONIST", "MOTIVATION", "CONFLICT", "OUTCOME"):
        assert beat in instruction


def test_narration_user_prompt_includes_place_and_extract():
    prompt = prompts.build_narration_user_prompt(
        place_name="亞爾",
        location="法國普羅旺斯",
        source_bundle=_bundle_zh("Built in Roman times...", title="Arles"),
        language="zh-TW",
    )
    assert "亞爾" in prompt
    assert "Built in Roman times..." in prompt
    # output spec tail
    assert "paragraphs" in prompt
    assert "pull_quote" in prompt
    assert "insufficient_source" in prompt
    # new source-agnostic wording
    assert "提供的來源內容不足" in prompt


def test_narration_user_prompt_with_hook_locks_thread():
    prompt = prompts.build_narration_user_prompt(
        place_name="Arles",
        location="Provence",
        source_bundle=_bundle_en("...", title="Arles"),
        language="en",
        hook=StoryHook(title="Yellow House", teaser="444 days that ended in madness"),
    )
    assert "Yellow House" in prompt
    assert "444 days that ended in madness" in prompt


def test_narration_user_prompt_raises_on_unknown_language():
    with pytest.raises(KeyError):
        prompts.build_narration_user_prompt(
            place_name="X", location="Y",
            source_bundle=_bundle_en("Z", title="X"),
            language="ja",
        )


# ---------- hooks (narrative angles) ----------


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_hooks_schema_has_required_fields(language):
    schema = prompts.hooks_response_schema(language)
    required = set(schema["required"])
    assert "hooks" in required
    assert "insufficient_source" in required


@pytest.mark.parametrize("language", ["zh-TW", "en"])
def test_hooks_schema_each_item_has_id_title_teaser(language):
    schema = prompts.hooks_response_schema(language)
    item = schema["properties"]["hooks"]["items"]
    assert item["type"] == "OBJECT"
    for field in ("id", "title", "teaser"):
        assert field in item["required"]


def test_hooks_system_instruction_enforces_fact_boundary():
    instruction = prompts.hooks_system_instruction("zh-TW")
    lower = instruction.lower()
    assert "fact boundary" in lower
    assert "insufficient_source" in instruction


def test_hooks_user_prompt_carries_extract():
    ex = SourceExtract(
        provider="wikipedia_en", title="Eiffel Tower",
        text="Built in 1889...",
        char_count=len("Built in 1889..."), has_named_entity=True,
    )
    bundle = SourceBundle(
        wikidata_id="Q243", place_name="艾菲爾鐵塔",
        extracts=[ex], total_chars=len("Built in 1889..."), is_sufficient=True,
    )
    prompt = prompts.build_hooks_user_prompt(
        place_name="艾菲爾鐵塔",
        location="巴黎",
        source_bundle=bundle,
    )
    assert "艾菲爾鐵塔" in prompt
    assert "Built in 1889..." in prompt
