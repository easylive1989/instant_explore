"""bot.interactions 狀態轉移測試。"""
from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import patch

from lorescape_backend.social.bot import interactions
from tests._fakes import FakeSupabase


def _pending(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="pending",
        discord_message_id="m1", review_decision=None, scheduled_at=None,
        ig_post_id=None, slide_urls=["u"], caption="c",
    )
    base.update(o)
    return base


def test_approve_sets_decision_only():
    sb = FakeSupabase([_pending()])
    interactions.approve(
        sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert sb.rows[0]["review_decision"] == "approved"
    assert sb.rows[0]["status"] == "pending"  # 未動 status


def test_reject_sets_status_rejected():
    sb = FakeSupabase([_pending()])
    interactions.reject(
        sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert sb.rows[0]["review_decision"] == "rejected"
    assert sb.rows[0]["status"] == "rejected"


def test_schedule_sets_time_and_scheduled_status():
    sb = FakeSupabase([_pending()])
    when = datetime(2026, 7, 9, 13, 0, tzinfo=timezone.utc)
    interactions.schedule(
        sb, publish_date="2026-07-09", media_type="carousel",
        scheduled_at=when,
    )
    assert sb.rows[0]["status"] == "scheduled"
    assert sb.rows[0]["scheduled_at"] == when.isoformat()


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_publish_now_approves_then_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_pending()])
    ok = interactions.publish_now(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert ok is True
    assert sb.rows[0]["review_decision"] == "approved"
    mock_pub.assert_called_once()
    # 確認送進 publish_row 的是「approve 之後重新載入」的那一列。
    passed = mock_pub.call_args.args[2]
    assert passed["review_decision"] == "approved"


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_publish_now_returns_false_when_row_missing(mock_pub, fake_config):
    sb = FakeSupabase()
    ok = interactions.publish_now(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert ok is False
    mock_pub.assert_not_called()


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_republish_resets_terminal_and_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_pending(
        status="failed", review_decision="approved", ig_post_id="ig-old",
    )])
    ok = interactions.republish(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
    )
    assert ok is True
    mock_pub.assert_called_once()
    # publish_row 收到的是重置後的「本地副本」。
    passed = mock_pub.call_args.args[2]
    assert passed["status"] == "pending"
    assert passed["ig_post_id"] is None
    # 但底層儲存體本身沒被動到（證明 republish 只改本地副本）。
    assert sb.rows[0]["status"] == "failed"
    assert sb.rows[0]["ig_post_id"] == "ig-old"


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_republish_returns_false_when_row_missing(mock_pub, fake_config):
    sb = FakeSupabase()
    ok = interactions.republish(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
    )
    assert ok is False
    mock_pub.assert_not_called()
