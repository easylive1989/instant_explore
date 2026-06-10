"""Gemini wrapper for on-demand narration (uses flash for latency).

Two generation modes:

- `generate_structured` — plain call with `response_schema`; the API
  guarantees valid JSON. Used by the legacy (no web search) path and as
  the repair step of the grounded path.
- `generate_grounded` — call with the Google Search grounding tool so
  the model researches the place on the live web while writing. The
  API rejects combining tools with `response_schema` (400), so JSON is
  requested via the prompt instead and validated here; when parsing
  fails, one schema-enforced repair call (without tools) reformats the
  text. Empirically the repair path is rarely needed.
"""
from __future__ import annotations

import json
import logging
import re
import time
from typing import Any

from google import genai
from google.genai import errors as genai_errors
from google.genai import types

logger = logging.getLogger(__name__)

NARRATION_MODEL = "gemini-2.5-flash"
NARRATION_TEMPERATURE = 0.3

_CODE_FENCE_RE = re.compile(r"^```(?:json)?\s*|\s*```$")

# Grounded calls hit Google-side "high demand" 503 spikes noticeably more
# often than plain calls; a short retry keeps those transient blips from
# surfacing as user-facing 500s.
_GROUNDED_RETRY_DELAYS = (3, 8)


def generate_structured(
    *,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: dict,
) -> dict[str, Any]:
    """Call Gemini in structured-JSON mode and return the parsed payload."""
    client = genai.Client(api_key=api_key)

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=NARRATION_TEMPERATURE,
        response_mime_type="application/json",
        response_schema=response_schema,
    )

    response = _generate_with_503_retry(
        client, user_prompt=user_prompt, config=config,
    )

    return json.loads(response.text)


def generate_grounded(
    *,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: dict,
) -> dict[str, Any]:
    """Call Gemini with Google Search grounding and return parsed JSON.

    `response_schema` is NOT sent with the grounded call (the API rejects
    tools + schema together); it is only used by the repair call when the
    prompt-constrained JSON fails to parse. The user prompt must therefore
    describe the expected JSON shape explicitly.
    """
    client = genai.Client(api_key=api_key)

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=NARRATION_TEMPERATURE,
        tools=[types.Tool(google_search=types.GoogleSearch())],
    )

    response = _generate_with_503_retry(
        client, user_prompt=user_prompt, config=config,
    )
    _log_grounding_evidence(response)

    raw = (response.text or "").strip()
    if not raw:
        raise RuntimeError("Gemini grounded call returned an empty response")

    parsed = _parse_json_text(raw)
    if parsed is not None:
        return parsed

    logger.warning(
        "narration.grounded_json_repair", extra={"raw_chars": len(raw)},
    )
    return generate_structured(
        api_key=api_key,
        system_instruction=(
            "Convert the user's content into JSON matching the response "
            "schema. Preserve the content exactly; do NOT add, remove, or "
            "invent any information."
        ),
        user_prompt=raw,
        response_schema=response_schema,
    )


def _generate_with_503_retry(
    client: Any, *, user_prompt: str, config: Any
) -> Any:
    """generate_content with short backoff on Google-side 5xx errors."""
    for attempt, delay in enumerate((*_GROUNDED_RETRY_DELAYS, None)):
        try:
            return client.models.generate_content(
                model=NARRATION_MODEL,
                contents=[user_prompt],
                config=config,
            )
        except genai_errors.ServerError as exc:
            if delay is None:
                raise
            logger.warning(
                "narration.grounded_5xx_retry",
                extra={"attempt": attempt + 1, "delay_s": delay,
                       "err": str(exc)[:120]},
            )
            time.sleep(delay)
    raise AssertionError("unreachable")


def _parse_json_text(text: str) -> dict[str, Any] | None:
    """Parse model text as a JSON object; tolerate markdown code fences."""
    cleaned = _CODE_FENCE_RE.sub("", text.strip()).strip()
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def _log_grounding_evidence(response: Any) -> None:
    """Log how many web queries/sources the model actually used."""
    try:
        metadata = response.candidates[0].grounding_metadata
        queries = len(list(getattr(metadata, "web_search_queries", None) or []))
        sources = len(list(getattr(metadata, "grounding_chunks", None) or []))
    except (AttributeError, IndexError, TypeError):
        queries, sources = 0, 0
    logger.info(
        "narration.grounded",
        extra={"web_queries": queries, "web_sources": sources},
    )
