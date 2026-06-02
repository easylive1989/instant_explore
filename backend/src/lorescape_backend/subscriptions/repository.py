"""Persistence for subscription state, backed by Supabase RPCs."""
from __future__ import annotations

from lorescape_backend.subscriptions.models import SubscriptionEvent


class SubscriptionRepository:
    """Reads and writes the ``subscriptions`` table via SECURITY DEFINER RPCs.

    Constructed with a Supabase client created from the service-role key, so
    it bypasses RLS — this is server-only code.
    """

    def __init__(self, client) -> None:
        self._client = client

    def apply_event(self, event: SubscriptionEvent) -> None:
        """Upsert an event idempotently and in timestamp order."""
        self._client.rpc(
            "apply_subscription_event",
            {
                "p_user_id": event.user_id,
                "p_is_active": event.is_active,
                "p_product_id": event.product_id,
                "p_entitlement": event.entitlement,
                "p_expires_at": _iso(event.expires_at),
                "p_event_id": event.event_id,
                "p_event_at": _iso(event.event_at),
                "p_raw_event": event.raw,
            },
        ).execute()

    def is_subscribed(self, user_id: str) -> bool:
        """True if the user currently holds an active, unexpired entitlement."""
        response = self._client.rpc(
            "is_user_subscribed", {"p_user_id": user_id}
        ).execute()
        return bool(response.data)

    def list_user_ids(self) -> list[str]:
        """All user ids we have any subscription row for (reconcile targets)."""
        response = self._client.table("subscriptions").select("user_id").execute()
        return [row["user_id"] for row in (response.data or [])]


def _iso(value) -> str | None:
    return value.isoformat() if value is not None else None
