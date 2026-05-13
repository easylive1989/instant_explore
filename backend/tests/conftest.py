"""Shared pytest fixtures."""
from __future__ import annotations

import pytest

from lorescape_backend.config import Config


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
        threads_user_id="threads_user_1",
        threads_access_token="threads_token",
        ig_user_id="ig_user_1",
        meta_page_access_token="meta_page_token",
        brand_handle_threads="@instant_explore",
        brand_handle_ig="@instant_explore",
        cta_text="Explore more places with Instant Explore.",
    )
