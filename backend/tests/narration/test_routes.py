from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from lorescape_backend.config import Config
from lorescape_backend.narration.models import (
    HookItem,
    HooksResponse,
    NarrationResponse,
)
from lorescape_backend.narration.routes import get_config, router


def _fake_config() -> Config:
    return Config(
        supabase_url="x",
        supabase_service_role_key="x",
        gemini_api_key="test-key",
        discord_webhook_url=None,
        discord_bot_token=None,
        discord_review_channel_id=None,
        discord_approver_ids=(),
        threads_user_id=None,
        threads_access_token=None,
        ig_user_id=None,
        meta_page_access_token=None,
        brand_handle_threads="",
        brand_handle_ig="",
        cta_text="",
    )


def _make_app() -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    app.dependency_overrides[get_config] = _fake_config
    return app


@patch("lorescape_backend.narration.routes.service.generate_hooks")
def test_post_hooks_returns_payload(gen_hooks):
    gen_hooks.return_value = HooksResponse(
        hooks=[HookItem(id="h1", title="T1", teaser="Te1")],
        insufficient_source=False,
    )
    client = TestClient(_make_app())

    response = client.post(
        "/narration/hooks",
        json={
            "place_name": "Arles",
            "location": "Provence",
            "wikipedia_title": "Arles",
            "language": "zh-TW",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["hooks"][0]["id"] == "h1"
    assert body["insufficient_source"] is False
    # The route MUST pass the gemini key from config to the service.
    assert gen_hooks.call_args.kwargs["api_key"] == "test-key"


@patch("lorescape_backend.narration.routes.service.generate_narration")
def test_post_narration_returns_payload(gen_narration):
    gen_narration.return_value = NarrationResponse(
        place_name="亞爾",
        location="法國普羅旺斯",
        era="十九世紀末",
        paragraphs=["一", "二", "三"],
        pull_quote="",
        insufficient_source=False,
    )
    client = TestClient(_make_app())

    response = client.post(
        "/narration",
        json={
            "place_name": "Arles",
            "location": "Provence",
            "wikipedia_title": "Arles",
            "language": "zh-TW",
            "hook": {"id": "h", "title": "梵谷", "teaser": "444 天"},
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["place_name"] == "亞爾"
    assert body["paragraphs"] == ["一", "二", "三"]
    assert body["insufficient_source"] is False


def test_post_hooks_rejects_unsupported_language():
    client = TestClient(_make_app())
    response = client.post(
        "/narration/hooks",
        json={
            "place_name": "x",
            "wikipedia_title": "x",
            "language": "ja",
        },
    )
    assert response.status_code == 400


def test_post_narration_rejects_unsupported_language():
    client = TestClient(_make_app())
    response = client.post(
        "/narration",
        json={
            "place_name": "x",
            "wikipedia_title": "x",
            "language": "ja",
        },
    )
    assert response.status_code == 400
