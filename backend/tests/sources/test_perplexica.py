"""Tests for sources/perplexica.py — fetch_web_research."""
from __future__ import annotations

import requests_mock

from lorescape_backend.sources import perplexica

_BASE = "http://localhost:3000"


def _providers_response() -> dict:
    """Mirror the real /api/providers shape (providers[].chatModels/...)."""
    return {
        "providers": [
            {
                "id": "prov-chat",
                "name": "Custom OpenAI",
                "chatModels": [{"name": "Gemini Flash", "key": "gemini-flash"}],
                "embeddingModels": [],
            },
            {
                "id": "prov-embed",
                "name": "Transformers",
                "chatModels": [],
                "embeddingModels": [{"name": "MiniLM", "key": "text-embed"}],
            },
        ]
    }


def test_fetch_web_research_formats_message_and_sources():
    with requests_mock.Mocker() as m:
        m.get(f"{_BASE}/api/providers", json=_providers_response())
        m.post(
            f"{_BASE}/api/search",
            json={
                "message": "Arles is a city in Provence.",
                "sources": [
                    {"metadata": {"title": "Arles", "url": "https://e.com/arles"}},
                ],
            },
        )
        text = perplexica.fetch_web_research(
            place_name="Arles",
            location="Provence",
            language="en",
            base_url=_BASE,
        )

    assert text is not None
    assert "Arles is a city in Provence." in text
    assert "Sources:" in text
    assert "https://e.com/arles" in text


def test_fetch_web_research_sends_resolved_provider_ids():
    with requests_mock.Mocker() as m:
        m.get(f"{_BASE}/api/providers", json=_providers_response())
        m.post(f"{_BASE}/api/search", json={"message": "ok"})
        perplexica.fetch_web_research(
            place_name="X", location="", language="en", base_url=_BASE
        )

        body = m.request_history[-1].json()

    assert body["chatModel"] == {"providerId": "prov-chat", "key": "gemini-flash"}
    assert body["embeddingModel"] == {"providerId": "prov-embed", "key": "text-embed"}
    assert body["sources"] == ["web"]
    assert body["stream"] is False


def test_fetch_web_research_returns_none_when_no_chat_model_configured():
    # Real out-of-the-box state: Transformers embeddings exist, but no chat
    # provider has been added yet — fetch must degrade to None.
    with requests_mock.Mocker() as m:
        m.get(
            f"{_BASE}/api/providers",
            json={
                "providers": [
                    {
                        "id": "transformers",
                        "name": "Transformers",
                        "chatModels": [],
                        "embeddingModels": [{"name": "MiniLM", "key": "k"}],
                    }
                ]
            },
        )
        text = perplexica.fetch_web_research(
            place_name="X", location="", language="en", base_url=_BASE
        )

    assert text is None


def test_fetch_web_research_returns_none_when_providers_5xx():
    with requests_mock.Mocker() as m:
        m.get(f"{_BASE}/api/providers", status_code=503)
        text = perplexica.fetch_web_research(
            place_name="X", location="", language="en", base_url=_BASE
        )

    assert text is None


def test_fetch_web_research_returns_none_when_search_5xx():
    with requests_mock.Mocker() as m:
        m.get(f"{_BASE}/api/providers", json=_providers_response())
        m.post(f"{_BASE}/api/search", status_code=503)
        text = perplexica.fetch_web_research(
            place_name="X", location="", language="en", base_url=_BASE
        )

    assert text is None


def test_fetch_web_research_returns_none_when_message_empty():
    with requests_mock.Mocker() as m:
        m.get(f"{_BASE}/api/providers", json=_providers_response())
        m.post(f"{_BASE}/api/search", json={"message": "  ", "sources": []})
        text = perplexica.fetch_web_research(
            place_name="X", location="", language="en", base_url=_BASE
        )

    assert text is None
