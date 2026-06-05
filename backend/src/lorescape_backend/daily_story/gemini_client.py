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
    """Structured output from the Gemini story generation call.

    `paragraphs` holds the long-form (3 × 200-300 zh chars / 80-130 en
    words) story for App display and TTS. `card_paragraphs` holds the
    same story compressed to the Instagram card layout (3 × 60-100
    chars/words).
    """

    place_name: str
    place_location: str
    era: str
    hashtags: tuple[str, ...]
    paragraphs: tuple[str, ...]
    card_title: str
    card_title_sub: str
    card_paragraphs: tuple[str, ...]
    card_pull_quote: str
    card_pull_quote_attrib: str
    card_anno_roman: str


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
        hashtags=tuple(data["hashtags"]),
        paragraphs=tuple(data["paragraphs"]),
        card_title=data["card_title"],
        card_title_sub=data["card_title_sub"],
        card_paragraphs=tuple(data["card_paragraphs"]),
        card_pull_quote=data["card_pull_quote"],
        card_pull_quote_attrib=data["card_pull_quote_attrib"],
        card_anno_roman=data["card_anno_roman"],
    )
