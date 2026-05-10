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
    )
