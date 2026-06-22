"""Tests for the manual IG Reels publish script."""
from __future__ import annotations

from types import SimpleNamespace

import pytest

from scripts import publish_reel


def test_resolve_video_returns_final_mp4(tmp_path, monkeypatch):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)

    result = publish_reel._resolve_video("2026-06-22", None)

    assert result == day_dir / "final.mp4"


def test_resolve_video_raises_when_missing(tmp_path, monkeypatch):
    (tmp_path / "2026-06-22").mkdir()
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)

    with pytest.raises(FileNotFoundError):
        publish_reel._resolve_video("2026-06-22", None)


def test_build_caption_prefers_override():
    result = publish_reel._build_caption(
        supabase=None, config=None, date_str="2026-06-22", override="hello"
    )
    assert result == "hello"


def test_build_caption_from_story_row(mocker):
    config = SimpleNamespace(
        brand_handle_ig="@love.lorescape", cta_text="Explore."
    )
    mocker.patch.object(
        publish_reel,
        "_load_story_row",
        return_value={
            "place_name": "Alhambra",
            "era": "13th century",
            "story": "A Moorish palace tale.",
            "hashtags": ["Spain"],
            "image_attribution": None,
        },
    )
    result = publish_reel._build_caption(
        supabase=object(), config=config, date_str="2026-06-22", override=None
    )
    assert "Alhambra" in result
    assert "#Spain" in result


def test_build_caption_falls_back_to_narration(mocker):
    mocker.patch.object(publish_reel, "_load_story_row", return_value=None)
    mocker.patch.object(
        publish_reel, "_read_narration", return_value="narration line"
    )
    result = publish_reel._build_caption(
        supabase=object(), config=object(), date_str="2026-06-22", override=None
    )
    assert result == "narration line"


def test_build_caption_raises_when_nothing_available(mocker):
    mocker.patch.object(publish_reel, "_load_story_row", return_value=None)
    mocker.patch.object(publish_reel, "_read_narration", return_value=None)
    with pytest.raises(ValueError):
        publish_reel._build_caption(
            supabase=object(),
            config=object(),
            date_str="2026-06-22",
            override=None,
        )
