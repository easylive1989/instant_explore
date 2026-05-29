"""Caption builder for Instagram posts.

Takes a `StoryCopy` view of a daily story row plus the brand handle. Hashtag
strategy is hybrid: a small fixed set of brand tags first, then the
per-story tags the model generated.
"""
from __future__ import annotations

from dataclasses import dataclass

# Fixed brand tags appended to every IG caption.
BRAND_TAGS: tuple[str, ...] = (
    "WorldHeritage",
    "Travel",
    "History",
    "Culture",
    "InstantExplore",
)

# Hard platform limit for IG captions.
_IG_HARD_LIMIT = 2200


@dataclass(frozen=True)
class StoryCopy:
    """Fields used to assemble the IG caption."""

    place_name: str
    era: str
    story: str
    hashtags: tuple[str, ...]


def build_full_caption(
    *, story: StoryCopy, brand_handle: str, cta_text: str
) -> str:
    """Build the full IG caption (header + body + hashtags + CTA).

    Truncates only the body to keep the result under IG's 2200-char limit.
    """
    header = _header(story)
    tags = _format_tags(BRAND_TAGS + story.hashtags)
    footer = _footer(cta_text=cta_text, brand_handle=brand_handle)

    fixed = "\n\n".join(p for p in (header, "", tags, footer) if p)
    body_budget = _IG_HARD_LIMIT - len(fixed) - 2  # account for separators
    body = story.story if len(story.story) <= body_budget else _truncate(
        story.story, body_budget
    )
    return "\n\n".join(p for p in (header, body, tags, footer) if p)


def _header(story: StoryCopy) -> str:
    return f"{story.place_name} · {story.era}".strip()


def _footer(*, cta_text: str, brand_handle: str) -> str:
    parts = [p for p in (cta_text.strip(), brand_handle.strip()) if p]
    return " ".join(parts)


def _format_tags(tags) -> str:
    """Render an iterable of bare tag strings as space-separated #hashtags."""
    return " ".join(f"#{t}" for t in tags if t)


def _truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    # Leave room for an ellipsis.
    return text[: max(0, limit - 1)] + "…"
