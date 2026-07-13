"""Tests for the manual IG Reels publish script.

Cover rendering and hook parsing moved to the shared
`lorescape_publisher.reel_cover` module (tested in publisher/tests);
here we cover the script-local pieces: video resolution, caption source
priority, and the CLI wiring.
"""
from __future__ import annotations

from types import SimpleNamespace

import pytest

import publish_reel


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
        publish_reel.reel_cover,
        "load_story_row",
        return_value={
            "place_name": "Alhambra",
            "era": "13th century",
            "story": "A Moorish palace tale.",
            "hashtags": ["Spain"],
            "image_attribution": None,
        },
    )
    mocker.patch.object(publish_reel, "_read_narration", return_value=None)
    result = publish_reel._build_caption(
        supabase=object(), config=config, date_str="2026-06-22", override=None
    )
    assert "Alhambra" in result
    assert "#Spain" in result


def test_build_caption_leads_with_narration_hook(mocker):
    config = SimpleNamespace(
        brand_handle_ig="@love.lorescape", cta_text="Explore."
    )
    mocker.patch.object(
        publish_reel.reel_cover,
        "load_story_row",
        return_value={
            "place_name": "Alhambra",
            "era": "13th century",
            "story": "A Moorish palace tale.",
            "hashtags": ["Spain"],
            "image_attribution": None,
        },
    )
    mocker.patch.object(
        publish_reel,
        "_read_narration",
        return_value="這座宮殿藏著什麼秘密？\n第二行不該當鉤子。",
    )
    result = publish_reel._build_caption(
        supabase=object(), config=config, date_str="2026-06-22", override=None
    )
    assert result.startswith("這座宮殿藏著什麼秘密？")


def test_read_narration_returns_text(tmp_path, monkeypatch):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "narration.txt").write_text(
        "\n第一句鉤子。\n第二句。\n", encoding="utf-8"
    )
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)

    assert publish_reel._read_narration("2026-06-22") == "第一句鉤子。\n第二句。"


def test_read_narration_none_when_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    assert publish_reel._read_narration("2026-06-22") is None


def test_build_caption_falls_back_to_narration(mocker):
    mocker.patch.object(
        publish_reel.reel_cover, "load_story_row", return_value=None
    )
    mocker.patch.object(
        publish_reel, "_read_narration", return_value="narration line"
    )
    result = publish_reel._build_caption(
        supabase=object(), config=object(), date_str="2026-06-22", override=None
    )
    assert result == "narration line"


def test_build_caption_raises_when_nothing_available(mocker):
    mocker.patch.object(
        publish_reel.reel_cover, "load_story_row", return_value=None
    )
    mocker.patch.object(publish_reel, "_read_narration", return_value=None)
    with pytest.raises(ValueError):
        publish_reel._build_caption(
            supabase=object(),
            config=object(),
            date_str="2026-06-22",
            override=None,
        )


def test_main_passes_cover_url_to_publish_reel(tmp_path, mocker):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("publish_reel.load_dotenv")
    mocker.patch.object(
        publish_reel, "_build_caption", return_value="some caption"
    )
    mocker.patch.object(
        publish_reel.reel_cover, "build_cover_url",
        return_value="https://x/cover.png",
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
    mocker.patch("publish_reel.Config.from_env", return_value=config)
    mocker.patch("publish_reel.create_client", return_value=object())
    pub = mocker.patch(
        "publish_reel.reel_publisher.publish_reel_with_fallback",
        return_value="post-1",
    )

    result = publish_reel.main(["2026-06-22"])

    assert result == 0
    assert pub.call_args.kwargs["cover_url"] == "https://x/cover.png"


def test_main_publishes_without_cover_when_cover_build_fails(tmp_path, mocker):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("publish_reel.load_dotenv")
    mocker.patch.object(
        publish_reel, "_build_caption", return_value="some caption"
    )
    mocker.patch.object(
        publish_reel.reel_cover, "build_cover_url",
        side_effect=RuntimeError("render exploded"),
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
    mocker.patch("publish_reel.Config.from_env", return_value=config)
    mocker.patch("publish_reel.create_client", return_value=object())
    pub = mocker.patch(
        "publish_reel.reel_publisher.publish_reel_with_fallback",
        return_value="post-1",
    )

    result = publish_reel.main(["2026-06-22"])

    assert result == 0
    # Cover failure must not block the publish; it falls back to no cover.
    assert pub.call_args.kwargs["cover_url"] is None


def test_main_via_url_flag_skips_rupload_path(tmp_path, mocker):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("publish_reel.load_dotenv")
    mocker.patch.object(
        publish_reel, "_build_caption", return_value="some caption"
    )
    mocker.patch.object(
        publish_reel.reel_cover, "build_cover_url", return_value=None
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
    mocker.patch("publish_reel.Config.from_env", return_value=config)
    mocker.patch("publish_reel.create_client", return_value=object())
    with_fallback = mocker.patch(
        "publish_reel.reel_publisher.publish_reel_with_fallback"
    )
    via_url = mocker.patch(
        "publish_reel.reel_publisher.publish_reel_via_video_url",
        return_value="post-url-1",
    )

    result = publish_reel.main(["2026-06-22", "--via-url"])

    assert result == 0
    with_fallback.assert_not_called()
    assert via_url.call_args.kwargs["date_str"] == "2026-06-22"


def test_main_returns_1_and_prints_error_on_publish_failure(
    tmp_path, mocker
):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(publish_reel, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("publish_reel.load_dotenv")
    mocker.patch.object(
        publish_reel,
        "_build_caption",
        return_value="some caption",
    )
    mocker.patch.object(
        publish_reel.reel_cover, "build_cover_url", return_value=None
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
        "publish_reel.Config.from_env", return_value=config
    )
    mocker.patch(
        "publish_reel.create_client", return_value=object()
    )
    mocker.patch(
        "publish_reel.reel_publisher.publish_reel_with_fallback",
        side_effect=RuntimeError("Reel container c1 failed: ERROR detail"),
    )

    import io
    stderr_capture = io.StringIO()
    mocker.patch("sys.stderr", stderr_capture)

    result = publish_reel.main(["2026-06-22"])

    assert result == 1
    assert "Reel container c1 failed" in stderr_capture.getvalue()
