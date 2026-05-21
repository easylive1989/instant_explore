import json
from unittest.mock import MagicMock, patch

from lorescape_backend.daily_story.gemini_client import (
    GeneratedStory,
    generate_story,
)


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_parses_json_response(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "羅馬競技場",
            "place_location": "義大利羅馬",
            "era": "公元 70-80 年",
            "story": "...",
            "threads_summary": "short version",
            "hashtags": ["rome", "ancientWonders", "colosseum"],
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

    assert result == GeneratedStory(
        place_name="羅馬競技場",
        place_location="義大利羅馬",
        era="公元 70-80 年",
        story="...",
        threads_summary="short version",
        hashtags=("rome", "ancientWonders", "colosseum"),
    )
    mock_client_cls.assert_called_once_with(api_key="key")
    call_kwargs = mock_client.models.generate_content.call_args.kwargs
    assert call_kwargs["model"] == "gemini-2.5-pro"


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_passes_system_instruction_and_temperature(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "X",
            "place_location": "Y",
            "era": "Z",
            "story": "S",
            "threads_summary": "T",
            "hashtags": [],
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    generate_story(
        api_key="key",
        system_instruction="my-system",
        user_prompt="my-user",
        response_schema={"type": "OBJECT", "required": ["story"]},
    )

    kwargs = mock_client.models.generate_content.call_args.kwargs
    config = kwargs["config"]
    # The config object must convey the system instruction, temperature, JSON
    # mime type, and schema. Implementation may use either GenerateContentConfig
    # or a dict — we read attributes via getattr/dict access tolerantly.
    if isinstance(config, dict):
        assert config["system_instruction"] == "my-system"
        assert config["temperature"] == 0.3
        assert config["response_mime_type"] == "application/json"
        assert config["response_schema"]["required"] == ["story"]
    else:
        assert config.system_instruction == "my-system"
        assert config.temperature == 0.3
        assert config.response_mime_type == "application/json"
        assert config.response_schema["required"] == ["story"]


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
