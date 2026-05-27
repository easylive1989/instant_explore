"""Gemini wrapper for on-demand narration (uses flash for latency)."""
from __future__ import annotations

import json
from typing import Any

from google import genai
from google.genai import types

NARRATION_MODEL = "gemini-3.5-flash"
NARRATION_TEMPERATURE = 0.3


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

    response = client.models.generate_content(
        model=NARRATION_MODEL,
        contents=[user_prompt],
        config=config,
    )

    return json.loads(response.text)
