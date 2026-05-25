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


_LANGUAGE_NAMES = {
    "zh-TW": "Traditional Chinese (zh-TW)",
    "en": "English (en)",
}


_BASE_PROPERTIES: dict = {
    "place_name": {"type": "STRING"},
    "place_location": {"type": "STRING"},
    "era": {"type": "STRING"},
    "threads_summary": {"type": "STRING"},
    "hashtags": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
    },
}

_BASE_REQUIRED = [
    "place_name", "place_location", "era",
    "threads_summary", "hashtags",
]

_CARD_PROPERTIES: dict = {
    "card_title":              {"type": "STRING"},
    "card_title_sub":          {"type": "STRING"},
    "card_paragraphs": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
    "card_pull_quote":         {"type": "STRING"},
    "card_pull_quote_attrib":  {"type": "STRING"},
    "card_anno_roman":         {"type": "STRING"},
}

_CARD_REQUIRED = [
    "card_title", "card_title_sub", "card_paragraphs",
    "card_pull_quote", "card_pull_quote_attrib", "card_anno_roman",
]


def build_response_schema(language: str) -> dict:
    """Return the Gemini structured-output schema for the given language.

    Both languages produce the base fields PLUS the card_* fields. The
    legacy `story` text column is derived by the writer from
    `card_paragraphs`.
    """
    if language not in _LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": {**_BASE_PROPERTIES, **_CARD_PROPERTIES},
        "required": _BASE_REQUIRED + _CARD_REQUIRED,
    }


def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair."""
    language_name = _LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    intro = (
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):\n'
        f"<<<\n{wikipedia_extract}\n>>>\n\n"
    )
    if language == "zh-TW":
        return intro + _zh_tw_body(language_name)
    return intro + _en_body(language_name)


def _en_body(language_name: str) -> str:
    return (
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
        f"Also produce a punchier 300-400 character version of the same story "
        f"in {language_name}, ending on a hook or open question rather than "
        "wrapping up neatly. This shorter version must fit comfortably under "
        "500 characters total — it will be posted as a single Threads post.\n"
        "\n"
        "Also produce 3-5 hashtags drawn from the country, era, and theme "
        "of this place. Each tag should be a single lowerCamelCase word "
        "without the '#' prefix, ASCII letters/digits only (so they work as "
        "hashtags on English-language social media regardless of the story "
        "language).\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- story: the 700-1200 character narrative\n"
        "- threads_summary: the 300-400 character punchier version\n"
        "- hashtags: array of 3-5 lowerCamelCase ASCII hashtag strings "
        "(no '#' prefix)\n"
    )


def _zh_tw_body(language_name: str) -> str:
    # Tailored for the IG card layout: 3 short paragraphs (drop-cap on first),
    # a pull quote, attribution, and a Roman-numeral year for the masthead.
    return (
        f"Write a true historical short story in {language_name}, structured as "
        "exactly 3 paragraphs of 60-100 Traditional Chinese characters each.\n"
        "\n"
        "Style:\n"
        "- Each paragraph centres on a specific moment, person, or turning point.\n"
        "- Open paragraph 1 with a concrete scene — a dated event, a real person "
        "acting in a real place. The first character should be a concrete noun "
        "or name (it will be rendered as a large drop-cap), not a function word "
        '(e.g. avoid starting with "在", "當", "這", "那").\n'
        "- Quote real historical lines or chronicler accounts ONLY if they "
        "appear in the source; otherwise paraphrase.\n"
        "- Cite specific years (use Han numerals for years in body text, "
        "e.g. 一八八九年) and reference real named people from the source.\n"
        "- Do NOT end with a redundant '地名, 地點, 年代' summary — those "
        "values are returned as separate fields below.\n"
        "\n"
        f"Also produce a punchier 300-400 character version of the same story "
        f"in {language_name} as `threads_summary`, ending on a hook or open "
        "question. This shorter version must fit under 500 characters total — "
        "it will be posted as a single Threads post.\n"
        "\n"
        "Also produce 3-5 hashtags drawn from the country, era, and theme. "
        "Each tag is a single lowerCamelCase word without the '#' prefix, "
        "ASCII letters/digits only.\n"
        "\n"
        "ADDITIONALLY, produce the following Instagram-card fields:\n"
        "- card_title_ch: a punchy Traditional Chinese main title that captures "
        "the central tension of the story (≤ 14 characters, must NOT just "
        "repeat the place name).\n"
        "- card_title_sub_ch: a subtitle that complements the main title "
        "(≤ 20 characters; full-width quotes 「」 allowed).\n"
        "- card_paragraphs_ch: the same 3 paragraphs above, returned as a "
        "JSON array of 3 strings (one paragraph per element, no leading/"
        "trailing whitespace).\n"
        "- card_pull_quote_ch: one short, dramatic quote from the story, "
        "wrapped in full-width Chinese quotation marks 「」 or 『』. Prefer "
        "real quotes from the source over invented lines.\n"
        "- card_pull_quote_attrib_ch: attribution for the pull quote, "
        "beginning with the full-width em-dash ──. Use Han numerals for "
        "years (example: ── 莫泊桑，一八八九).\n"
        "- card_anno_roman: the representative year of the story as Roman "
        "numerals (example: 1889 → MDCCCLXXXIX). If the story spans a range, "
        "pick one representative year.\n"
        "\n"
        "Output JSON with these fields:\n"
        "- place_name: localized place name only (no extras)\n"
        "- place_location: localized location (e.g. country/city)\n"
        "- era: the era your story takes place in\n"
        "- threads_summary: the 300-400 character punchier version\n"
        "- hashtags: array of 3-5 lowerCamelCase ASCII hashtag strings\n"
        "- card_title_ch, card_title_sub_ch, card_paragraphs_ch, "
        "card_pull_quote_ch, card_pull_quote_attrib_ch, card_anno_roman: "
        "as described above\n"
    )
