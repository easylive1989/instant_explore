"""social_posts helper tests."""
from __future__ import annotations

from unittest.mock import MagicMock

from lorescape_backend.social import post_log


def _client():
    client = MagicMock()
    table = client.table.return_value
    table.upsert.return_value.execute.return_value = MagicMock(data=None)
    update_chain = table.update.return_value
    update_chain.eq.return_value = update_chain
    update_chain.execute.return_value = MagicMock(data=None)
    return client, table


def test_record_post_upserts_outcome_with_published_at():
    client, table = _client()

    post_log.record_post(
        client,
        publish_date="2026-07-05",
        media_type="reel",
        status="published",
        ig_post_id="ig-1",
    )

    payload, = table.upsert.call_args.args
    assert payload["status"] == "published"
    assert payload["ig_post_id"] == "ig-1"
    assert payload["published_at"] is not None
    # discord_message_id is not in the payload, so the upsert preserves it.
    assert "discord_message_id" not in payload
    assert (
        table.upsert.call_args.kwargs["on_conflict"]
        == "publish_date,media_type"
    )


def test_record_post_failed_has_no_published_at():
    client, table = _client()

    post_log.record_post(
        client,
        publish_date="2026-07-05",
        media_type="carousel",
        status="failed",
        error="boom",
    )

    payload, = table.upsert.call_args.args
    assert payload["status"] == "failed"
    assert payload["error"] == "boom"
    assert payload["published_at"] is None


def test_record_review_pending_resets_prior_outcome():
    client, table = _client()

    post_log.record_review_pending(
        client,
        publish_date="2026-07-05",
        media_type="reel",
        discord_message_id="msg-1",
    )

    payload, = table.upsert.call_args.args
    assert payload["status"] == "pending"
    assert payload["discord_message_id"] == "msg-1"
    assert payload["ig_post_id"] is None
    assert payload["error"] is None
    assert payload["published_at"] is None


def test_mark_status_updates_by_date_and_type():
    client, table = _client()

    post_log.mark_status(
        client,
        publish_date="2026-07-05",
        media_type="reel",
        status="skipped",
    )

    payload, = table.update.call_args.args
    assert payload == {"status": "skipped"}
    eq_calls = table.update.return_value.eq.call_args_list
    assert ("publish_date", "2026-07-05") in [c.args for c in eq_calls]


def test_get_post_returns_row_or_none():
    client, table = _client()
    select_chain = table.select.return_value
    select_chain.eq.return_value = select_chain
    select_chain.limit.return_value = select_chain
    select_chain.execute.return_value = MagicMock(
        data=[{"status": "pending"}]
    )

    row = post_log.get_post(client, "2026-07-05", "reel")

    assert row == {"status": "pending"}


def test_record_review_pending_carries_slide_urls_and_caption():
    client, table = _client()

    post_log.record_review_pending(
        client,
        publish_date="2026-07-06",
        media_type="carousel",
        discord_message_id="msg-1",
        slide_urls=["https://x/1.jpg", "https://x/2.jpg"],
        caption="今天的故事",
    )

    payload, = table.upsert.call_args.args
    assert payload["slide_urls"] == ["https://x/1.jpg", "https://x/2.jpg"]
    assert payload["caption"] == "今天的故事"
    assert payload["status"] == "pending"


def test_record_review_pending_defaults_keep_reel_payload_nullable():
    client, table = _client()

    post_log.record_review_pending(
        client,
        publish_date="2026-07-06",
        media_type="reel",
        discord_message_id="msg-2",
    )

    payload, = table.upsert.call_args.args
    assert payload["slide_urls"] is None
    assert payload["caption"] is None


def test_stage_pending_upserts_clean_pending_row():
    client, table = _client()

    post_log.stage_pending(
        client,
        publish_date="2026-07-09",
        media_type="carousel",
        slide_urls=["https://x/1.jpg"],
        caption="cap",
    )

    payload, = table.upsert.call_args.args
    assert payload["status"] == "pending"
    assert payload["discord_message_id"] is None
    assert payload["review_decision"] is None
    assert payload["scheduled_at"] is None
    assert payload["overdue_notified_at"] is None
    assert payload["slide_urls"] == ["https://x/1.jpg"]
    assert payload["caption"] == "cap"
    assert (
        table.upsert.call_args.kwargs["on_conflict"]
        == "publish_date,media_type"
    )


def test_set_review_decision_writes_decision_and_reviewer():
    client, table = _client()

    post_log.set_review_decision(
        client,
        publish_date="2026-07-09",
        media_type="carousel",
        decision="approved",
        reviewed_by="user-1",
    )

    payload = table.update.call_args.args[0]
    assert payload["review_decision"] == "approved"
    assert payload["reviewed_by"] == "user-1"
    assert payload["reviewed_at"] is not None


def test_set_schedule_sets_scheduled_status():
    client, table = _client()

    post_log.set_schedule(
        client,
        publish_date="2026-07-09",
        media_type="reel",
        scheduled_at="2026-07-09T13:00:00+00:00",
    )

    payload = table.update.call_args.args[0]
    assert payload["scheduled_at"] == "2026-07-09T13:00:00+00:00"
    assert payload["status"] == "scheduled"


def test_list_pending_unposted_filters_status_and_null_message():
    client = MagicMock()
    chain = client.table.return_value.select.return_value
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "r1"}])

    rows = post_log.list_pending_unposted(client)

    assert rows == [{"id": "r1"}]
    chain.eq.assert_any_call("status", "pending")
    chain.is_.assert_any_call("discord_message_id", "null")


def test_list_scheduled_due_filters_status_and_time():
    client = MagicMock()
    chain = client.table.return_value.select.return_value
    chain.eq.return_value = chain
    chain.lte.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "r2"}])

    rows = post_log.list_scheduled_due(client, "2026-07-09T13:00:00+00:00")

    assert rows == [{"id": "r2"}]
    chain.eq.assert_any_call("status", "scheduled")
    chain.lte.assert_any_call("scheduled_at", "2026-07-09T13:00:00+00:00")
