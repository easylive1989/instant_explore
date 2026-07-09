"""bot.scheduler.tick 排程迴圈測試。"""
from __future__ import annotations

import dataclasses
from datetime import datetime, timezone
from unittest.mock import patch

from lorescape_backend.social.bot import scheduler
from tests._fakes import FakeSupabase

NOW = datetime(2026, 7, 9, 13, 0, tzinfo=timezone.utc)
PAST = "2026-07-09T12:00:00+00:00"
FUTURE = "2026-07-09T14:00:00+00:00"


def _row(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="scheduled",
        review_decision="approved", scheduled_at=PAST,
        overdue_notified_at=None, ig_post_id=None,
    )
    base.update(o)
    return base


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row",
       return_value=True)
def test_due_and_approved_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_row()])
    notes = []
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    mock_pub.assert_called_once()
    assert notes == []


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_due_but_unapproved_notifies_once(mock_pub, fake_config):
    sb = FakeSupabase([_row(review_decision=None)])
    notes = []
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    mock_pub.assert_not_called()
    assert len(notes) == 1  # 只提醒一次
    assert sb.rows[0]["overdue_notified_at"] is not None


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_not_due_is_ignored(mock_pub, fake_config):
    sb = FakeSupabase([_row(scheduled_at=FUTURE)])
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: None)
    mock_pub.assert_not_called()


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_publish_disabled_noops(mock_pub, fake_config):
    config = dataclasses.replace(fake_config, daily_story_publish_enabled=False)
    sb = FakeSupabase([_row()])
    scheduler.tick(config, sb, now=NOW, notify=lambda d, m: None)
    mock_pub.assert_not_called()
