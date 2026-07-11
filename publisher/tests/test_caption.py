"""Caption builder for Instagram."""
from __future__ import annotations

from lorescape_publisher.caption import (
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
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert out.startswith("Colosseum · 70-80 CE")


def test_full_caption_contains_story_body_hashtags_cta_and_mention():
    story = _story()
    out = build_full_caption(
        story=story,
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert "A long story body." in out
    # Brand tags must appear and so do the per-story tags.
    for tag in BRAND_TAGS:
        assert f"#{tag}" in out
    for tag in story.hashtags:
        assert f"#{tag}" in out
    assert "Explore more." in out
    assert "@love.lorescape" in out


def test_full_caption_under_ig_limit_when_story_is_huge():
    huge_story = _story(story="x" * 5000)
    out = build_full_caption(
        story=huge_story,
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert len(out) <= 2200


def test_full_caption_leads_with_hook_when_present():
    out = build_full_caption(
        story=_story(hook="這座教堂為什麼被一分為二？"),
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert out.startswith("這座教堂為什麼被一分為二？")
    # The header still appears, just after the hook.
    assert "Colosseum · 70-80 CE" in out


def test_full_caption_includes_photo_credit_when_present():
    story = _story(
        image_attribution="Jane Doe / CC BY-SA 4.0 (via Wikimedia Commons)"
    )
    out = build_full_caption(
        story=story,
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert "📷 Jane Doe / CC BY-SA 4.0 (via Wikimedia Commons)" in out


def test_full_caption_omits_photo_credit_when_absent():
    out = build_full_caption(
        story=_story(image_attribution=None),
        brand_handle="@love.lorescape",
        cta_text="Explore more.",
    )
    assert "📷" not in out
