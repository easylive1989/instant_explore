"""Tests for the SubscriptionChecker live-fallback gate."""
from __future__ import annotations

from datetime import datetime, timezone

from lorescape_backend.subscriptions.revenuecat import SubscriberStatus
from lorescape_backend.subscriptions.service import SubscriptionChecker

from .fakes import FakeSubscriptionRepository

_NOW = datetime(2026, 6, 23, tzinfo=timezone.utc)


class _FakeRevenueCatClient:
    def __init__(self, status: SubscriberStatus | None = None,
                 error: bool = False) -> None:
        self._status = status
        self._error = error
        self.seen: list[str] = []

    def get_subscriber(self, user_id: str) -> SubscriberStatus:
        self.seen.append(user_id)
        if self._error:
            raise RuntimeError("revenuecat unavailable")
        assert self._status is not None
        return self._status


def _active() -> SubscriberStatus:
    return SubscriberStatus(
        is_active=True,
        expires_at=datetime(2026, 7, 1, tzinfo=timezone.utc),
        product_id="premium_annual",
        entitlement="premium",
    )


def _inactive() -> SubscriberStatus:
    return SubscriberStatus(
        is_active=False, expires_at=None, product_id=None, entitlement=None
    )


def test_local_hit_returns_true_without_live_call():
    repo = FakeSubscriptionRepository(subscribed=True)
    client = _FakeRevenueCatClient(_active())
    checker = SubscriptionChecker(repo, client, now_factory=lambda: _NOW)

    assert checker.is_subscribed("user-1") is True
    assert client.seen == []  # the local hit short-circuits
    assert repo.applied == []


def test_local_miss_without_client_returns_false():
    repo = FakeSubscriptionRepository(subscribed=False)
    checker = SubscriptionChecker(repo, None, now_factory=lambda: _NOW)

    assert checker.is_subscribed("user-1") is False
    assert repo.applied == []


def test_local_miss_with_active_live_heals_and_returns_true():
    repo = FakeSubscriptionRepository(subscribed=False)
    client = _FakeRevenueCatClient(_active())
    checker = SubscriptionChecker(repo, client, now_factory=lambda: _NOW)

    assert checker.is_subscribed("user-1") is True
    assert client.seen == ["user-1"]
    assert len(repo.applied) == 1
    event = repo.applied[0]
    assert event.user_id == "user-1"
    assert event.is_active is True
    assert event.entitlement == "premium"
    assert event.product_id == "premium_annual"
    assert event.event_at == _NOW
    assert event.event_id == f"live:{_NOW.isoformat()}"
    assert event.raw == {"source": "live"}


def test_local_miss_with_inactive_live_returns_false_without_healing():
    repo = FakeSubscriptionRepository(subscribed=False)
    client = _FakeRevenueCatClient(_inactive())
    checker = SubscriptionChecker(repo, client, now_factory=lambda: _NOW)

    assert checker.is_subscribed("user-1") is False
    assert client.seen == ["user-1"]
    assert repo.applied == []


def test_live_check_failure_fails_closed():
    repo = FakeSubscriptionRepository(subscribed=False)
    client = _FakeRevenueCatClient(error=True)
    checker = SubscriptionChecker(repo, client, now_factory=lambda: _NOW)

    assert checker.is_subscribed("user-1") is False
    assert repo.applied == []
