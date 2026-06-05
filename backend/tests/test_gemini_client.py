import json
from unittest.mock import MagicMock, patch

from lorescape_backend.daily_story.gemini_client import (
    GEMINI_MODEL,
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
            "hashtags": ["rome", "ancientWonders", "colosseum"],
            "paragraphs": ["長段一", "長段二", "長段三"],
            "card_title": "血腥的盛宴",
            "card_title_sub": "從石灰岩堆砌出的命運舞台",
            "card_paragraphs": ["段一", "段二", "段三"],
            "card_pull_quote": "「他們將死之人向您致敬」",
            "card_pull_quote_attrib": "── 蘇埃托尼烏斯",
            "card_anno_roman": "LXXX",
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
        hashtags=("rome", "ancientWonders", "colosseum"),
        paragraphs=("長段一", "長段二", "長段三"),
        card_title="血腥的盛宴",
        card_title_sub="從石灰岩堆砌出的命運舞台",
        card_paragraphs=("段一", "段二", "段三"),
        card_pull_quote="「他們將死之人向您致敬」",
        card_pull_quote_attrib="── 蘇埃托尼烏斯",
        card_anno_roman="LXXX",
    )
    mock_client_cls.assert_called_once_with(api_key="key")
    call_kwargs = mock_client.models.generate_content.call_args.kwargs
    assert call_kwargs["model"] == GEMINI_MODEL


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_passes_system_instruction_and_temperature(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "X",
            "place_location": "Y",
            "era": "Z",
            "hashtags": [],
            "paragraphs": ["long1", "long2", "long3"],
            "card_title": "title",
            "card_title_sub": "sub",
            "card_paragraphs": ["p1"],
            "card_pull_quote": "quote",
            "card_pull_quote_attrib": "attrib",
            "card_anno_roman": "I",
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    generate_story(
        api_key="key",
        system_instruction="my-system",
        user_prompt="my-user",
        response_schema={"type": "OBJECT", "required": ["card_title"]},
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
        assert config["response_schema"]["required"] == ["card_title"]
    else:
        assert config.system_instruction == "my-system"
        assert config.temperature == 0.3
        assert config.response_mime_type == "application/json"
        assert config.response_schema["required"] == ["card_title"]


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_parses_card_fields(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "艾菲爾鐵塔",
            "place_location": "巴黎",
            "era": "十九世紀末",
            "hashtags": ["paris", "eiffelTower"],
            "paragraphs": ["長段一", "長段二", "長段三"],
            "card_title": "討厭鐵塔的文學大師",
            "card_title_sub": "莫泊桑的「專屬午餐位」",
            "card_paragraphs": ["第一段", "第二段", "第三段"],
            "card_pull_quote": "「看不見艾菲爾鐵塔的地方。」",
            "card_pull_quote_attrib": "── 莫泊桑，一八八九",
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

    assert result.card_title == "討厭鐵塔的文學大師"
    assert result.card_title_sub == "莫泊桑的「專屬午餐位」"
    assert result.card_paragraphs == ("第一段", "第二段", "第三段")
    assert result.card_pull_quote == "「看不見艾菲爾鐵塔的地方。」"
    assert result.card_pull_quote_attrib == "── 莫泊桑，一八八九"
    assert result.card_anno_roman == "MDCCCLXXXIX"
    # story field has been removed from GeneratedStory
    assert not hasattr(result, "story")


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_raises_when_card_field_missing(mock_client_cls):
    """All card fields are required now — missing keys must fail fast."""
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {
            "place_name": "X",
            "place_location": "Y",
            "era": "Z",
            "hashtags": [],
            # card fields omitted intentionally
        }
    )
    mock_client = MagicMock()
    mock_client.models.generate_content.return_value = mock_response
    mock_client_cls.return_value = mock_client

    try:
        generate_story(
            api_key="key",
            system_instruction="sys",
            user_prompt="user",
            response_schema={"type": "OBJECT"},
        )
    except KeyError:
        return
    raise AssertionError("expected KeyError when card_* fields are missing")
