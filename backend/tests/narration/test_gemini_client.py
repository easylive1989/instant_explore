"""Tests for narration/gemini_client.py — grounded generation path."""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import patch

import pytest

from lorescape_backend.narration import gemini_client

_SCHEMA = {"type": "OBJECT", "properties": {"era": {"type": "STRING"}}}


def _response(text: str) -> SimpleNamespace:
    """Minimal generate_content response shape (no grounding metadata)."""
    return SimpleNamespace(text=text, candidates=[])


def _call_grounded() -> dict:
    return gemini_client.generate_grounded(
        api_key="k",
        system_instruction="sys",
        user_prompt="prompt",
        response_schema=_SCHEMA,
    )


@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_returns_parsed_json(client_cls):
    client_cls.return_value.models.generate_content.return_value = _response(
        '{"era": "1888"}'
    )

    assert _call_grounded() == {"era": "1888"}


@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_strips_markdown_code_fence(client_cls):
    client_cls.return_value.models.generate_content.return_value = _response(
        '```json\n{"era": "1888"}\n```'
    )

    assert _call_grounded() == {"era": "1888"}


@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_call_uses_search_tool_without_schema(client_cls):
    client_cls.return_value.models.generate_content.return_value = _response(
        '{"era": "x"}'
    )

    _call_grounded()

    config = client_cls.return_value.models.generate_content.call_args.kwargs[
        "config"
    ]
    assert config.tools, "google_search tool must be attached"
    assert config.response_schema is None
    assert config.response_mime_type is None


@patch("lorescape_backend.narration.gemini_client.generate_structured")
@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_repairs_broken_json_via_structured_call(client_cls, repair):
    client_cls.return_value.models.generate_content.return_value = _response(
        "Here are three stories about Arles..."
    )
    repair.return_value = {"era": "repaired"}

    assert _call_grounded() == {"era": "repaired"}
    repair_kwargs = repair.call_args.kwargs
    assert repair_kwargs["response_schema"] is _SCHEMA
    assert "Here are three stories" in repair_kwargs["user_prompt"]


@patch("lorescape_backend.narration.gemini_client.generate_structured")
@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_repairs_non_object_json(client_cls, repair):
    client_cls.return_value.models.generate_content.return_value = _response(
        '["a", "list", "not", "object"]'
    )
    repair.return_value = {"era": "repaired"}

    assert _call_grounded() == {"era": "repaired"}


@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_raises_on_empty_response(client_cls):
    client_cls.return_value.models.generate_content.return_value = _response("")

    with pytest.raises(RuntimeError, match="empty response"):
        _call_grounded()


@patch("lorescape_backend.narration.gemini_client.time.sleep")
@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_retries_on_503_then_succeeds(client_cls, sleep_mock):
    from google.genai import errors as genai_errors

    err = genai_errors.ServerError(
        503, {"error": {"message": "high demand", "status": "UNAVAILABLE"}}
    )
    client_cls.return_value.models.generate_content.side_effect = [
        err, _response('{"era": "1888"}'),
    ]

    assert _call_grounded() == {"era": "1888"}
    assert client_cls.return_value.models.generate_content.call_count == 2
    sleep_mock.assert_called_once_with(3)


@patch("lorescape_backend.narration.gemini_client.time.sleep")
@patch("lorescape_backend.narration.gemini_client.genai.Client")
def test_grounded_raises_after_exhausting_503_retries(client_cls, sleep_mock):
    from google.genai import errors as genai_errors

    err = genai_errors.ServerError(
        503, {"error": {"message": "high demand", "status": "UNAVAILABLE"}}
    )
    client_cls.return_value.models.generate_content.side_effect = err

    with pytest.raises(genai_errors.ServerError):
        _call_grounded()
    assert client_cls.return_value.models.generate_content.call_count == 3
