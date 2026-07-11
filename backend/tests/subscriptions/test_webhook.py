"""Tests for the RevenueCat webhook route."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.testclient import TestClient

from lorescape_backend.config import Config
from lorescape_backend.dependencies import get_config
from lorescape_backend.subscriptions.routes import (
    get_subscription_repository,
    router,
)

from .fakes import FakeSubscriptionRepository

_WEBHOOK_TOKEN = "secret-token"


def _config(webhook_token: str | None = _WEBHOOK_TOKEN) -> Config:
    return Config(
        supabase_url="x",
        supabase_service_role_key="x",
        gemini_api_key="x",
        revenuecat_webhook_auth_token=webhook_token,
    )


def _make_app(repo: FakeSubscriptionRepository, *,
              webhook_token: str | None = _WEBHOOK_TOKEN) -> FastAPI:
    app = FastAPI()
    app.include_router(router)
    app.dependency_overrides[get_config] = lambda: _config(webhook_token)
    app.dependency_overrides[get_subscription_repository] = lambda: repo
    return app


def _payload(app_user_id: str = "user-1") -> dict:
    return {
        "api_version": "1.0",
        "event": {
            "type": "INITIAL_PURCHASE",
            "app_user_id": app_user_id,
            "product_id": "premium_monthly",
            "entitlement_ids": ["premium"],
            "expiration_at_ms": 1_700_000_000_000,
            "event_timestamp_ms": 1_699_000_000_000,
            "id": "evt-1",
        },
    }


def test_valid_event_is_persisted():
    repo = FakeSubscriptionRepository()
    client = TestClient(_make_app(repo))

    res = client.post(
        "/webhooks/revenuecat",
        json=_payload(),
        headers={"Authorization": _WEBHOOK_TOKEN},
    )

    assert res.status_code == 200
    assert res.json() == {"status": "ok"}
    assert len(repo.applied) == 1
    assert repo.applied[0].user_id == "user-1"


def test_wrong_auth_token_is_rejected():
    repo = FakeSubscriptionRepository()
    client = TestClient(_make_app(repo))

    res = client.post(
        "/webhooks/revenuecat",
        json=_payload(),
        headers={"Authorization": "wrong"},
    )

    assert res.status_code == 401
    assert repo.applied == []


def test_missing_auth_header_is_rejected():
    repo = FakeSubscriptionRepository()
    client = TestClient(_make_app(repo))

    res = client.post("/webhooks/revenuecat", json=_payload())

    assert res.status_code == 401
    assert repo.applied == []


def test_webhook_disabled_returns_503():
    repo = FakeSubscriptionRepository()
    client = TestClient(_make_app(repo, webhook_token=None))

    res = client.post(
        "/webhooks/revenuecat",
        json=_payload(),
        headers={"Authorization": "anything"},
    )

    assert res.status_code == 503
    assert repo.applied == []


def test_unparseable_payload_is_acknowledged_but_ignored():
    repo = FakeSubscriptionRepository()
    client = TestClient(_make_app(repo))

    res = client.post(
        "/webhooks/revenuecat",
        json={"api_version": "1.0"},
        headers={"Authorization": _WEBHOOK_TOKEN},
    )

    assert res.status_code == 200
    assert res.json() == {"status": "ignored"}
    assert repo.applied == []
