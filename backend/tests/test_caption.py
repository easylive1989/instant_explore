"""Caption builder for Instagram."""
from __future__ import annotations

from lorescape_backend.social.caption import (
    BRAND_TAGS,
    StoryCopy,
    build_full_caption,
)


def _story(**overrides) -> StoryCopy:
    base = dict(
        place_name="Colosseum",
        era="70-80 CE",
        story="A long story body. " * 20,  # ~400 chars
        hashtags=("rome", "colosseum", "ancientWonders"),
    )
    base.update(overrides)
    return StoryCopy(**base)


def test_full_caption_starts_with_header():
    out = build_full_caption(
        story=_story(),
        brand_handle="@instant_explore",
        cta_text="Explore more.",
    )
    assert out.startswith("Colosseum · 70-80 CE")


def test_full_caption_contains_story_body_hashtags_cta_and_mention():
    story = _story()
    out = build_full_caption(
        story=story,
        brand_handle="@instant_explore",
        cta_text="Explore more.",
    )
    assert "A long story body." in out
    # Brand tags must appear and so do the per-story tags.
    for tag in BRAND_TAGS:
        assert f"#{tag}" in out
    for tag in story.hashtags:
        assert f"#{tag}" in out
    assert "Explore more." in out
    assert "@instant_explore" in out


def test_full_caption_under_ig_limit_when_story_is_huge():
    huge_story = _story(story="x" * 5000)
    out = build_full_caption(
        story=huge_story,
        brand_handle="@instant_explore",
        cta_text="Explore more.",
    )
    assert len(out) <= 2200
