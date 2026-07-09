"""Tests for the carousel upload + pending-row staging script."""
from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace

import pytest

import send_carousel_for_review


def _config(**overrides):
    base = dict(
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
    pending = mocker.patch.object(
        send_carousel_for_review.post_log, "stage_pending"
    )
    return SimpleNamespace(upload=upload, pending=pending)


def test_uploads_slides_and_stages_pending_row(day_dir, env):
    assert send_carousel_for_review.main(["2026-07-06"]) == 0

    # The script no longer imports discord_review at all — local scripts
    # only upload + stage a row; the bot owns posting the review message.
    assert not hasattr(send_carousel_for_review, "discord_review")

    assert env.upload.call_count == 2
    first = env.upload.call_args_list[0]
    assert first.kwargs["path"] == "wander/2026-07-06/slide_01.jpg"
    assert first.kwargs["content_type"] == "image/jpeg"

    env.pending.assert_called_once()
    kwargs = env.pending.call_args.kwargs
    assert kwargs["publish_date"] == "2026-07-06"
    assert kwargs["media_type"] == "carousel"
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
    env.pending.assert_not_called()


def test_missing_caption_fails(day_dir, env):
    (day_dir / "caption.txt").unlink()
    assert send_carousel_for_review.main(["2026-07-06"]) == 1
    env.upload.assert_not_called()
    env.pending.assert_not_called()
