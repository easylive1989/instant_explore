"""Tests for publisher Config."""
from __future__ import annotations

import pytest

from lorescape_publisher.config import Config

_REQUIRED = {
    "SUPABASE_URL": "https://x.supabase.co",
    "SUPABASE_SERVICE_ROLE_KEY": "srk",
    "GEMINI_API_KEY": "gk",
}

# Vars that must not leak in from the operator's shell/.env, so every test
# starts from a clean slate regardless of what's loaded outside pytest.
# Same technique as backend/tests/test_config.py's _baseline_env.
_OPTIONAL_ENV_VARS = (
    "GEMINI_BACKEND",
    "GOOGLE_CLOUD_PROJECT",
    "GOOGLE_CLOUD_LOCATION",
    "DISCORD_WEBHOOK_URL",
    "DISCORD_BOT_TOKEN",
    "DISCORD_REVIEW_CHANNEL_ID",
    "DISCORD_APPROVER_IDS",
    "IG_USER_ID",
    "META_PAGE_ACCESS_TOKEN",
    "BRAND_HANDLE_IG",
    "DAILY_STORY_ENABLED",
    "DAILY_STORY_GENERATE_ENABLED",
    "DAILY_STORY_PUBLISH_ENABLED",
    "DAILY_VIDEO_DIR",
)


def _set_required(monkeypatch):
    for key, value in _REQUIRED.items():
        monkeypatch.setenv(key, value)
    for key in _OPTIONAL_ENV_VARS:
        monkeypatch.delenv(key, raising=False)


def test_from_env_loads_required(monkeypatch):
    _set_required(monkeypatch)
    config = Config.from_env()
    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "srk"
    assert config.gemini_api_key == "gk"


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "srk")
    monkeypatch.setenv("GEMINI_API_KEY", "gk")
    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()


def test_from_env_parses_approver_ids_as_tuple(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111, 222 ,333")
    config = Config.from_env()
    assert config.discord_approver_ids == ("111", "222", "333")


def test_review_enabled_requires_all_three(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DISCORD_BOT_TOKEN", "t")
    monkeypatch.setenv("DISCORD_REVIEW_CHANNEL_ID", "c")
    monkeypatch.delenv("DISCORD_APPROVER_IDS", raising=False)
    assert Config.from_env().review_enabled is False
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111")
    assert Config.from_env().review_enabled is True


def test_instagram_enabled_flag(monkeypatch):
    _set_required(monkeypatch)
    assert Config.from_env().instagram_enabled is False
    monkeypatch.setenv("IG_USER_ID", "ig1")
    monkeypatch.setenv("META_PAGE_ACCESS_TOKEN", "tok")
    assert Config.from_env().instagram_enabled is True


def test_daily_story_defaults_on_and_kill_switch(monkeypatch):
    _set_required(monkeypatch)
    assert Config.from_env().daily_story_enabled is True
    monkeypatch.setenv("DAILY_STORY_ENABLED", "0")
    config = Config.from_env()
    assert config.daily_story_enabled is False
    assert config.daily_story_generate_enabled is False
    assert config.daily_story_publish_enabled is False


def test_per_job_flags_override_master_switch(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DAILY_STORY_ENABLED", "0")
    monkeypatch.setenv("DAILY_STORY_PUBLISH_ENABLED", "1")
    config = Config.from_env()
    assert config.daily_story_generate_enabled is False
    assert config.daily_story_publish_enabled is True


def test_gemini_backend_vertex_requires_project_not_key(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "srk")
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setenv("GEMINI_BACKEND", "vertex")
    monkeypatch.delenv("GOOGLE_CLOUD_PROJECT", raising=False)
    with pytest.raises(RuntimeError, match="GOOGLE_CLOUD_PROJECT"):
        Config.from_env()
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", "proj-1")
    config = Config.from_env()
    assert config.gemini_backend == "vertex"
    assert config.gemini_api_key is None
