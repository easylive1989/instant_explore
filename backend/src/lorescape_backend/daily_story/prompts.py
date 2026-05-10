"""Gemini prompt + structured-output schema for daily story generation.

Goal: produce vivid, narrative-rich historical stories grounded strictly in
the provided Wikipedia extract — concrete moments, named figures, dated
events, in the style of a popular history book — while minimising
hallucination.
"""
from __future__ import annotations


SYSTEM_INSTRUCTION = (
    "You are a historian and storyteller. Write a vivid, narrative-rich "
    "historical short story about a famous landmark, based STRICTLY on the "
    "Wikipedia content provided. Do NOT introduce any historical facts, names, "
    "or events that do not appear in the source material. If the source is "
    "insufficient for a specific claim, omit it rather than invent. Strive for "
    "the dramatic, multi-paragraph storytelling style of a popular history "
    "book — open with a concrete scene, name real historical figures, cite "
    "specific dates, and use evocative imagery drawn from the source."
)


# JSON schema for Gemini structured output.
# Uses uppercase types per google-genai schema conventions.
GEMINI_RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "place_name": {"type": "STRING"},
        "place_location": {"type": "STRING"},
        "era": {"type": "STRING"},
        "story": {"type": "STRING"},
    },
    "required": ["place_name", "place_location", "era", "story"],
}


_LANGUAGE_NAMES = {
    "zh-TW": "Traditional Chinese (zh-TW)",
    "en": "English (en)",
}


def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair."""
    language_name = _LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    return (
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):\n'
        f"<<<\n{wikipedia_extract}\n>>>\n\n"
        f"Write a 700-1200 character true historical short story in {language_name}.\n"
        "\n"
        "Style:\n"
        "- Multiple short paragraphs, each centred on a specific moment, "
        "person, or turning point.\n"
        "- Open with a concrete scene — a dated event, a person acting in a "
        'place — not a textbook summary like "X is a landmark in Y".\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years or eras (e.g. '1492', '70-80 CE', '明朝') "
        "when stating events.\n"
        "- Reference real named people from the source (rulers, architects, "
        "chroniclers, generals, etc).\n"
        "- Close with one short reflective line about the landmark's enduring "
        "significance.\n"
        "- Do NOT end the story with a redundant 'place name, location, era' "
        "summary — those values are returned as separate fields below.\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- story: the 700-1200 character narrative\n"
    )
