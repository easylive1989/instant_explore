"""Tests for the subscription reconcile sweep."""
from __future__ import annotations

from datetime import datetime, timezone

from lorescape_backend.subscriptions.reconcile import reconcile_subscriptions
from lorescape_backend.subscriptions.revenuecat import SubscriberStatus

from .fakes import FakeSubscriptionRepository

_NOW = datetime(2026, 6, 1, tzinfo=timezone.utc)


class _FakeRevenueCatClient:
    def __init__(self, statuses: dict[str, SubscriberStatus],
                 errors: set[str] | None = None) -> None:
        self._statuses = statuses
        self._errors = errors or set()
        self.seen: list[str] = []

    def get_subscriber(self, user_id: str) -> SubscriberStatus:
        self.seen.append(user_id)
        if user_id in self._errors:
            raise RuntimeError("revenuecat unavailable")
        return self._statuses[user_id]


def _status(active: bool) -> SubscriberStatus:
    return SubscriberStatus(
        is_active=active,
        expires_at=datetime(2026, 7, 1, tzinfo=timezone.utc),
        product_id="premium_monthly",
        entitlement="premium",
    )


def test_reconcile_applies_revenuecat_truth_for_each_user():
    repo = FakeSubscriptionRepository(user_ids=["a", "b"])
    client = _FakeRevenueCatClient(
        {"a": _status(True), "b": _status(False)}
    )

    count = reconcile_subscriptions(repo, client, now=_NOW)

    assert count == 2
    applied = {e.user_id: e for e in repo.applied}
    assert applied["a"].is_active is True
    assert applied["b"].is_active is False
    # Reconcile stamps a fresh event_at so it always wins ordering.
    assert applied["a"].event_at == _NOW
    assert applied["a"].event_id.startswith("reconcile:")


def test_reconcile_skips_users_that_error_without_aborting():
    repo = FakeSubscriptionRepository(user_ids=["a", "b", "c"])
    client = _FakeRevenueCatClient(
        {"a": _status(True), "c": _status(True)}, errors={"b"}
    )

    count = reconcile_subscriptions(repo, client, now=_NOW)

    assert count == 2
    assert {e.user_id for e in repo.applied} == {"a", "c"}
    assert client.seen == ["a", "b", "c"]
