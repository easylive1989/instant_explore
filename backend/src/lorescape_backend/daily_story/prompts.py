"""Gemini prompt + structured-output schema for daily story generation.

The story spine + fact-boundary rules live in
`lorescape_backend.shared.story_prompt`. This module composes those
core rules with daily-story-specific output requirements (IG card,
Threads summary, hashtags).

Output contract:
- `paragraphs`: long-form 3-paragraph story (200-300 zh chars / 80-130
  en words per paragraph) used for the App's narration view and TTS.
- `card_paragraphs`: short 3-paragraph version (60-100 chars per
  paragraph) sized for the Instagram card layout.
"""
from __future__ import annotations

from lorescape_backend.shared.story_prompt import (
    LANGUAGE_NAMES,
    build_story_system_instruction,
    build_story_user_prompt,
)


# Public re-export so callers (`job.py`) keep a stable import surface.
def SYSTEM_INSTRUCTION_FOR(language: str) -> str:
    return build_story_system_instruction(language)


# Backwards-compatible single-language constant (zh-TW). Existing callers
# that hard-coded `prompts.SYSTEM_INSTRUCTION` get the zh-TW skeleton.
SYSTEM_INSTRUCTION = build_story_system_instruction("zh-TW")


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

_STORY_PROPERTIES: dict = {
    # Long-form narration body — the "real story" Surface used in the App.
    "paragraphs": {
        "type": "ARRAY",
        "items": {"type": "STRING"},
        "minItems": 3,
        "maxItems": 3,
    },
}

_STORY_REQUIRED = ["paragraphs"]

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
    """Return the Gemini structured-output schema for the given language."""
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    return {
        "type": "OBJECT",
        "properties": {
            **_BASE_PROPERTIES,
            **_STORY_PROPERTIES,
            **_CARD_PROPERTIES,
        },
        "required": _BASE_REQUIRED + _STORY_REQUIRED + _CARD_REQUIRED,
    }


def build_user_prompt(
    *, wikipedia_title: str, wikipedia_extract: str, language: str
) -> str:
    """Build the user-facing prompt for one (place, language) pair.

    The `place_name`/`location` upstream are equivalent to the wiki title
    on the daily-story path — we don't have a localized name yet at this
    point, so we pass the title for both.
    """
    if language not in LANGUAGE_NAMES:
        raise KeyError(f"Unknown language: {language!r}")
    base = build_story_user_prompt(
        place_name=wikipedia_title,
        location=wikipedia_title,
        wikipedia_title=wikipedia_title,
        wikipedia_extract=wikipedia_extract,
        hook=None,
    )
    if language == "zh-TW":
        return base + "\n\n" + _zh_tw_output_spec()
    return base + "\n\n" + _en_output_spec()


def _en_output_spec() -> str:
    return (
        "OUTPUT FIELDS:\n"
        "- paragraphs: the long-form story as a JSON array of exactly 3 "
        "strings. Each paragraph is 80-130 English words. This is the "
        "main story (setup / development / resolution).\n"
        "- card_paragraphs: a SHORT version of the same story for the "
        "Instagram card layout: exactly 3 strings, 60-100 English words "
        "each. Same story arc as `paragraphs`, just compressed. The "
        "first character must be a concrete noun or proper name (it "
        "will be rendered as a large drop-cap); avoid starting with "
        '"The", "A", "An", "In", "On", "At", "It", "This", "That".\n'
        "- threads_summary: a punchier 300-400 character version of the "
        "story ending on a hook or open question. Total must fit under "
        "500 characters — it will be posted as a single Threads post.\n"
        "- hashtags: 3-5 lowerCamelCase ASCII tags (no '#' prefix) drawn "
        "from the country, era, and theme.\n"
        "- card_title: a punchy English main title capturing the central "
        "tension (≤ 28 characters, must NOT just repeat the place name).\n"
        "- card_title_sub: a subtitle complementing the main title "
        "(≤ 50 characters).\n"
        "- card_pull_quote: one short, dramatic quote from the story, "
        'wrapped in straight double quotes "...". Prefer real quotes '
        "from the source over invented lines.\n"
        "- card_pull_quote_attrib: attribution for the pull quote, "
        "beginning with an em-dash —. Example: — Suetonius, 121 CE.\n"
        "- card_anno_roman: the representative year of the story as "
        "Roman numerals (example: 1889 → MDCCCLXXXIX). If the story "
        "spans a range, pick one representative year.\n"
        "- place_name: localized place name only (no extras).\n"
        "- place_location: localized location (e.g. country/city).\n"
        "- era: the era your story takes place in."
    )


def _zh_tw_output_spec() -> str:
    return (
        "OUTPUT FIELDS:\n"
        "- paragraphs: 長版故事，JSON 陣列剛好 3 段字串，每段 200-300 "
        "繁體中文字（起 / 承 / 合）。這是 App 內顯示與朗讀用的主要"
        "故事。\n"
        "- card_paragraphs: 同一個故事的「短版」，供 Instagram 卡片排"
        "版使用：剛好 3 段字串，每段 60-100 繁體中文字。故事弧線與 "
        "`paragraphs` 相同，只是壓縮。第一個字必須是具體名詞或人名"
        "（會被放大成 drop-cap），避免以「在」「當」「這」「那」"
        "等虛詞開頭。\n"
        "- threads_summary: 同一故事的 300-400 字精簡版本，以鉤子或"
        "開放問題收尾。整體長度需在 500 字以內，將以單則 Threads "
        "貼文發出。\n"
        "- hashtags: 3-5 個 lowerCamelCase ASCII 標籤（不含 '#'），"
        "取自國家、時代、主題。\n"
        "- card_title: 精煉的繁體中文主標，抓住故事的核心張力"
        "（≤ 14 字，不可只重複地名）。\n"
        "- card_title_sub: 副標，與主標互補（≤ 20 字，可用全形"
        "引號「」）。\n"
        "- card_pull_quote: 故事中一句短而戲劇性的引述，以全形"
        "引號「」或『』包裹。優先使用源文真實引述，而非自創。\n"
        "- card_pull_quote_attrib: 引述出處，以全形 em-dash ── 開頭，"
        "年份用漢字（範例：── 莫泊桑，一八八九）。\n"
        "- card_anno_roman: 故事代表年份的羅馬數字"
        "（範例：1889 → MDCCCLXXXIX）。跨年度故事擇一代表年。\n"
        "- place_name: 在地化的地名（不含其他）。\n"
        "- place_location: 在地化的位置（如國家/城市）。\n"
        "- era: 故事發生的時代。"
    )
