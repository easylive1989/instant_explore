"""Subscription gate that heals missing rows via a live RevenueCat check."""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Callable

from lorescape_backend.subscriptions.models import SubscriptionEvent
from lorescape_backend.subscriptions.repository import SubscriptionRepository
from lorescape_backend.subscriptions.revenuecat import RevenueCatClient

logger = logging.getLogger(__name__)


def _utc_now() -> datetime:
    return datetime.now(tz=timezone.utc)


class SubscriptionChecker:
    """Authoritative subscription gate for the narration endpoint.

    The local ``subscriptions`` table is only eventually consistent: it is
    written by RevenueCat webhooks and the nightly reconcile sweep, and the
    sweep can only refresh users that already have a row. A freshly purchased
    (or restored) user can therefore be entitled in the RevenueCat client SDK
    while the backend table still has no row — which would wrongly route them
    to the paywall.

    To close that gap, a negative local result falls back to a live RevenueCat
    REST lookup. A hit is written back via ``apply_event`` so later checks take
    the fast local path and the reconcile sweep keeps covering the user. The
    live lookup is skipped when RevenueCat REST is not configured
    (``revenuecat_client is None``), preserving the table-only behaviour.
    """

    def __init__(
        self,
        repository: SubscriptionRepository,
        revenuecat_client: RevenueCatClient | None = None,
        now_factory: Callable[[], datetime] = _utc_now,
    ) -> None:
        self._repository = repository
        self._client = revenuecat_client
        self._now = now_factory

    def is_subscribed(self, user_id: str) -> bool:
        """True if the user is entitled, healing the table on a live hit."""
        if self._repository.is_subscribed(user_id):
            return True
        if self._client is None:
            return False
        return self._verify_live(user_id)

    def _verify_live(self, user_id: str) -> bool:
        try:
            status = self._client.get_subscriber(user_id)
        except Exception:  # a RevenueCat outage must fail closed, not 500
            logger.exception(
                "Live RevenueCat check failed for user %s", user_id
            )
            return False
        if not status.is_active:
            return False

        now = self._now()
        self._repository.apply_event(
            SubscriptionEvent(
                user_id=user_id,
                is_active=True,
                product_id=status.product_id,
                entitlement=status.entitlement,
                expires_at=status.expires_at,
                event_id=f"live:{now.isoformat()}",
                event_at=now,
                raw={"source": "live"},
            )
        )
        logger.info(
            "Healed missing subscription row for user %s via live check",
            user_id,
        )
        return True
