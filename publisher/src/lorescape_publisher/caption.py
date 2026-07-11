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
    "Lorescape",
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
    # Lead-image credit (author / licence / source). None when there is no
    # commercially usable image; omitted from the caption when absent.
    image_attribution: str | None = None
    # Curiosity-gap opening line (the reel's spoken hook). When present it
    # leads the caption so the preview shows the hook, not "place · era".
    hook: str | None = None


def build_full_caption(
    *, story: StoryCopy, brand_handle: str, cta_text: str
) -> str:
    """Build the full IG caption (hook + header + body + tags + CTA + credit).

    When the story carries a ``hook`` it leads the caption so the preview
    shows the curiosity gap; otherwise the header (``place · era``) leads,
    preserving the original layout. Truncates only the body to keep the
    result under IG's 2200-char limit. A photo credit line is appended when
    the story has an image attribution.
    """
    lead = story.hook.strip() if story.hook else ""
    header = _header(story)
    tags = _format_tags(BRAND_TAGS + story.hashtags)
    footer = _footer(cta_text=cta_text, brand_handle=brand_handle)
    credit = _photo_credit(story.image_attribution)

    non_body = [p for p in (lead, header, tags, footer, credit) if p]
    # Budget for the body: hard limit minus every other block, minus a small
    # margin for the "\n\n" separators the body itself adds.
    body_budget = _IG_HARD_LIMIT - len("\n\n".join(non_body)) - 4
    body = story.story if len(story.story) <= body_budget else _truncate(
        story.story, body_budget
    )
    parts = [p for p in (lead, header, body, tags, footer, credit) if p]
    return "\n\n".join(parts)


def _photo_credit(attribution: str | None) -> str:
    """Render the image credit line, or empty string when absent."""
    if not attribution:
        return ""
    return f"📷 {attribution}"


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
