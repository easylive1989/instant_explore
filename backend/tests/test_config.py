import pytest

from lorescape_backend.config import Config
from lorescape_backend.shared.genai import BACKEND_AI_STUDIO, BACKEND_VERTEX


def _baseline_env(monkeypatch):
    """Set required env vars so Config.from_env() doesn't bail out."""
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")
    # Default to the AI Studio backend unless a test opts into Vertex, so an
    # operator's GEMINI_BACKEND=vertex shell env can't leak into these tests.
    monkeypatch.delenv("GEMINI_BACKEND", raising=False)
    monkeypatch.delenv("GOOGLE_CLOUD_PROJECT", raising=False)
    monkeypatch.delenv("GOOGLE_CLOUD_LOCATION", raising=False)


def test_from_env_loads_all_required(monkeypatch):
    _baseline_env(monkeypatch)

    config = Config.from_env()

    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "key1"
    assert config.gemini_api_key == "key2"


def test_from_env_optionals_default_to_none_or_empty(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.delenv("REVENUECAT_WEBHOOK_AUTH_TOKEN", raising=False)
    monkeypatch.delenv("REVENUECAT_API_KEY", raising=False)

    config = Config.from_env()
    assert config.revenuecat_webhook_auth_token is None
    assert config.revenuecat_api_key is None
    assert config.revenuecat_webhook_enabled is False
    assert config.revenuecat_reconcile_enabled is False


def test_revenuecat_flags_enabled_when_set(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("REVENUECAT_WEBHOOK_AUTH_TOKEN", "whtok")
    monkeypatch.setenv("REVENUECAT_API_KEY", "rckey")

    config = Config.from_env()
    assert config.revenuecat_webhook_auth_token == "whtok"
    assert config.revenuecat_api_key == "rckey"
    assert config.revenuecat_webhook_enabled is True
    assert config.revenuecat_reconcile_enabled is True


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "key1")
    monkeypatch.setenv("GEMINI_API_KEY", "key2")

    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()


def test_narration_web_search_defaults_on_and_kill_switch(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.delenv("NARRATION_WEB_SEARCH", raising=False)
    assert Config.from_env().narration_web_search_enabled is True

    for off in ("0", "false", "off", "FALSE"):
        monkeypatch.setenv("NARRATION_WEB_SEARCH", off)
        assert Config.from_env().narration_web_search_enabled is False

    monkeypatch.setenv("NARRATION_WEB_SEARCH", "1")
    assert Config.from_env().narration_web_search_enabled is True


def test_gemini_backend_defaults_to_ai_studio(monkeypatch):
    _baseline_env(monkeypatch)
    config = Config.from_env()

    assert config.gemini_backend == BACKEND_AI_STUDIO
    assert config.gemini_api_key == "key2"
    settings = config.genai_settings
    assert settings.backend == BACKEND_AI_STUDIO
    assert settings.api_key == "key2"


def test_gemini_backend_vertex_requires_project_not_key(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("GEMINI_BACKEND", "vertex")
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", "instant-explore-7b442")
    monkeypatch.setenv("GOOGLE_CLOUD_LOCATION", "asia-east1")

    config = Config.from_env()

    assert config.gemini_backend == BACKEND_VERTEX
    assert config.gemini_api_key is None
    settings = config.genai_settings
    assert settings.backend == BACKEND_VERTEX
    assert settings.project == "instant-explore-7b442"
    assert settings.location == "asia-east1"


def test_gemini_backend_vertex_defaults_location(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("GEMINI_BACKEND", "vertex")
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", "p")

    assert Config.from_env().genai_settings.location == "us-central1"


def test_gemini_backend_vertex_missing_project_raises(monkeypatch):
    _baseline_env(monkeypatch)
    monkeypatch.setenv("GEMINI_BACKEND", "vertex")
    monkeypatch.delenv("GOOGLE_CLOUD_PROJECT", raising=False)

    with pytest.raises(RuntimeError, match="GOOGLE_CLOUD_PROJECT"):
        Config.from_env()
