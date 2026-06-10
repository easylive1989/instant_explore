"""Perplexica (AI web-search engine) source provider — DEMO / SPIKE.

Perplexica is a self-hosted "AI answering engine": it runs a SearxNG
meta-search, retrieves web pages, and has its own LLM synthesise a cited
answer. We use it here to *augment* (never replace) the Wikipedia +
Wikidata source bundle for on-demand narration, so the story writer has
extra material for places where Wikipedia is thin.

Flow (new Perplexica / "Vane" API):
  1. GET  {base}/api/providers → discover a usable chat + embedding
     provider (providerId UUID + a model key). The search endpoint
     requires these by reference, so we resolve them at call time
     instead of hard-coding UUIDs.
  2. POST {base}/api/search with `sources:["web"]`, `stream:false` →
     returns `{message, sources:[{metadata:{title,url}, content}]}`.
  3. Format `message` + the source citations into a single plaintext
     block suitable for the story prompt.

Returns None (never raises) on any failure — graceful degrade, mirroring
`sources/wikipedia.py`. The caller treats a missing Perplexica extract
the same as any other provider that failed.

This is a spike to evaluate the effect; it is intentionally not wired
into the production `pipeline.py` yet.
"""
from __future__ import annotations

import logging
import os
from typing import Any

import requests

logger = logging.getLogger(__name__)

