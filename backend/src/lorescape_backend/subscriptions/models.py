"""Subscription event model shared by the webhook and reconcile flows."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

# RevenueCat event types that REVOKE entitlement immediately. Everything else
# (purchase, renewal, uncancellation, product change, cancellation — which
# only stops auto-renew — etc.) is treated as active; expiry is enforced
# separately via expires_at, so a cancelled-but-not-yet-expired user stays
# entitled until their period ends.
_REVOKING_EVENT_TYPES = frozenset(
    {"EXPIRATION", "SUBSCRIPTION_PAUSED"}
)


@dataclass(frozen=True)
class SubscriptionEvent:
    """A normalized change to a user's entitlement, ready to persist."""

    user_id: str
    is_active: bool
    product_id: str | None
    entitlement: str | None
    expires_at: datetime | None
    event_id: str | None
    event_at: datetime | None
    raw: dict


def _ms_to_datetime(value: object) -> datetime | None:
    if not isinstance(value, (int, float)):
        return None
    return datetime.fromtimestamp(value / 1000, tz=timezone.utc)


def parse_webhook(payload: dict) -> SubscriptionEvent | None:
    """Parse a RevenueCat webhook body into a :class:`SubscriptionEvent`.

    Returns ``None`` when the payload has no event or no app user id, so the
    caller can acknowledge-and-ignore malformed deliveries instead of 500ing.
    """
    event = payload.get("event")
    if not isinstance(event, dict):
        return None
    user_id = event.get("app_user_id")
    if not user_id:
        return None

    entitlement_ids = event.get("entitlement_ids")
    entitlement = (
        entitlement_ids[0]
        if isinstance(entitlement_ids, list) and entitlement_ids
        else event.get("entitlement_id")
    )

    event_type = event.get("type")
    return SubscriptionEvent(
        user_id=str(user_id),
        is_active=event_type not in _REVOKING_EVENT_TYPES,
        product_id=event.get("product_id"),
        entitlement=entitlement,
        expires_at=_ms_to_datetime(event.get("expiration_at_ms")),
        event_id=event.get("id"),
        event_at=_ms_to_datetime(event.get("event_timestamp_ms")),
        raw=event,
    )
