"""reel_publisher.run_reel_publish_job state-machine tests."""
from __future__ import annotations

from dataclasses import replace
from datetime import date
from unittest.mock import patch

import pytest

from lorescape_backend.social.reel_publisher import run_reel_publish_job

TARGET = date(2026, 7, 5)
DATE_STR = "2026-07-05"


def _story_row(**overrides):
    base = dict(
        id="row-zh-1",
        publish_date=DATE_STR,
        language="zh-TW",
        place_id="place-1",
        place_name="羅馬競技場",
        era="公元 70-80 年",
        story="第一段\n\n第二段",
        hashtags=["rome"],
        image_attribution=None,
        review_state="published",
    )
    base.update(overrides)
    return base


@pytest.fixture
def video_config(fake_config, tmp_path):
    """fake_config pointed at a tmp DAILY_VIDEO_DIR with today's video."""
    day_dir = tmp_path / DATE_STR
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    (day_dir / "narration.txt").write_text(
        "這座競技場藏著什麼？\n第二句。", encoding="utf-8"
    )
    return replace(fake_config, daily_video_dir=str(tmp_path))


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_publishes_and_records_success(
    ig_pub, cover, post_log, create, video_config
):
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row()
    cover.narration_hook.return_value = "這座競技場藏著什麼？"
    cover.build_cover_url.return_value = "https://x/cover.png"
    ig_pub.return_value = "reel-1"

    run_reel_publish_job(video_config, TARGET)

    ig_kwargs = ig_pub.call_args.kwargs
    assert ig_kwargs["video_path"].endswith(f"{DATE_STR}/final.mp4")
    assert ig_kwargs["cover_url"] == "https://x/cover.png"
    assert "羅馬競技場" in ig_kwargs["caption"]
    record = post_log.record_post.call_args.kwargs
    assert record["media_type"] == "reel"
    assert record["status"] == "published"
    assert record["ig_post_id"] == "reel-1"


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_already_published_skips(
    ig_pub, cover, post_log, create, video_config
):
    post_log.get_post.return_value = {"status": "published"}

    run_reel_publish_job(video_config, TARGET)

    ig_pub.assert_not_called()
    post_log.record_post.assert_not_called()


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_failed_row_is_retried(
    ig_pub, cover, post_log, create, video_config
):
    """A prior 'failed' social_posts row must not block the retry."""
    post_log.get_post.return_value = {"status": "failed"}
    cover.load_story_row.return_value = _story_row()
    cover.narration_hook.return_value = None
    cover.build_cover_url.return_value = None
    ig_pub.return_value = "reel-2"

    run_reel_publish_job(video_config, TARGET)

    ig_pub.assert_called_once()
    assert post_log.record_post.call_args.kwargs["status"] == "published"


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_unapproved_story_skips(
    ig_pub, cover, post_log, create, video_config
):
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row(review_state="pending")

    run_reel_publish_job(video_config, TARGET)

    ig_pub.assert_not_called()
    post_log.record_post.assert_not_called()


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
@patch("lorescape_backend.social.reel_publisher.discord_notify.notify_failure")
def test_missing_video_notifies_and_leaves_no_state(
    notify, ig_pub, cover, post_log, create, fake_config, tmp_path
):
    config = replace(fake_config, daily_video_dir=str(tmp_path))
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row()

    run_reel_publish_job(config, TARGET)

    ig_pub.assert_not_called()
    post_log.record_post.assert_not_called()
    notify.assert_called_once()
    assert "no video" in notify.call_args.kwargs["error_message"]


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
@patch("lorescape_backend.social.reel_publisher.discord_notify.notify_failure")
def test_publish_failure_records_failed_and_notifies(
    notify, ig_pub, cover, post_log, create, video_config
):
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row()
    cover.narration_hook.return_value = None
    cover.build_cover_url.return_value = None
    ig_pub.side_effect = RuntimeError("Reel container failed")

    run_reel_publish_job(video_config, TARGET)

    record = post_log.record_post.call_args.kwargs
    assert record["status"] == "failed"
    assert "Reel container failed" in record["error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_cover_failure_publishes_without_cover(
    ig_pub, cover, post_log, create, video_config
):
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row()
    cover.narration_hook.return_value = None
    cover.build_cover_url.side_effect = RuntimeError("render exploded")
    ig_pub.return_value = "reel-3"

    run_reel_publish_job(video_config, TARGET)

    assert ig_pub.call_args.kwargs["cover_url"] is None
    assert post_log.record_post.call_args.kwargs["status"] == "published"


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.post_log")
@patch("lorescape_backend.social.reel_publisher.reel_cover")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_dry_run_publishes_nothing(
    ig_pub, cover, post_log, create, video_config, capsys
):
    post_log.get_post.return_value = None
    cover.load_story_row.return_value = _story_row()
    cover.narration_hook.return_value = None
    cover.build_cover_url.return_value = None

    run_reel_publish_job(video_config, TARGET, dry_run=True)

    ig_pub.assert_not_called()
    post_log.record_post.assert_not_called()
    assert "[dry-run]" in capsys.readouterr().out


@patch("lorescape_backend.social.reel_publisher.create_client")
@patch("lorescape_backend.social.reel_publisher.instagram.publish_reel")
def test_no_video_dir_disables_job(ig_pub, create, fake_config):
    run_reel_publish_job(fake_config, TARGET)

    create.assert_not_called()
    ig_pub.assert_not_called()
