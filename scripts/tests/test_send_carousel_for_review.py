"""Tests for the carousel Discord review submission script."""
from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace

import pytest

import send_carousel_for_review


def _config(**overrides):
    base = dict(
        discord_bot_token="tok",
        discord_review_channel_id="chan-1",
        supabase_url="https://x.supabase.co",
        supabase_service_role_key="key",
    )
    base.update(overrides)
    return SimpleNamespace(**base)


@pytest.fixture
def day_dir(tmp_path, mocker) -> Path:
    day = tmp_path / "2026-07-06"
    day.mkdir()
    for i in (1, 2):
        (day / f"slide_{i:02d}.jpg").write_bytes(b"jpeg" + bytes([i]))
    (day / "caption.txt").write_text("今天的故事", encoding="utf-8")
    mocker.patch.object(
        send_carousel_for_review, "DAILY_CAROUSEL_DIR", tmp_path
    )
    return day


@pytest.fixture
def env(mocker):
    mocker.patch("send_carousel_for_review.load_dotenv")
    mocker.patch(
        "send_carousel_for_review.Config.from_env", return_value=_config()
    )
    mocker.patch(
        "send_carousel_for_review.create_client", return_value=object()
    )
    upload = mocker.patch.object(
        send_carousel_for_review.card_storage, "upload_card_image"
    )
    upload.side_effect = (
        lambda supabase, data, *, path, content_type:
        f"https://x/ig-cards/{path}"
    )
    send = mocker.patch.object(
        send_carousel_for_review.discord_review, "send_images_for_review",
        return_value="msg-1",
    )
    pending = mocker.patch.object(
        send_carousel_for_review.post_log, "record_review_pending"
    )
    return SimpleNamespace(upload=upload, send=send, pending=pending)


def test_uploads_slides_sends_review_and_records_pending(day_dir, env):
    assert send_carousel_for_review.main(["2026-07-06"]) == 0

    assert env.upload.call_count == 2
    first = env.upload.call_args_list[0]
    assert first.kwargs["path"] == "wander/2026-07-06/slide_01.jpg"
    assert first.kwargs["content_type"] == "image/jpeg"

    env.send.assert_called_once()
    assert len(env.send.call_args.kwargs["images"]) == 2

    env.pending.assert_called_once()
    kwargs = env.pending.call_args.kwargs
    assert kwargs["media_type"] == "carousel"
    assert kwargs["discord_message_id"] == "msg-1"
    assert kwargs["slide_urls"] == [
        "https://x/ig-cards/wander/2026-07-06/slide_01.jpg",
        "https://x/ig-cards/wander/2026-07-06/slide_02.jpg",
    ]
    assert kwargs["caption"] == "今天的故事"


def test_missing_slides_dir_fails(env, tmp_path, mocker):
    mocker.patch.object(
        send_carousel_for_review, "DAILY_CAROUSEL_DIR", tmp_path
    )
    assert send_carousel_for_review.main(["2026-07-06"]) == 1
    env.upload.assert_not_called()


def test_oversized_slide_fails_before_upload(day_dir, env, mocker):
    mocker.patch.object(send_carousel_for_review, "MAX_ATTACHMENT_BYTES", 3)
    assert send_carousel_for_review.main(["2026-07-06"]) == 1
    env.pending.assert_not_called()


def test_main_fails_when_discord_not_configured(day_dir, env, mocker):
    mocker.patch(
        "send_carousel_for_review.Config.from_env",
        return_value=_config(discord_bot_token=None),
    )
    assert send_carousel_for_review.main(["2026-07-06"]) == 1
    env.upload.assert_not_called()