USER_AGENT = (
    "lorescape-backend/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)
_DEFAULT_BASE_URL = "http://localhost:3000"
_TIMEOUT = 90  # Perplexica does web search + LLM synthesis; allow headroom.
_MAX_SOURCES_LISTED = 8


def default_base_url() -> str:
    """Perplexica base URL from PERPLEXICA_URL, defaulting to localhost:3000."""
    return os.environ.get("PERPLEXICA_URL") or _DEFAULT_BASE_URL


def fetch_web_research(
    *,
    place_name: str,
    location: str,
    language: str,
    base_url: str | None = None,
    timeout: int = _TIMEOUT,
) -> str | None:
    """Query Perplexica for web research about a place; return a text block.

    `language` is the request locale (e.g. ``"zh-TW"``) — used only to
    phrase the query; Perplexica decides the answer language from it.
    Returns None on any error or when no usable provider is configured.
    """
    base = (base_url or default_base_url()).rstrip("/")

    models = _resolve_models(base, timeout)
    if models is None:
        return None
    chat_model, embedding_model = models

    query = _build_query(place_name=place_name, location=location, language=language)
    payload = {
        "chatModel": chat_model,
        "embeddingModel": embedding_model,
        "sources": ["web"],
        "query": query,
        # "speed" runs the lightest chain (fewer LLM round-trips) — less
        # exposure to free-tier 503/rate-limit and structured-output quirks.
        "optimizationMode": "speed",
        "stream": False,
    }

    try:
        response = requests.post(
            f"{base}/api/search",
            json=payload,
            headers={"User-Agent": USER_AGENT, "Content-Type": "application/json"},
            timeout=timeout,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        logger.warning(
            "sources.perplexica.search_failed",
            extra={"place_name": place_name, "err": str(exc)},
        )
        return None

    try:
        data = response.json()
    except ValueError as exc:
        logger.warning(
            "sources.perplexica.bad_json",
            extra={"place_name": place_name, "err": str(exc)},
        )
        return None

    return _format_research(data)


def _build_query(*, place_name: str, location: str, language: str) -> str:
    """Phrase a research query in the request language."""
    where = f"（{location}）" if location else ""
    if language.startswith("zh"):
        return f"{place_name}{where} 的歷史、相關的著名人物、重要事件與傳說"
    where_en = f" ({location})" if location else ""
    return (
        f"History of {place_name}{where_en}: notable people, key events, "
        "and legends associated with it."
    )


def _resolve_models(
    base: str, timeout: int
) -> tuple[dict[str, str], dict[str, str]] | None:
    """Discover a chat + embedding model reference from /api/providers.

    Returns ``(chat_model, embedding_model)`` where each is a dict
    ``{"providerId": ..., "key": ...}``, or None when nothing usable is
    configured / reachable.
    """
    try:
        response = requests.get(
            f"{base}/api/providers",
            headers={"User-Agent": USER_AGENT},
            timeout=timeout,
        )
        response.raise_for_status()
        data = response.json()
    except (requests.RequestException, ValueError) as exc:
        logger.warning("sources.perplexica.providers_failed", extra={"err": str(exc)})
        return None

    chat = _pick_model(data, kind="chat")
    embedding = _pick_model(data, kind="embedding")
    if chat is None or embedding is None:
        logger.warning(
            "sources.perplexica.no_usable_provider",
            extra={"has_chat": chat is not None, "has_embedding": embedding is not None},
        )
        return None
    return chat, embedding


# Perplexica's internal chains ask the chat model for structured JSON.
# Reasoning/agentic models emit <think> blocks or chatty preambles that
# break that parsing, and "auto" routing may land on one. Prefer clean
# instruction-following models and skip the known offenders.
_CHAT_AVOID = ("auto", "oss", "qwen", "compound", "glm", "safeguard", "thinking")
# Gemini/GPT honour strict structured-output best; put them first because
# Perplexica's generateObject step does a strict JSON.parse that free
# models (trailing commas, <think> blocks) routinely fail.
_CHAT_PREFER = (
    "gemini-2.5-flash",
    "gpt-4",
    "llama-3.3-70b",
    "llama-4",
    "gemma",
)


def _pick_model(data: Any, *, kind: str) -> dict[str, str] | None:
    """Pull a usable ``{providerId, key}`` of the given kind.

    The /api/providers payload looks like::

        {"providers": [
            {"id": "<uuid>", "name": "...",
             "chatModels": [{"name": "...", "key": "..."}],
             "embeddingModels": [{"name": "...", "key": "..."}]}
        ]}

    For embeddings we take the first available model. For chat we rank by
    `_CHAT_PREFER` and skip `_CHAT_AVOID` so Perplexica's JSON-structured
    chains get a model that actually returns clean JSON.
    """
    model_field = "chatModels" if kind == "chat" else "embeddingModels"
    candidates: list[dict[str, str]] = []
    for provider in _providers_for_kind(data, kind):
        provider_id = (
            provider.get("id")
            or provider.get("providerId")
            or provider.get("uuid")
        )
        models = provider.get(model_field) or provider.get("models") or []
        if not provider_id or not isinstance(models, list):
            continue
        for model in models:
            key = (
                (model.get("key") or model.get("name") or model.get("id"))
                if isinstance(model, dict)
                else model
            )
            if key:
                candidates.append({"providerId": str(provider_id), "key": str(key)})

    if not candidates:
        return None
    if kind != "chat":
        return candidates[0]
    return _rank_chat_candidates(candidates)


def _rank_chat_candidates(
    candidates: list[dict[str, str]],
) -> dict[str, str] | None:
    """Choose the cleanest chat model from candidates (see `_CHAT_PREFER`)."""
    safe = [c for c in candidates if not _is_avoided_chat(c["key"])]
    for wanted in _CHAT_PREFER:
        for c in safe:
            if wanted in c["key"].lower():
                return c
    if safe:
        return safe[0]
    return candidates[0]  # everything was "avoided"; better than nothing


def _is_avoided_chat(key: str) -> bool:
    lowered = key.lower()
    return any(bad in lowered for bad in _CHAT_AVOID)


def _providers_for_kind(data: Any, kind: str) -> list[dict]:
    """Normalise the /api/providers payload into a list of provider dicts."""
    if isinstance(data, list):
        return [p for p in data if isinstance(p, dict)]
    if isinstance(data, dict):
        legacy_key = (
            "chatModelProviders" if kind == "chat" else "embeddingModelProviders"
        )
        bucket = data.get("providers") or data.get(legacy_key) or []
        if isinstance(bucket, list):
            return [p for p in bucket if isinstance(p, dict)]
        if isinstance(bucket, dict):
            return [p for p in bucket.values() if isinstance(p, dict)]
    return []


def _format_research(data: Any) -> str | None:
    """Turn a /api/search response into a plaintext research block."""
    if not isinstance(data, dict):
        return None
    message = data.get("message")
    if not isinstance(message, str) or not message.strip():
        return None

    lines = [message.strip()]

    sources = data.get("sources")
    if isinstance(sources, list) and sources:
        citations: list[str] = []
        for src in sources[:_MAX_SOURCES_LISTED]:
            if not isinstance(src, dict):
                continue
            meta = src.get("metadata") or {}
            title = meta.get("title") or src.get("title") or "(untitled)"
            url = meta.get("url") or src.get("url") or ""
            citations.append(f"- {title} {url}".rstrip())
        if citations:
            lines.append("")
            lines.append("Sources:")
            lines.extend(citations)

    return "\n".join(lines)
