"""Gemini prompt + structured-output schema for daily story generation.

Goal: minimise hallucination by forcing the model to ground its output
strictly in the provided Wikipedia extract.
"""
from __future__ import annotations


SYSTEM_INSTRUCTION = (
    "You are a historian. You will write a true historical short story about a "
    "famous landmark, based STRICTLY on the Wikipedia content provided. "
    "Do NOT introduce any historical facts, names, or events that do not "
    "appear in the source material. If the source is insufficient for a "
    "specific claim, omit it rather than invent."
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
        f"Write a 300-500 character true historical story in {language_name}.\n"
        "Requirements:\n"
        '- Include at least one specific year or era (e.g., "70-80 CE")\n'
        "- Include at least one real historical figure named in the source\n"
        "- Describe one concrete historical event from the source\n"
        "- End with the place name, location, and approximate era\n\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name\n"
        "- place_location: localized location (e.g., country/city)\n"
        "- era: approximate era of the story\n"
        "- story: the 300-500 char story body\n"
    )
