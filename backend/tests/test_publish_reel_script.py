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


def test_main_returns_1_and_prints_error_on_publish_failure(
    tmp_path, mocker
):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("scripts.publish_reel.load_dotenv")
    mocker.patch.object(
        publish_reel,
        "_build_caption",
        return_value="some caption",
    )

    config = SimpleNamespace(
        instagram_enabled=True,
        ig_user_id="ig1",
        meta_page_access_token="tok",
        supabase_url="https://x.supabase.co",
        supabase_service_role_key="key",
        brand_handle_ig="@lorescape",
        cta_text="Explore.",
    )
    mocker.patch(
        "scripts.publish_reel.Config.from_env", return_value=config
    )
    mocker.patch(
        "scripts.publish_reel.create_client", return_value=object()
    )
    mocker.patch(
        "scripts.publish_reel.instagram.publish_reel",
        side_effect=RuntimeError("Reel container c1 failed: ERROR detail"),
    )

    import io
    stderr_capture = io.StringIO()
    mocker.patch("sys.stderr", stderr_capture)

    result = publish_reel.main(["2026-06-22"])

    assert result == 1
    assert "Reel container c1 failed" in stderr_capture.getvalue()
