from unittest.mock import patch

import pytest

from lorescape_backend.narration import service
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    NarrationRequest,
)


_INTRO_EXTRACT = "Roman colony; Van Gogh painted here in 1888."


@patch("lorescape_backend.narration.service.wikipedia.fetch_intro_extract")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_hooks_returns_parsed_hooks(gen_mock, fetch_mock):
    fetch_mock.return_value = _INTRO_EXTRACT
    gen_mock.return_value = {
        "hooks": [
            {"id": "h1", "title": "T1", "teaser": "Te1"},
            {"id": "h2", "title": "T2", "teaser": "Te2"},
        ],
        "insufficient_source": False,
    }

    result = service.generate_hooks(
        api_key="K",
        request=HooksRequest(
            place_name="Arles",
            location="Provence",
            wikipedia_title="Arles",
            language="zh-TW",
        ),
    )

    assert len(result.hooks) == 2
    assert result.hooks[0].id == "h1"
    assert result.insufficient_source is False
    fetch_mock.assert_called_once_with("Arles")


@patch("lorescape_backend.narration.service.wikipedia.fetch_intro_extract")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_hooks_handles_insufficient_source(gen_mock, fetch_mock):
    fetch_mock.return_value = _INTRO_EXTRACT
    gen_mock.return_value = {"hooks": [], "insufficient_source": True}

    result = service.generate_hooks(
        api_key="K",
        request=HooksRequest(
            place_name="x", wikipedia_title="x", language="en",
        ),
    )

    assert result.hooks == []
    assert result.insufficient_source is True


def test_generate_hooks_rejects_unsupported_language():
    with pytest.raises(service.UnsupportedLanguageError):
        service.generate_hooks(
            api_key="K",
            request=HooksRequest(
                place_name="x", wikipedia_title="x", language="ja",
            ),
        )


@patch("lorescape_backend.narration.service.wikipedia.fetch_intro_extract")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_returns_parsed_response(gen_mock, fetch_mock):
    fetch_mock.return_value = _INTRO_EXTRACT
    gen_mock.return_value = {
        "place_name": "亞爾",
        "place_location": "法國普羅旺斯",
        "era": "十九世紀末",
        "paragraphs": ["一", "二", "三"],
        "pull_quote": "「我看見麥田」",
        "insufficient_source": False,
    }

    result = service.generate_narration(
        api_key="K",
        request=NarrationRequest(
            place_name="Arles",
            location="Provence",
            wikipedia_title="Arles",
            language="zh-TW",
            hook=HookItem(id="h", title="梵谷的黃色小屋",
                          teaser="444 天的悲劇"),
        ),
    )

    assert result.place_name == "亞爾"
    assert result.paragraphs == ["一", "二", "三"]
    assert result.pull_quote == "「我看見麥田」"
    assert result.insufficient_source is False
    fetch_mock.assert_called_once_with("Arles")
    # Hook content should reach the LLM via the user prompt
    call_kwargs = gen_mock.call_args.kwargs
    assert "梵谷的黃色小屋" in call_kwargs["user_prompt"]
    assert "444 天的悲劇" in call_kwargs["user_prompt"]


@patch("lorescape_backend.narration.service.wikipedia.fetch_intro_extract")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_without_hook_invites_self_pick(gen_mock, fetch_mock):
    fetch_mock.return_value = _INTRO_EXTRACT
    gen_mock.return_value = {
        "place_name": "Arles",
        "place_location": "Provence",
        "era": "Late 19th c.",
        "paragraphs": ["a", "b", "c"],
        "pull_quote": "",
        "insufficient_source": False,
    }

    service.generate_narration(
        api_key="K",
        request=NarrationRequest(
            place_name="Arles", wikipedia_title="Arles", language="en",
        ),
    )

    call_kwargs = gen_mock.call_args.kwargs
    assert "No specific narrative anchor" in call_kwargs["user_prompt"]


@patch("lorescape_backend.narration.service.wikipedia.fetch_intro_extract")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_forces_empty_paragraphs_when_insufficient_source(
    gen_mock, fetch_mock,
):
    """If the model flags insufficient_source, the service MUST discard
    whatever it put in `paragraphs` and `pull_quote` — observed failure
    mode: model regurgitates the in-prompt positive example."""
    fetch_mock.return_value = ""
    gen_mock.return_value = {
        "place_name": "Fake Place",
        "place_location": "",
        "era": "",
        # Model leaked the positive example into paragraphs anyway.
        "paragraphs": [
            "一八八八年二月，文森·梵谷踏上亞爾...",
            "一八八八年二月，文森·梵谷踏上亞爾...",
            "一八八八年二月，文森·梵谷踏上亞爾...",
        ],
        "pull_quote": "「我看見麥田」",
        "insufficient_source": True,
    }

    result = service.generate_narration(
        api_key="K",
        request=NarrationRequest(
            place_name="Fake", wikipedia_title="Fake", language="zh-TW",
        ),
    )

    assert result.insufficient_source is True
    assert result.paragraphs == []
    assert result.pull_quote == ""


def test_generate_narration_rejects_unsupported_language():
    with pytest.raises(service.UnsupportedLanguageError):
        service.generate_narration(
            api_key="K",
            request=NarrationRequest(
                place_name="x", wikipedia_title="x", language="ja",
            ),
        )
