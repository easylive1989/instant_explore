"""publisher._handle_prerendered — 預渲染（wander）carousel 的發布分支."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

import pytest

from lorescape_backend.social.publisher import run_publish_job

TARGET = date(2026, 7, 6)
DATE_STR = "2026-07-06"
URLS = ["https://x/wander/2026-07-06/slide_01.jpg",
        "https://x/wander/2026-07-06/slide_02.jpg"]


def _prerendered_row(**overrides):
    base = dict(
        publish_date=DATE_STR,
        media_type="carousel",
        status="pending",
        discord_message_id="msg-c-1",
        slide_urls=list(URLS),
        caption="今天的故事 #lorescape",
    )
    base.update(overrides)
    return base


@pytest.fixture
def mocks(fake_config):
    with (
        patch("lorescape_backend.social.publisher.create_client"),
        patch("lorescape_backend.social.publisher.post_log") as post_log,
        patch(
            "lorescape_backend.social.publisher.discord_review"
            ".check_reaction"
        ) as check,
        patch(
            "lorescape_backend.social.publisher.instagram.publish_carousel"
        ) as ig_pub,
        patch(
            "lorescape_backend.social.publisher._sync_story_state"
        ) as sync_state,
        patch(
            "lorescape_backend.social.publisher._load_pending_rows"
        ) as load_rows,
        patch(
            "lorescape_backend.social.publisher.discord_notify"
            ".notify_failure"
        ) as notify,
    ):
        class Namespace:
            pass

        ns = Namespace()
        ns.post_log = post_log
        ns.check = check
        ns.ig_pub = ig_pub
        ns.sync_state = sync_state
        ns.load_rows = load_rows
        ns.notify = notify
        ns.config = fake_config
        yield ns


def test_approved_prerendered_publishes_urls_with_stored_caption(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "post-1"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_called_once()
    kwargs = mocks.ig_pub.call_args.kwargs
    assert kwargs["image_urls"] == URLS
    assert kwargs["caption"] == "今天的故事 #lorescape"
    mocks.post_log.record_post.assert_called_once()
    assert mocks.post_log.record_post.call_args.kwargs["status"] == "published"
    mocks.sync_state.assert_called_once()
    assert mocks.sync_state.call_args.args[2] == "published"
    mocks.load_rows.assert_not_called()  # 絕不 fall through


def test_rejected_prerendered_marks_rejected_and_syncs(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "rejected"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.mark_status.assert_called_once()
    assert mocks.post_log.mark_status.call_args.kwargs["status"] == "rejected"
    assert mocks.sync_state.call_args.args[2] == "rejected"
    mocks.load_rows.assert_not_called()


def test_no_reaction_marks_skipped(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "none"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_not_called()
    assert mocks.post_log.mark_status.call_args.kwargs["status"] == "skipped"
    assert mocks.sync_state.call_args.args[2] == "skipped"


@pytest.mark.parametrize("status", ["published", "rejected", "skipped"])
def test_terminal_prerendered_row_is_untouched_and_blocks_default(
    mocks, status
):
    mocks.post_log.get_post.return_value = _prerendered_row(status=status)

    run_publish_job(mocks.config, TARGET)

    mocks.check.assert_not_called()
    mocks.ig_pub.assert_not_called()
    mocks.load_rows.assert_not_called()


def test_publish_failure_records_failed_and_notifies(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"
    mocks.ig_pub.side_effect = RuntimeError("boom")

    run_publish_job(mocks.config, TARGET)

    assert mocks.post_log.record_post.call_args.kwargs["status"] == "failed"
    assert mocks.sync_state.call_args.args[2] == "failed"
    mocks.notify.assert_called_once()


def test_failed_prerendered_row_retries_when_approved(mocks):
    mocks.post_log.get_post.return_value = _prerendered_row(status="failed")
    mocks.check.return_value = "approved"
    mocks.ig_pub.return_value = "post-2"

    run_publish_job(mocks.config, TARGET)

    mocks.ig_pub.assert_called_once()


def test_row_without_slide_urls_falls_through_to_default_flow(mocks):
    """一般 carousel outcome row（slide_urls 為 NULL）不觸發預渲染分支."""
    mocks.post_log.get_post.return_value = _prerendered_row(slide_urls=None)
    mocks.load_rows.return_value = []

    run_publish_job(mocks.config, TARGET)

    mocks.load_rows.assert_called_once()
    mocks.ig_pub.assert_not_called()


def test_dry_run_prints_without_publishing(mocks, capsys):
    mocks.post_log.get_post.return_value = _prerendered_row()
    mocks.check.return_value = "approved"

    run_publish_job(mocks.config, TARGET, dry_run=True)

    mocks.ig_pub.assert_not_called()
    mocks.post_log.record_post.assert_not_called()
    mocks.sync_state.assert_not_called()
    out = capsys.readouterr().out
    assert "approved" in out
    assert URLS[0] in out


def test_dry_run_without_prerendered_row_skips_default_flow(mocks, capsys):
    mocks.post_log.get_post.return_value = None

    run_publish_job(mocks.config, TARGET, dry_run=True)

    mocks.load_rows.assert_not_called()
    mocks.ig_pub.assert_not_called()
    assert "no pre-rendered carousel" in capsys.readouterr().out
