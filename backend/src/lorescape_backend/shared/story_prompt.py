"""Shared prompt skeleton for landmark stories.

Both `daily_story` (cron-driven IG/Threads post) and `narration`
(on-demand App experience) build their LLM prompts on top of this
skeleton so a single source of truth governs story quality.

Design goal: produce a *real story* — protagonist, motivation, conflict,
outcome — grounded strictly in the provided Wikipedia extract, not a
generic guidebook blurb.
"""
from __future__ import annotations

from dataclasses import dataclass


LANGUAGE_NAMES: dict[str, str] = {
    "zh-TW": "Traditional Chinese (zh-TW)",
    "en": "English (en)",
}


@dataclass(frozen=True)
class StoryHook:
    """A user-selected narrative angle (from /narration/hooks)."""

    title: str
    teaser: str


# Layered fallback: which kind of subject to anchor the story around when
# the obvious "famous person" angle does not exist for this place.
_FALLBACK_PRIORITY_EN = (
    "1. A named historical figure tied to this place (artist, ruler, "
    "writer, inventor, builder).\n"
    "2. A specific recorded event (battle, disaster, ceremony, "
    "discovery, decree).\n"
    "3. A local legend or folk tale — prefix the relevant sentences with "
    'something like "Legend has it..." or "According to local tradition...".\n'
    "4. The origin of the name itself, or the story of how the place came "
    "to be built or settled."
)

_FALLBACK_PRIORITY_ZH = (
    "1. 與此地有關的著名歷史人物（藝術家、統治者、作家、發明家、"
    "建造者）。\n"
    "2. 有記錄的具體事件（戰役、災難、典禮、發現、敕令）。\n"
    "3. 當地傳說或民間故事 —— 在相關句子前加上「相傳……」"
    "或「據說……」等標記。\n"
    "4. 地名由來，或這個地方是怎麼建立、被開拓的故事。"
)


# A single short positive example showing what "good" looks like. The
# LLM mimics tone/structure from examples much better than from rules.
_EXAMPLE_ZH = (
    "範例（不是輸出的一部分，僅供參考風格）：\n"
    "「一八八八年二月，文森·梵谷踏上亞爾的土地，這座普羅旺斯小城正"
    "下著雪。他剛從巴黎逃出來，厭倦了陰冷天氣與藝術圈的喧囂，渴望"
    "在南方找到他的「日本」—— 一個充滿陽光、麥田與顏色的烏托邦。"
    "他在城裡租下一棟外牆塗成亮黃色的小屋，腦中構想著一個宏大的"
    "計畫：把這裡變成「南方畫室」，邀請整個歐洲的前衛藝術家來此"
    "共同生活、共同創作。」"
)

_EXAMPLE_EN = (
    "Example (style reference only, not part of the output):\n"
    '"February 1888. Vincent van Gogh stepped off the train into Arles '
    "and found, to his astonishment, that the Provençal town was buried "
    "in snow. He had fled Paris exhausted — sick of the grey skies, the "
    "drinking, the quarrelsome circles of painters — and crossed France "
    "in search of what he called his 'Japan': a southern utopia of sun, "
    "wheatfields, and pure colour. He rented a small house on Place "
    "Lamartine, painted its façade a defiant yellow, and began writing "
    "to his friends in Paris with an audacious plan: he would turn this "
    "modest building into a Studio of the South, a commune where the "
    'avant-garde of Europe could live and paint together."'
)


