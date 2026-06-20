"""Tests for the shared google-genai client factory."""
from unittest.mock import patch

from lorescape_backend.shared.genai import (
    BACKEND_AI_STUDIO,
    BACKEND_VERTEX,
    GenaiSettings,
    build_client,
)


@patch("lorescape_backend.shared.genai.genai.Client")
def test_build_client_ai_studio_uses_api_key(mock_client_cls):
    settings = GenaiSettings(backend=BACKEND_AI_STUDIO, api_key="key-123")

    build_client(settings)

    mock_client_cls.assert_called_once_with(api_key="key-123")


@patch("lorescape_backend.shared.genai.genai.Client")
def test_build_client_vertex_uses_project_and_location(mock_client_cls):
    settings = GenaiSettings(
        backend=BACKEND_VERTEX,
        project="instant-explore-7b442",
        location="us-central1",
    )

    build_client(settings)

    mock_client_cls.assert_called_once_with(
        vertexai=True,
        project="instant-explore-7b442",
        location="us-central1",
    )


@patch("lorescape_backend.shared.genai.genai.Client")
def test_build_client_vertex_ignores_api_key(mock_client_cls):
    settings = GenaiSettings(
        backend=BACKEND_VERTEX,
        api_key="leftover-key",
        project="p",
        location="asia-east1",
    )

    build_client(settings)

    _, kwargs = mock_client_cls.call_args
    assert "api_key" not in kwargs
    assert kwargs["vertexai"] is True
    assert kwargs["location"] == "asia-east1"
