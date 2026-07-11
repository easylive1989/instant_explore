"""reel_cover shared-helper tests."""
from __future__ import annotations

from unittest.mock import patch

from lorescape_publisher import reel_cover


def test_narration_hook_returns_first_nonblank_line():
    text = "\n第一句鉤子。\n第二句。\n"
    assert reel_cover.narration_hook(text) == "第一句鉤子。"


def test_narration_hook_none_when_empty():
    assert reel_cover.narration_hook(None) is None
    assert reel_cover.narration_hook("") is None
    assert reel_cover.narration_hook("\n  \n") is None


@patch("lorescape_publisher.reel_cover.card_storage.upload_card_png")
@patch("lorescape_publisher.reel_cover.render_cover")
@patch("lorescape_publisher.reel_cover.mapper.build_card_content")
@patch("lorescape_publisher.reel_cover.load_place_row")
@patch("lorescape_publisher.reel_cover.load_story_row")
def test_build_cover_url_renders_uploads_and_returns_url(
    load_story, load_place, build_content, render, upload
):
    load_story.return_value = {"place_id": "p1"}
    load_place.return_value = {"id": "p1"}
    build_content.return_value = object()
    render.return_value = b"\x89PNGcover"
    upload.return_value = "https://x.supabase.co/.../2026-06-22/reel-cover.png"

    url = reel_cover.build_cover_url(object(), "2026-06-22")

    assert url == upload.return_value
    assert upload.call_args.kwargs["path"] == "2026-06-22/reel-cover.png"


@patch("lorescape_publisher.reel_cover.load_story_row")
def test_build_cover_url_none_when_story_row_missing(load_story):
    load_story.return_value = None
    assert reel_cover.build_cover_url(object(), "2026-06-22") is None


@patch("lorescape_publisher.reel_cover.mapper.build_card_content")
@patch("lorescape_publisher.reel_cover.load_place_row")
@patch("lorescape_publisher.reel_cover.load_story_row")
def test_build_cover_url_none_when_card_content_missing(
    load_story, load_place, build_content
):
    load_story.return_value = {"place_id": "p1"}
    load_place.return_value = {"id": "p1"}
    build_content.return_value = None
    assert reel_cover.build_cover_url(object(), "2026-06-22") is None


@patch("lorescape_publisher.reel_cover.load_place_row")
@patch("lorescape_publisher.reel_cover.load_story_row")
def test_build_cover_url_uses_given_story_row(load_story, load_place):
    """Passing story_row skips the daily_stories query."""
    load_place.return_value = None

    result = reel_cover.build_cover_url(
        object(), "2026-06-22", story_row={"place_id": "p1"}
    )

    assert result is None
    load_story.assert_not_called()
    load_place.assert_called_once()