def build_story_system_instruction(language: str) -> str:
    """System instruction enforcing the story-spine + fact constraint.

    The instruction is bilingual-aware: while the rule text is in
    English (so the model parses it reliably), it explicitly names the
    output language and embeds a language-appropriate positive example.
    """
    language_name = LANGUAGE_NAMES[language]  # KeyError on unknown — intentional
    if language == "zh-TW":
        example_block = _EXAMPLE_ZH
        fallback_block = _FALLBACK_PRIORITY_ZH
        language_rules = (
            "- Years in body text use Han numerals (e.g. 一八八八年).\n"
            "- Quotes use full-width Chinese marks 「」 or 『』.\n"
            "- Em-dash uses the full-width form ──."
        )
    else:
        example_block = _EXAMPLE_EN
        fallback_block = _FALLBACK_PRIORITY_EN
        language_rules = (
            "- Years use Arabic numerals (e.g. 1888).\n"
            '- Quotes use straight double quotes "...".\n'
            "- Em-dash uses the standard em-dash —."
        )

    return (
        "You are a historian and a storyteller. Your task is to write a "
        "true short story about a real landmark, grounded STRICTLY in "
        "the Wikipedia extract supplied by the user.\n"
        "\n"
        "FACT BOUNDARY (absolute):\n"
        "- Do NOT introduce any person, event, date, or quote that is not "
        "in the source material. If the source is silent on a detail, "
        "omit it rather than invent.\n"
        "- If the source is too thin to support a 3-paragraph story "
        "with a real protagonist or event, return the structured field "
        "`insufficient_source: true` and leave the story empty.\n"
        "- CRITICAL: do NOT write meta-narration about the absence of "
        "information (sentences like \"we do not know...\", \"there is "
        "no record of...\", \"the source does not say...\", \"細節在現有"
        "資料中並無記載\", \"等待被填補的空白\"). That is worse than returning "
        "nothing. If you catch yourself writing such sentences, STOP, "
        "discard the draft, set `insufficient_source: true`, and return "
        "an empty `paragraphs` array.\n"
        "\n"
        "STORY SPINE (every story MUST have these four beats):\n"
        "- PROTAGONIST: one named real person (artist, ruler, builder, "
        "writer, witness, chronicler...). Give their role and era.\n"
        "- MOTIVATION: what did they want here, and why did this place "
        "matter to them?\n"
        "- CONFLICT / TURN: what unexpected thing happened — an "
        "obstacle, betrayal, disaster, decision, revelation?\n"
        "- OUTCOME: how did it end, and what residue did it leave on "
        "this place?\n"
        "\n"
        "SUBJECT PRIORITY (layered fallback — use the highest tier the "
        "source can ground):\n"
        f"{fallback_block}\n"
        "\n"
        f"OUTPUT LANGUAGE: {language_name}.\n"
        f"{language_rules}\n"
        "\n"
        "OUTPUT FORMAT:\n"
        "- Plain prose, no markdown, no bullets, no headings.\n"
        "- Exactly 3 paragraphs (setup / development / resolution), "
        "separated by a single blank line.\n"
        "- Open paragraph 1 with a concrete scene — a dated moment, a "
        "real person in a real place — NOT a generic opener like "
        '"Welcome to..." or "Let me tell you about...".\n'
        "- Do NOT end with a redundant 'place name, location, era' "
        "summary; those values are returned in separate fields.\n"
        "\n"
        f"{example_block}"
    )


def build_story_user_prompt(
    *,
    place_name: str,
    location: str,
    wikipedia_title: str,
    wikipedia_extract: str,
    hook: StoryHook | None = None,
) -> str:
    """User prompt: feed the LLM the place + wiki extract + optional hook."""
    lines = [
        f"Place: {place_name}",
        f"Location: {location}",
        f'Source material (English Wikipedia extract for "{wikipedia_title}"):',
        "<<<",
        wikipedia_extract,
        ">>>",
    ]
    if hook is not None:
        lines.extend(
            [
                "",
                "Narrative anchor (you MUST develop this specific thread; "
                "do not bounce between unrelated topics):",
                f"- Title: {hook.title}",
                f"- Teaser: {hook.teaser}",
            ]
        )
    else:
        lines.extend(
            [
                "",
                "No specific narrative anchor — pick the most evocative "
                "real-world thread the source can ground.",
            ]
        )
    return "\n".join(lines)
