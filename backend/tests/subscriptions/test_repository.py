"""Tests for the Supabase-backed subscription repository."""
from __future__ import annotations

from datetime import datetime, timezone

from lorescape_backend.subscriptions.models import SubscriptionEvent
from lorescape_backend.subscriptions.repository import SubscriptionRepository

from .fakes import FakeSupabaseClient


def _event(**overrides) -> SubscriptionEvent:
    base = {
        "user_id": "user-1",
        "is_active": True,
        "product_id": "premium_monthly",
        "entitlement": "premium",
        "expires_at": datetime(2026, 1, 1, tzinfo=timezone.utc),
        "event_id": "evt-1",
        "event_at": datetime(2025, 12, 1, tzinfo=timezone.utc),
        "raw": {"k": "v"},
    }
    base.update(overrides)
    return SubscriptionEvent(**base)


def test_apply_event_calls_rpc_with_iso_timestamps():
    client = FakeSupabaseClient()
    repo = SubscriptionRepository(client)

    repo.apply_event(_event())

    assert len(client.rpc_calls) == 1
    name, params = client.rpc_calls[0]
    assert name == "apply_subscription_event"
    assert params["p_user_id"] == "user-1"
    assert params["p_is_active"] is True
    assert params["p_expires_at"] == "2026-01-01T00:00:00+00:00"
    assert params["p_event_at"] == "2025-12-01T00:00:00+00:00"
    assert params["p_raw_event"] == {"k": "v"}


def test_apply_event_passes_none_for_missing_timestamps():
    client = FakeSupabaseClient()
    repo = SubscriptionRepository(client)

    repo.apply_event(_event(expires_at=None, event_at=None))

    _, params = client.rpc_calls[0]
    assert params["p_expires_at"] is None
    assert params["p_event_at"] is None


def test_is_subscribed_reflects_rpc_result():
    assert SubscriptionRepository(
        FakeSupabaseClient(subscribed=True)
    ).is_subscribed("user-1") is True
    assert SubscriptionRepository(
        FakeSupabaseClient(subscribed=False)
    ).is_subscribed("user-1") is False


def test_list_user_ids_reads_subscriptions_table():
    client = FakeSupabaseClient(user_ids=["a", "b", "c"])
    repo = SubscriptionRepository(client)

    assert repo.list_user_ids() == ["a", "b", "c"]
