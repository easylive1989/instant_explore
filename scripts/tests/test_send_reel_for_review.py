"""Tests for the reel pending-row staging script."""
from __future__ import annotations

from types import SimpleNamespace

import send_reel_for_review


def _config(**overrides):
    base = dict(
        supabase_url="https://x.supabase.co",
        supabase_service_role_key="key",
    )
    base.update(overrides)
    return SimpleNamespace(**base)


def test_main_stages_pending_row(tmp_path, mocker):
    day_dir = tmp_path / "2026-07-05"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(send_reel_for_review, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("send_reel_for_review.load_dotenv")
    mocker.patch(
        "send_reel_for_review.Config.from_env", return_value=_config()
    )
    mocker.patch("send_reel_for_review.create_client", return_value=object())
    stage = mocker.patch.object(
        send_reel_for_review.post_log, "stage_pending"
    )

    result = send_reel_for_review.main(["2026-07-05"])

    assert result == 0
    # The script no longer imports discord_review — the bot owns posting
    # the review message (and building the 720p preview) now.
    assert not hasattr(send_reel_for_review, "discord_review")

    stage.assert_called_once()
    kwargs = stage.call_args.kwargs
    assert kwargs["publish_date"] == "2026-07-05"
    assert kwargs["media_type"] == "reel"


def test_main_fails_when_video_missing(tmp_path, mocker):
    mocker.patch.object(send_reel_for_review, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("send_reel_for_review.load_dotenv")
    mocker.patch(
        "send_reel_for_review.Config.from_env", return_value=_config()
    )

    assert send_reel_for_review.main(["2026-07-05"]) == 1
