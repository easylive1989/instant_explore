"""Gemini API wrapper using google-genai SDK with structured JSON output."""
from __future__ import annotations

import json
from dataclasses import dataclass

from google import genai
from google.genai import types

GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_TEMPERATURE = 0.3


@dataclass(frozen=True)
class GeneratedStory:
    """Structured output from the Gemini story generation call."""

    place_name: str
    place_location: str
    era: str
    story: str


def generate_story(
    *,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: dict,
) -> GeneratedStory:
    """Call Gemini and parse the JSON response into a GeneratedStory.

    Uses structured JSON output mode so the response is always valid JSON
    matching the provided schema.
    """
    client = genai.Client(api_key=api_key)

    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=GEMINI_TEMPERATURE,
        response_mime_type="application/json",
        response_schema=response_schema,
    )

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[user_prompt],
        config=config,
    )

    data = json.loads(response.text)
    return GeneratedStory(
        place_name=data["place_name"],
        place_location=data["place_location"],
        era=data["era"],
        story=data["story"],
    )
