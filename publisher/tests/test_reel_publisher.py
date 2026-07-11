"""reel_publisher.run_reel_publish_job state-machine tests.

The reel has its own Discord review (independent of the carousel):
pending → published / failed / rejected / skipped, driven by the ✅/❌
reactions on the reel review message referenced by the social_posts row.
"""
from __future__ import annotations

from dataclasses import replace
from datetime import date
from unittest.mock import patch

import pytest

from lorescape_publisher.reel_publisher import run_reel_publish_job

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


def _reel_row(**overrides):
    base = dict(
        publish_date=DATE_STR,
        media_type="reel",
        status="pending",
        discord_message_id="msg-reel-1",
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


@pytest.fixture
def mocks():
    """Patch the collaborators and yield them as a namespace."""
    with (
        patch("lorescape_publisher.reel_publisher.create_client"),
        patch("lorescape_publisher.reel_publisher.post_log") as post_log,
        patch("lorescape_publisher.reel_publisher.reel_cover") as cover,
        patch(
            "lorescape_publisher.reel_publisher.discord_review"
            ".check_reaction"
        ) as check,
        patch(
            "lorescape_publisher.reel_publisher.instagram.publish_reel"
        ) as ig_pub,
        patch(
            "lorescape_publisher.reel_publisher.discord_notify"
            ".notify_failure"
        ) as notify,
    ):
        cover.load_story_row.return_value = _story_row()
        cover.narration_hook.return_value = "這座競技場藏著什麼？"
        cover.build_cover_url.return_value = "https://x/cover.png"

        class Namespace:
            pass

        ns = Namespace()
        ns.post_log = post_log
        ns.cover = cover
        ns.check = check
        ns.ig_pub = ig_pub
        ns.notify = notify
        yield ns


def test_approved_reel_publishes_and_records(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "reel-1"

    run_reel_publish_job(video_config, TARGET)

    assert mocks.check.call_args.kwargs["message_id"] == "msg-reel-1"
    ig_kwargs = mocks.ig_pub.call_args.kwargs
    assert ig_kwargs["video_path"].endswith(f"{DATE_STR}/final.mp4")
    assert ig_kwargs["cover_url"] == "https://x/cover.png"
    assert "羅馬競技場" in ig_kwargs["caption"]
    record = mocks.post_log.record_post.call_args.kwargs
    assert record["media_type"] == "reel"
    assert record["status"] == "published"
    assert record["ig_post_id"] == "reel-1"


def test_rejected_reel_marks_rejected(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "rejected"

    run_reel_publish_job(video_config, TARGET)

    mocks.ig_pub.assert_not_called()
    mark = mocks.post_log.mark_status.call_args.kwargs
    assert mark["status"] == "rejected"


def test_no_reaction_stays_pending_on_first_pass(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "none"

    run_reel_publish_job(video_config, TARGET)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.mark_status.assert_not_called()


def test_no_reaction_marks_skipped_on_final_pass(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "none"

    run_reel_publish_job(video_config, TARGET, final_pass=True)

    mocks.ig_pub.assert_not_called()
    mark = mocks.post_log.mark_status.call_args.kwargs
    assert mark["status"] == "skipped"


@pytest.mark.parametrize("status", ["published", "rejected", "skipped"])
def test_terminal_states_are_untouched(mocks, video_config, status):
    mocks.post_log.get_post.return_value = _reel_row(status=status)

    run_reel_publish_job(video_config, TARGET, final_pass=True)

    mocks.check.assert_not_called()
    mocks.ig_pub.assert_not_called()
    mocks.post_log.mark_status.assert_not_called()
    mocks.post_log.record_post.assert_not_called()


def test_failed_row_is_retried_when_approved(mocks, video_config):
    """failed = approved but the publish attempt raised; retry it."""
    mocks.post_log.get_post.return_value = _reel_row(status="failed")
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "reel-2"

    run_reel_publish_job(video_config, TARGET)

    mocks.ig_pub.assert_called_once()
    assert mocks.post_log.record_post.call_args.kwargs["status"] == "published"


def test_no_review_row_notifies_on_first_pass_only(mocks, video_config):
    mocks.post_log.get_post.return_value = None

    run_reel_publish_job(video_config, TARGET)
    assert mocks.notify.call_count == 1
    assert "no reel" in mocks.notify.call_args.kwargs["error_message"].lower()

    run_reel_publish_job(video_config, TARGET, final_pass=True)
    assert mocks.notify.call_count == 1  # final pass stays quiet

    mocks.ig_pub.assert_not_called()


def test_approved_but_video_missing_notifies(
    mocks, fake_config, tmp_path
):
    empty_dir = tmp_path / "no-videos"
    empty_dir.mkdir()
    config = replace(fake_config, daily_video_dir=str(empty_dir))
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "approved"

    run_reel_publish_job(config, TARGET)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.record_post.assert_not_called()
    mocks.notify.assert_called_once()
    assert "no video" in mocks.notify.call_args.kwargs["error_message"]


def test_publish_failure_records_failed_and_notifies(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.side_effect = RuntimeError("Reel container failed")

    run_reel_publish_job(video_config, TARGET)

    record = mocks.post_log.record_post.call_args.kwargs
    assert record["status"] == "failed"
    assert "Reel container failed" in record["error"]
    mocks.notify.assert_called_once()


def test_cover_failure_publishes_without_cover(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "approved"
    mocks.cover.build_cover_url.side_effect = RuntimeError("render exploded")
    mocks.ig_pub.return_value = "reel-3"

    run_reel_publish_job(video_config, TARGET)

    assert mocks.ig_pub.call_args.kwargs["cover_url"] is None
    assert mocks.post_log.record_post.call_args.kwargs["status"] == "published"


def test_dry_run_publishes_nothing(mocks, video_config, capsys):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "approved"

    run_reel_publish_job(video_config, TARGET, dry_run=True)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.record_post.assert_not_called()
    assert "[dry-run]" in capsys.readouterr().out


def test_dry_run_does_not_mark_rejected(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row()
    mocks.check.return_value = "rejected"

    run_reel_publish_job(video_config, TARGET, dry_run=True)

    mocks.post_log.mark_status.assert_not_called()


def test_row_without_message_id_is_left_alone(mocks, video_config):
    mocks.post_log.get_post.return_value = _reel_row(discord_message_id=None)

    run_reel_publish_job(video_config, TARGET, final_pass=True)

    mocks.check.assert_not_called()
    mocks.post_log.mark_status.assert_not_called()


def test_no_video_dir_disables_job(fake_config):
    with (
        patch(
            "lorescape_publisher.reel_publisher.create_client"
        ) as create,
        patch(
            "lorescape_publisher.reel_publisher.instagram.publish_reel"
        ) as ig_pub,
    ):
        run_reel_publish_job(fake_config, TARGET)

        create.assert_not_called()
        ig_pub.assert_not_called()
