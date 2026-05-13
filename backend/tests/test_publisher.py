"""publisher.run_publish_job state-machine tests."""
from __future__ import annotations

from datetime import date
from unittest.mock import MagicMock, patch

from lorescape_backend.social.publisher import run_publish_job


def _row(**overrides):
    base = dict(
        id="row-1",
        publish_date="2026-05-12",
        language="en",
        place_name="Colosseum",
        place_location="Rome",
        era="70-80 CE",
        story="story body",
        threads_summary="short",
        hashtags=["rome"],
        image_url="https://upload.wikimedia.org/x.jpg",
        wikipedia_url="https://en.wikipedia.org/wiki/Colosseum",
        review_state="pending",
        discord_message_id="msg-1",
    )
    base.update(overrides)
    return base


def _supabase_with_rows(rows):
    """Build a chained MagicMock matching supabase.table(...).select()...execute()."""
    select = MagicMock()
    select.eq.return_value = select
    select.execute.return_value = MagicMock(data=rows)

    update_chain = MagicMock()
    update_chain.eq.return_value = update_chain
    update_chain.execute.return_value = MagicMock(data=None)

    table = MagicMock()
    table.select.return_value = select
    table.update.return_value = update_chain

    client = MagicMock()
    client.table.return_value = table
    return client, table, update_chain


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
def test_approved_row_publishes_to_threads_and_ig(
    ig_pub, th_pub, check, create, fake_config
):
    rows = [_row()]
    client, table, update_chain = _supabase_with_rows(rows)
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"
    ig_pub.return_value = "ig-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_called_once()
    ig_pub.assert_called_once()
    update_payload = table.update.call_args[0][0]
    assert update_payload["review_state"] == "published"
    assert update_payload["threads_post_id"] == "th-1"
    assert update_payload["ig_post_id"] == "ig-1"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
def test_approved_row_without_image_skips_ig(
    ig_pub, th_pub, check, create, fake_config
):
    rows = [_row(image_url=None)]
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client
    check.return_value = "approved"
    th_pub.return_value = "th-1"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_called_once()
    ig_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "published"
    assert payload["threads_post_id"] == "th-1"
    assert payload["ig_post_id"] is None


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.instagram.publish")
def test_rejected_row_does_not_publish(
    ig_pub, th_pub, check, create, fake_config
):
    rows = [_row()]
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client
    check.return_value = "rejected"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_not_called()
    ig_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "rejected"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
def test_no_reaction_skips_row(th_pub, check, create, fake_config):
    rows = [_row()]
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client
    check.return_value = "none"

    run_publish_job(fake_config, date(2026, 5, 12))

    th_pub.assert_not_called()
    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "skipped"


@patch("lorescape_backend.social.publisher.create_client")
@patch("lorescape_backend.social.publisher.discord_review.check_reaction")
@patch("lorescape_backend.social.publisher.threads.publish")
@patch("lorescape_backend.social.publisher.discord_notify.notify_failure")
def test_publish_exception_marks_failed_and_notifies(
    notify, th_pub, check, create, fake_config
):
    rows = [_row()]
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client
    check.return_value = "approved"
    th_pub.side_effect = RuntimeError("API blew up")

    run_publish_job(fake_config, date(2026, 5, 12))

    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "failed"
    assert "API blew up" in payload["publish_error"]
    notify.assert_called_once()


@patch("lorescape_backend.social.publisher.create_client")
def test_no_pending_rows_does_nothing(create, fake_config):
    rows = []
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client

    run_publish_job(fake_config, date(2026, 5, 12))

    table.update.assert_not_called()


@patch("lorescape_backend.social.publisher.create_client")
def test_review_disabled_marks_pending_as_skipped(create):
    from lorescape_backend.config import Config

    config = Config(
        supabase_url="https://x", supabase_service_role_key="k",
        gemini_api_key="g", discord_webhook_url=None,
        discord_bot_token=None,  # review disabled
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id="u", threads_access_token="t",
        ig_user_id="i", meta_page_access_token="p",
        brand_handle_threads="", brand_handle_ig="", cta_text="",
    )
    rows = [_row()]
    client, table, _ = _supabase_with_rows(rows)
    create.return_value = client

    run_publish_job(config, date(2026, 5, 12))

    payload = table.update.call_args[0][0]
    assert payload["review_state"] == "skipped"
