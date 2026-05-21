"""Gemini API wrapper using google-genai SDK with structured JSON output."""
from __future__ import annotations

import json
from dataclasses import dataclass

from google import genai
from google.genai import types

GEMINI_MODEL = "gemini-2.5-pro"
GEMINI_TEMPERATURE = 0.3


@dataclass(frozen=True)
class GeneratedStory:
    """Structured output from the Gemini story generation call.

    Card fields are populated only on the zh-TW path; en leaves them None.
    For zh-TW, `story` is also None — the writer derives it by joining
    `card_paragraphs_ch`.
    """

    place_name: str
    place_location: str
    era: str
    story: str | None
    threads_summary: str
    hashtags: tuple[str, ...]
    card_title_ch: str | None = None
    card_title_sub_ch: str | None = None
    card_paragraphs_ch: tuple[str, ...] | None = None
    card_pull_quote_ch: str | None = None
    card_pull_quote_attrib_ch: str | None = None
    card_anno_roman: str | None = None


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
    paragraphs = data.get("card_paragraphs_ch")
    return GeneratedStory(
        place_name=data["place_name"],
        place_location=data["place_location"],
        era=data["era"],
        story=data.get("story"),
        threads_summary=data["threads_summary"],
        hashtags=tuple(data["hashtags"]),
        card_title_ch=data.get("card_title_ch"),
        card_title_sub_ch=data.get("card_title_sub_ch"),
        card_paragraphs_ch=tuple(paragraphs) if paragraphs is not None else None,
        card_pull_quote_ch=data.get("card_pull_quote_ch"),
        card_pull_quote_attrib_ch=data.get("card_pull_quote_attrib_ch"),
        card_anno_roman=data.get("card_anno_roman"),
    )
