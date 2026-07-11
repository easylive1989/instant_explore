"""Shared pytest fixtures for the scripts test suite."""
from __future__ import annotations

import pytest

from lorescape_publisher.config import Config


@pytest.fixture
def fake_config() -> Config:
    """A Config with dummy non-empty values for testing."""
    return Config(
        supabase_url="https://test.supabase.co",
        supabase_service_role_key="test_service_role_key",
        gemini_api_key="test_gemini_key",
        discord_webhook_url="https://discord.com/api/webhooks/test",
        discord_bot_token="test_bot_token",
        discord_review_channel_id="111222333444555666",
        discord_approver_ids=("999888777666555444",),
        ig_user_id="ig_user_1",
        meta_page_access_token="meta_page_token",
        brand_handle_ig="@love.lorescape",
        cta_text="Explore more places with Lorescape.",
    )
