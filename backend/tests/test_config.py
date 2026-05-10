import os
import pytest

from lorescape_backend.config import Config


def test_from_env_loads_all_required(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord/wh")

    config = Config.from_env()

    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "key1"
    assert config.gemini_api_key == "key2"
    assert config.discord_webhook_url == "https://discord/wh"


def test_from_env_discord_webhook_optional(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")
    monkeypatch.delenv("DISCORD_WEBHOOK_URL", raising=False)

    config = Config.from_env()
    assert config.discord_webhook_url is None


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")

    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()
