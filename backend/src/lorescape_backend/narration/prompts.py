"""Prompt builders and JSON schemas for on-demand narration.

Two paths share the same story-quality skeleton from
`lorescape_backend.shared.story_prompt`:

- `/narration/hooks` returns 2-3 narrative angles for the user to pick.
- `/narration` returns the long-form 3-paragraph story.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from lorescape_backend.sources.models import SourceBundle

from lorescape_backend.shared.story_prompt import (
    LANGUAGE_NAMES,
    StoryHook,
    build_story_system_instruction,
    build_story_user_prompt,
)


# ---------------------------------------------------------------------------
# /narration  (long-form story)
# ---------------------------------------------------------------------------


_NARRATION_PROPERTIES: dict = {
    "place_name":          {"type": "STRING"},
    "place_location":      {"type": "STRING"},
    "era":                 {"type": "STRING"},
    "paragraphs": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
    "pull_quote":          {"type": "STRING"},
    "insufficient_source": {"type": "BOOLEAN"},
}

_NARRATION_REQUIRED = [
    "place_name", "place_location", "era",
    "paragraphs", "pull_quote", "insufficient_source",
]


def narration_system_instruction(
    language: str, *, web_search: bool = False
) -> str:
    """The shared story-spine skeleton (reused verbatim)."""
    return build_story_system_instruction(language, web_search=web_search)


def narration_response_schema(language: str) -> dict:
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": _NARRATION_PROPERTIES,
        "required": _NARRATION_REQUIRED,
    }


# Grounded calls cannot use response_schema (API rejects tools + schema
# together), so the exact JSON shape must be spelled out in the prompt.
_NARRATION_JSON_SHAPE = (
    "OUTPUT FORMAT (STRICT): your entire reply MUST be exactly one JSON "
    "object — no markdown fence, no text before or after it:\n"
    '{"place_name": "...", "place_location": "...", "era": "...", '
    '"paragraphs": ["...", "...", "..."], "pull_quote": "...", '
    '"insufficient_source": false}'
)

_HOOKS_JSON_SHAPE = (
    "OUTPUT FORMAT (STRICT): your entire reply MUST be exactly one JSON "
    "object — no markdown fence, no text before or after it:\n"
    '{"hooks": [{"id": "...", "title": "...", "teaser": "..."}], '
    '"insufficient_source": false}'
)


def build_narration_user_prompt(
    *,
    place_name: str,
    location: str,
    source_bundle: "SourceBundle",
    language: str,
    hook: StoryHook | None = None,
    web_search: bool = False,
) -> str:
    """Story user prompt + narration-specific output spec tail."""
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    base = build_story_user_prompt(
        place_name=place_name, location=location,
        source_bundle=source_bundle, hook=hook,
    )
    tail = _zh_tw_output_spec() if language == "zh-TW" else _en_output_spec()
    prompt = base + "\n\n" + tail
    if web_search:
        prompt += "\n\n" + _NARRATION_JSON_SHAPE
    return prompt


def _en_output_spec() -> str:
    return (
        "OUTPUT FIELDS:\n"
        "- paragraphs: long-form story as a JSON array of exactly 3 "
        "strings, each 80-130 English words (setup / development / "
        "resolution).\n"
        "- pull_quote: one short, dramatic line from the story, wrapped "
        'in straight double quotes "...". Prefer real quotes from the '
        "source over invented lines. Empty string if none.\n"
        "- place_name: localized place name.\n"
        "- place_location: localized location (country / city).\n"
        "- era: the era your story takes place in.\n"
        "- insufficient_source: true when the provided sources are too "
        "thin to support the story-spine constraints. When true, leave "
        "`paragraphs` as an empty JSON array."
    )


def _zh_tw_output_spec() -> str:
    return (
        "OUTPUT FIELDS:\n"
        "- paragraphs: 長版故事，JSON 陣列剛好 3 段字串，每段 200-300 "
        "繁體中文字（起 / 承 / 合）。\n"
        "- pull_quote: 故事中一句短而戲劇性的引述，以全形引號「」或"
        "『』包裹。優先使用源文真實引述，沒有適合的就回傳空字串。\n"
        "- place_name: 在地化的地名。\n"
        "- place_location: 在地化的位置（國家／城市）。\n"
        "- era: 故事發生的時代。\n"
        "- insufficient_source: 當提供的來源內容不足以撐起故事骨架時"
        "回傳 true，此時 `paragraphs` 留空陣列。"
    )


# ---------------------------------------------------------------------------
# /narration/hooks  (2-3 narrative angles)
# ---------------------------------------------------------------------------


_HOOK_ITEM_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "id":     {"type": "STRING"},
        "title":  {"type": "STRING"},
        "teaser": {"type": "STRING"},
    },
    "required": ["id", "title", "teaser"],
}

_HOOKS_PROPERTIES: dict = {
    "hooks": {
        "type": "ARRAY",
        "items": _HOOK_ITEM_SCHEMA,
        "minItems": 0,
        "maxItems": 3,
    },
    "insufficient_source": {"type": "BOOLEAN"},
}

_HOOKS_REQUIRED = ["hooks", "insufficient_source"]


def hooks_system_instruction(
    language: str, *, web_search: bool = False
) -> str:
    """A standalone system instruction for the hook-discovery call.

    The hook task is more like research than storytelling, so we don't
    reuse the full story-spine prompt. We DO inherit the fact-boundary
    rule so the LLM doesn't invent angles unsupported by the source.
    With `web_search=True` angles may also be grounded in the model's
    own Google Search results.
    """
    language_name = LANGUAGE_NAMES[language]
    if language == "zh-TW":
        examples = (
            "範例（僅供風格參考，並非每個地方都套用）：\n"
            '- {"id":"van-gogh-1888","title":"梵谷的黃色小屋",'
            '"teaser":"他在亞爾留下的 444 天，最後以瘋狂收場"}\n'
            '- {"id":"colosseum-vespasian","title":"皇帝的血腥豪賭",'
            '"teaser":"維斯帕先用戰利品蓋了一座娛樂帝國的劇場"}'
        )
        constraint_hint = (
            "- title 限 6-14 個繁體中文字。\n"
            "- teaser 限 40 字以內，必須留下懸念。"
        )
    else:
        examples = (
            "Example shape (style reference only, do not blindly reuse):\n"
            '- {"id":"van-gogh-1888","title":"Yellow House Dream",'
            '"teaser":"444 days in Arles that ended in madness"}\n'
            '- {"id":"colosseum-vespasian","title":"The Emperor\'s Wager",'
            '"teaser":"Built with the spoils of Jerusalem to buy a city\'s love"}'
        )
        constraint_hint = (
            "- title is 4-8 words, max ~28 chars.\n"
            "- teaser is a one-sentence cliffhanger, max 60 chars."
        )

    if web_search:
        research_clause = (
            "Given the source materials below AND your own research "
            "with the google_search tool, surface 2-3 DISTINCT "
            "narrative angles a storyteller could develop — each "
            "grounded in a real named person or recorded event found "
            "in the materials or in credible search results.\n"
        )
        boundary_clause = (
            "FACT BOUNDARY (absolute): every angle must be grounded in "
            "the supplied materials or your web search results from "
            "credible pages; do NOT invent. The supplied "
            "Wikipedia/Wikidata materials are authoritative anchors. "
            "If you cannot ground 2 distinct angles, return an empty "
            "`hooks` array and set `insufficient_source` to true.\n"
        )
    else:
        research_clause = (
            "Given the Wikipedia extract below, surface 2-3 DISTINCT "
            "narrative angles a storyteller could develop — each "
            "grounded in a real named person or recorded event in the "
            "source.\n"
        )
        boundary_clause = (
            "FACT BOUNDARY (absolute): do NOT propose angles that "
            "require facts outside the source. If the source supports "
            "fewer than 2 distinct angles, return an empty `hooks` "
            "array and set `insufficient_source` to true.\n"
        )

    return (
        "You are a historical researcher. "
        f"{research_clause}"
        "\n"
        f"{boundary_clause}"
        "\n"
        f"OUTPUT LANGUAGE: {language_name}.\n"
        f"{constraint_hint}\n"
        "- Angles must be substantially different (not the same event "
        "in different words).\n"
        "- `id` is a short, ASCII, lowercase-with-dashes slug.\n"
        "\n"
        f"{examples}"
    )


def hooks_response_schema(language: str) -> dict:
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": _HOOKS_PROPERTIES,
        "required": _HOOKS_REQUIRED,
    }


def build_hooks_user_prompt(
    *,
    place_name: str,
    location: str,
    source_bundle: "SourceBundle",
    web_search: bool = False,
) -> str:
    prompt = build_story_user_prompt(
        place_name=place_name, location=location,
        source_bundle=source_bundle, hook=None,
    )
    if web_search:
        prompt += "\n\n" + _HOOKS_JSON_SHAPE
    return prompt
