import pytest

from lorescape_backend.config import Config


def _baseline_env(monkeypatch):
    """Set required env vars so Config.from_env() doesn't bail out."""
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")


def test_from_env_loads_all_required(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("DISCORD_WEBHOOK_URL", "https://discord/wh")

    config = Config.from_env()

    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "key1"
    assert config.gemini_api_key == "key2"
    assert config.discord_webhook_url == "https://discord/wh"


def test_from_env_optionals_default_to_none_or_empty(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.delenv("DISCORD_WEBHOOK_URL", raising=False)
    monkeypatch.delenv("DISCORD_BOT_TOKEN", raising=False)
    monkeypatch.delenv("DISCORD_REVIEW_CHANNEL_ID", raising=False)
    monkeypatch.delenv("DISCORD_APPROVER_IDS", raising=False)
    monkeypatch.delenv("IG_USER_ID", raising=False)
    monkeypatch.delenv("META_PAGE_ACCESS_TOKEN", raising=False)
    monkeypatch.delenv("BRAND_HANDLE_IG", raising=False)

    config = Config.from_env()
    assert config.discord_webhook_url is None
    assert config.discord_bot_token is None
    assert config.discord_review_channel_id is None
    assert config.discord_approver_ids == ()
    assert config.ig_user_id is None
    assert config.meta_page_access_token is None
    assert config.brand_handle_ig == ""
    # CTA defaults to a non-empty branded sentence.
    assert config.cta_text


def test_from_env_parses_approver_ids_as_tuple(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111, 222 ,333,")
    assert Config.from_env().discord_approver_ids == ("111", "222", "333")


def test_review_enabled_requires_all_three(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("DISCORD_BOT_TOKEN", "tok")
    monkeypatch.setenv("DISCORD_REVIEW_CHANNEL_ID", "777")
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111")
    assert Config.from_env().review_enabled is True

    monkeypatch.delenv("DISCORD_APPROVER_IDS")
    assert Config.from_env().review_enabled is False


def test_instagram_enabled_flag(monkeypatch):
    _baseline_env(monkeypatch)
    config = Config.from_env()
    assert config.instagram_enabled is False

    monkeypatch.setenv("IG_USER_ID", "i")
    monkeypatch.setenv("META_PAGE_ACCESS_TOKEN", "p")
    config = Config.from_env()
    assert config.instagram_enabled is True


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")

    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()
