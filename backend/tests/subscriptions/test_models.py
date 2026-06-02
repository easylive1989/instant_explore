"""Tests for RevenueCat webhook payload parsing."""
from __future__ import annotations

from datetime import datetime, timezone

from lorescape_backend.subscriptions.models import parse_webhook


def _event(**overrides) -> dict:
    event = {
        "type": "INITIAL_PURCHASE",
        "app_user_id": "user-1",
        "product_id": "premium_monthly",
        "entitlement_ids": ["premium"],
        "expiration_at_ms": 1_700_000_000_000,
        "event_timestamp_ms": 1_699_000_000_000,
        "id": "evt-1",
    }
    event.update(overrides)
    return {"api_version": "1.0", "event": event}


def test_parse_initial_purchase_is_active():
    parsed = parse_webhook(_event())

    assert parsed is not None
    assert parsed.user_id == "user-1"
    assert parsed.is_active is True
    assert parsed.product_id == "premium_monthly"
    assert parsed.entitlement == "premium"
    assert parsed.event_id == "evt-1"
    assert parsed.expires_at == datetime.fromtimestamp(
        1_700_000_000, tz=timezone.utc
    )
    assert parsed.event_at == datetime.fromtimestamp(
        1_699_000_000, tz=timezone.utc
    )


def test_parse_expiration_is_inactive():
    parsed = parse_webhook(_event(type="EXPIRATION"))
    assert parsed is not None
    assert parsed.is_active is False


def test_parse_cancellation_stays_active_until_expiry():
    # Cancellation only stops auto-renew; the user keeps access until expiry.
    parsed = parse_webhook(_event(type="CANCELLATION"))
    assert parsed is not None
    assert parsed.is_active is True


def test_parse_falls_back_to_singular_entitlement_id():
    payload = _event()
    del payload["event"]["entitlement_ids"]
    payload["event"]["entitlement_id"] = "premium"

    parsed = parse_webhook(payload)
    assert parsed is not None
    assert parsed.entitlement == "premium"


def test_parse_returns_none_without_event():
    assert parse_webhook({"api_version": "1.0"}) is None


def test_parse_returns_none_without_app_user_id():
    payload = _event()
    del payload["event"]["app_user_id"]
    assert parse_webhook(payload) is None
