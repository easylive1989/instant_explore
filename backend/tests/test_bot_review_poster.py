"""bot.review_poster.tick 測試。"""
from __future__ import annotations

from lorescape_backend.social.bot import review_poster
from tests._fakes import FakeSupabase


def _pending(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="pending",
        discord_message_id=None, slide_urls=["u"], caption="c",
    )
    base.update(o)
    return base


def test_posts_and_backfills_message_id():
    sb = FakeSupabase([_pending()])
    review_poster.tick(sb, post_review=lambda row: "msg-77")
    assert sb.rows[0]["discord_message_id"] == "msg-77"


def test_skips_when_poster_returns_none():
    sb = FakeSupabase([_pending()])
    review_poster.tick(sb, post_review=lambda row: None)
    assert sb.rows[0]["discord_message_id"] is None


def test_ignores_already_posted_rows():
    sb = FakeSupabase([_pending(discord_message_id="already")])
    calls = []
    review_poster.tick(sb, post_review=lambda row: calls.append(row) or "x")
    assert calls == []  # list_pending_unposted 已排除有 message id 的
