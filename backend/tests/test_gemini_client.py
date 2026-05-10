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
    )
    mock_client_cls.assert_called_once_with(api_key="key")
    call_kwargs = mock_client.models.generate_content.call_args.kwargs
    assert call_kwargs["model"] == "gemini-2.5-flash"


@patch("lorescape_backend.daily_story.gemini_client.genai.Client")
def test_generate_story_passes_system_instruction_and_temperature(mock_client_cls):
    mock_response = MagicMock()
    mock_response.text = json.dumps(
        {"place_name": "X", "place_location": "Y", "era": "Z", "story": "S"}
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
