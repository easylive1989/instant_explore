"""Content payload for the wander-style IG carousel.

A day's carousel lives in one directory (`marketing/outputs/daily_carousel/
<date>/`) holding `slides.json` (7–9 slide beats, written by Claude and
reviewed by the operator) and `caption.txt` (the IG caption). `load_carousel`
validates everything up-front so bad content fails before rendering.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

LAYOUTS = ("cover", "beat", "bright", "ending")
TEXT_POSITIONS = ("left", "right", "top", "center")
OVERLAYS = ("dark", "darker", "light")

# IG carousel hard limit.
MAX_SLIDES = 10


class WanderContentError(ValueError):
    """slides.json / caption.txt is missing or malformed."""


@dataclass(frozen=True)
class WanderSlide:
    """One carousel page: a photo, a layout variant and its copy.

    An empty string in `lines` marks a decorative separator between
    line groups (rendered as a thin gold rule).
    """

    layout: str
    photo: str
    lines: tuple[str, ...]
    title: str | None = None
    title_en: str | None = None
    tag_zh: str | None = None
    tag_en: str | None = None
    highlights: tuple[str, ...] = ()
    text_position: str = "left"
    overlay: str = "dark"


@dataclass(frozen=True)
class WanderCarousel:
    """A full day's wander carousel: ordered slides plus the IG caption."""

    date: str
    caption: str
    slides: tuple[WanderSlide, ...]


def load_carousel(day_dir: Path) -> WanderCarousel:
    """Load and validate `<day_dir>/slides.json` + `<day_dir>/caption.txt`.

    `day_dir` is named after the publish date (YYYY-MM-DD); the directory
    name becomes `WanderCarousel.date`.
    """
    slides_path = day_dir / "slides.json"
    caption_path = day_dir / "caption.txt"
    if not slides_path.is_file():
        raise WanderContentError(f"slides.json not found in {day_dir}")
    if not caption_path.is_file():
        raise WanderContentError(f"caption.txt not found in {day_dir}")

    caption = caption_path.read_text(encoding="utf-8").strip()
    if not caption:
        raise WanderContentError("caption.txt is empty")

    try:
        payload = json.loads(slides_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise WanderContentError(f"slides.json is not valid JSON: {exc}")

    raw_slides = payload.get("slides")
    if not raw_slides:
        raise WanderContentError("slides.json has no slides")
    if len(raw_slides) > MAX_SLIDES:
        raise WanderContentError(
            f"IG allows at most {MAX_SLIDES} slides, got {len(raw_slides)}"
        )

    slides = tuple(
        _parse_slide(raw, index) for index, raw in enumerate(raw_slides, 1)
    )
    return WanderCarousel(date=day_dir.name, caption=caption, slides=slides)


def _parse_slide(raw: dict[str, Any], index: int) -> WanderSlide:
    layout = raw.get("layout")
    if layout not in LAYOUTS:
        raise WanderContentError(
            f"slide {index}: layout must be one of {LAYOUTS}, got {layout!r}"
        )
    photo = raw.get("photo")
    if not photo:
        raise WanderContentError(f"slide {index}: photo is required")
    lines = raw.get("lines")
    if not lines:
        raise WanderContentError(f"slide {index}: lines must be non-empty")
    text_position = raw.get("text_position", "left")
    if text_position not in TEXT_POSITIONS:
        raise WanderContentError(
            f"slide {index}: text_position must be one of {TEXT_POSITIONS},"
            f" got {text_position!r}"
        )
    overlay = raw.get("overlay", "dark")
    if overlay not in OVERLAYS:
        raise WanderContentError(
            f"slide {index}: overlay must be one of {OVERLAYS},"
            f" got {overlay!r}"
        )
    return WanderSlide(
        layout=layout,
        photo=photo,
        lines=tuple(lines),
        title=raw.get("title"),
        title_en=raw.get("title_en"),
        tag_zh=raw.get("tag_zh"),
        tag_en=raw.get("tag_en"),
        highlights=tuple(raw.get("highlights") or ()),
        text_position=text_position,
        overlay=overlay,
    )
