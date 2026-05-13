"""Caption builders for Threads and Instagram posts.

Both functions take the same `StoryCopy` view of a daily story row plus the
brand handle for the target platform. Hashtag strategy is hybrid: a small
fixed set of brand tags first, then the per-story tags the model generated.
"""
from __future__ import annotations

from dataclasses import dataclass

# Fixed brand tags. Appended to every IG caption; the first three also seed
# the (shorter) Threads caption when there's room.
BRAND_TAGS: tuple[str, ...] = (
    "WorldHeritage",
    "Travel",
    "History",
    "Culture",
    "InstantExplore",
)

# Hard platform limits.
_THREADS_HARD_LIMIT = 500
_IG_HARD_LIMIT = 2200


@dataclass(frozen=True)
class StoryCopy:
    """Fields used to assemble platform-specific captions."""

    place_name: str
    era: str
    story: str
    threads_summary: str
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


def build_threads_caption(
    *, story: StoryCopy, brand_handle: str, cta_text: str
) -> str:
    """Build a Threads caption that fits in 500 chars.

    Includes the punchy summary plus a header. Hashtags and brand mention are
    appended greedily — dropped as needed to fit.
    """
    header = _header(story)
    body = story.threads_summary
    base = f"{header}\n\n{body}".rstrip()
    if len(base) > _THREADS_HARD_LIMIT:
        return _truncate(base, _THREADS_HARD_LIMIT)

    # Try increasingly trimmed footers until something fits.
    primary_tags = _format_tags(story.hashtags[:3])
    mention = brand_handle.strip()
    cta = cta_text.strip()

    for extras in _footer_variants(
        primary_tags=primary_tags, mention=mention, cta=cta
    ):
        candidate = f"{base}\n\n{extras}" if extras else base
        if len(candidate) <= _THREADS_HARD_LIMIT:
            return candidate
    return base


def _header(story: StoryCopy) -> str:
    return f"{story.place_name} · {story.era}".strip()


def _footer(*, cta_text: str, brand_handle: str) -> str:
    parts = [p for p in (cta_text.strip(), brand_handle.strip()) if p]
    return " ".join(parts)


def _format_tags(tags) -> str:
    """Render an iterable of bare tag strings as space-separated #hashtags."""
    return " ".join(f"#{t}" for t in tags if t)


def _footer_variants(
    *, primary_tags: str, mention: str, cta: str
):
    """Yield footer candidates from richest to bare-bones."""
    if cta and primary_tags and mention:
        yield f"{cta}\n{primary_tags} {mention}"
    if primary_tags and mention:
        yield f"{primary_tags} {mention}"
    if mention:
        yield mention
    if primary_tags:
        yield primary_tags
    yield ""


def _truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    # Leave room for an ellipsis.
    return text[: max(0, limit - 1)] + "…"
