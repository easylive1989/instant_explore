"""executor.publish_row 發布行為測試。"""
from __future__ import annotations

import dataclasses
from unittest.mock import MagicMock, patch

import pytest

from lorescape_backend.social import executor


def _client():
    client = MagicMock()
    table = client.table.return_value
    table.upsert.return_value.execute.return_value = MagicMock(data=None)
    return client, table


def _carousel_row(**overrides):
    base = dict(
        id="r1", publish_date="2026-07-09", media_type="carousel",
        status="scheduled", review_decision="approved",
        slide_urls=["https://x/1.jpg", "https://x/2.jpg"],
        caption="cap", ig_post_id=None,
    )
    base.update(overrides)
    return base


@patch("lorescape_backend.social.executor.instagram.publish_carousel",
       return_value="ig-123")
def test_publish_carousel_row_publishes_and_records(mock_pub, fake_config):
    client, table = _client()

    ok = executor.publish_carousel_row(fake_config, client, _carousel_row())

    assert ok is True
    mock_pub.assert_called_once()
    kwargs = mock_pub.call_args.kwargs
    assert kwargs["image_urls"] == ["https://x/1.jpg", "https://x/2.jpg"]
    assert kwargs["caption"] == "cap"
    payload, = table.upsert.call_args.args
    assert payload["status"] == "published"
    assert payload["ig_post_id"] == "ig-123"


@patch("lorescape_backend.social.executor.instagram.publish_carousel",
       side_effect=RuntimeError("boom"))
def test_publish_carousel_row_records_failure(mock_pub, fake_config):
    client, table = _client()

    ok = executor.publish_carousel_row(fake_config, client, _carousel_row())

    assert ok is False
    payload, = table.upsert.call_args.args
    assert payload["status"] == "failed"
    assert "boom" in payload["error"]


@patch("lorescape_backend.social.executor.instagram.publish_carousel")
def test_publish_row_skips_already_published(mock_pub, fake_config):
    client, _ = _client()

    ok = executor.publish_row(
        fake_config, client, _carousel_row(ig_post_id="ig-old"),
    )

    assert ok is True
    mock_pub.assert_not_called()


@patch("lorescape_backend.social.executor.instagram.publish_carousel")
def test_publish_carousel_row_noops_when_ig_disabled(mock_pub):
    from lorescape_backend.config import Config
    config = Config(
        supabase_url="u", supabase_service_role_key="k", gemini_api_key="g",
        discord_webhook_url=None, discord_bot_token=None,
        discord_review_channel_id=None, discord_approver_ids=(),
        ig_user_id=None, meta_page_access_token=None,
        brand_handle_ig="", cta_text="",
    )
    client, table = _client()

    ok = executor.publish_carousel_row(config, client, _carousel_row())

    assert ok is False
    mock_pub.assert_not_called()
