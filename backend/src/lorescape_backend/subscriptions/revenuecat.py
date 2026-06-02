"""Thin RevenueCat REST client used by the reconcile job."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote

import requests

_BASE_URL = "https://api.revenuecat.com/v1"
_TIMEOUT_SECONDS = 15


@dataclass(frozen=True)
class SubscriberStatus:
    """The current entitlement state for one app user, per RevenueCat."""

    is_active: bool
    expires_at: datetime | None
    product_id: str | None
    entitlement: str | None


def _parse_iso(value: object) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


class RevenueCatClient:
    """Reads subscriber status from the RevenueCat REST API."""

    def __init__(self, api_key: str, session: requests.Session | None = None):
        self._api_key = api_key
        self._session = session or requests.Session()

    def get_subscriber(self, app_user_id: str) -> SubscriberStatus:
        """Fetch and reduce a subscriber's entitlements to a single status.

        A subscriber is active when they hold at least one entitlement whose
        ``expires_date`` is absent (lifetime) or still in the future.
        """
        response = self._session.get(
            f"{_BASE_URL}/subscribers/{quote(app_user_id, safe='')}",
            headers={"Authorization": f"Bearer {self._api_key}"},
            timeout=_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        entitlements = (
            response.json().get("subscriber", {}).get("entitlements", {})
        )

        now = datetime.now(tz=timezone.utc)
        best: SubscriberStatus | None = None
        for name, info in entitlements.items():
            if not isinstance(info, dict):
                continue
            expires_at = _parse_iso(info.get("expires_date"))
            active = expires_at is None or expires_at > now
            candidate = SubscriberStatus(
                is_active=active,
                expires_at=expires_at,
                product_id=info.get("product_identifier"),
                entitlement=name,
            )
            # Prefer an active entitlement over an expired one.
            if active:
                return candidate
            best = best or candidate

        return best or SubscriberStatus(
            is_active=False,
            expires_at=None,
            product_id=None,
            entitlement=None,
        )
