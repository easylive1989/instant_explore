"""Tests for the reel Discord review submission script."""
from __future__ import annotations

from types import SimpleNamespace

import send_reel_for_review


def _config(**overrides):
    base = dict(
        discord_bot_token="tok",
        discord_review_channel_id="chan-1",
        supabase_url="https://x.supabase.co",
        supabase_service_role_key="key",
    )
    base.update(overrides)
    return SimpleNamespace(**base)


def test_load_video_bytes_returns_small_file_as_is(tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"small")

    assert send_reel_for_review._load_video_bytes(video) == b"small"


def test_load_video_bytes_encodes_preview_when_too_large(tmp_path, mocker):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"x")
    mocker.patch.object(
        send_reel_for_review, "MAX_ATTACHMENT_BYTES", 0
    )
    run = mocker.patch.object(send_reel_for_review.subprocess, "run")

    send_reel_for_review._load_video_bytes(video)

    cmd = run.call_args.args[0]
    assert cmd[0] == "ffmpeg"
    assert "scale=-2:720" in cmd
    assert str(video) in cmd


def test_main_sends_review_and_records_pending_row(tmp_path, mocker):
    day_dir = tmp_path / "2026-07-05"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(send_reel_for_review, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("send_reel_for_review.load_dotenv")
    mocker.patch(
        "send_reel_for_review.Config.from_env", return_value=_config()
    )
    mocker.patch("send_reel_for_review.create_client", return_value=object())
    send_video = mocker.patch(
        "send_reel_for_review.discord_review.send_video_for_review",
        return_value="msg-1",
    )
    record = mocker.patch(
        "send_reel_for_review.post_log.record_review_pending"
    )

    result = send_reel_for_review.main(["2026-07-05"])

    assert result == 0
    assert send_video.call_args.kwargs["video_bytes"] == b"v"
    assert send_video.call_args.kwargs["publish_date"] == "2026-07-05"
    assert record.call_args.kwargs["discord_message_id"] == "msg-1"
    assert record.call_args.kwargs["media_type"] == "reel"


def test_main_fails_when_video_missing(tmp_path, mocker):
    mocker.patch.object(send_reel_for_review, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("send_reel_for_review.load_dotenv")
    mocker.patch(
        "send_reel_for_review.Config.from_env", return_value=_config()
    )

    assert send_reel_for_review.main(["2026-07-05"]) == 1


def test_main_fails_when_discord_not_configured(tmp_path, mocker):
    day_dir = tmp_path / "2026-07-05"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    mocker.patch.object(send_reel_for_review, "DAILY_VIDEO_DIR", tmp_path)
    mocker.patch("send_reel_for_review.load_dotenv")
    mocker.patch(
        "send_reel_for_review.Config.from_env",
        return_value=_config(discord_bot_token=None),
    )

    assert send_reel_for_review.main(["2026-07-05"]) == 1
