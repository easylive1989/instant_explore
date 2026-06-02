"""Periodic reconcile: re-read RevenueCat to heal any missed webhooks."""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.subscriptions.models import SubscriptionEvent
from lorescape_backend.subscriptions.repository import SubscriptionRepository
from lorescape_backend.subscriptions.revenuecat import RevenueCatClient

logger = logging.getLogger(__name__)


def reconcile_subscriptions(
    repository: SubscriptionRepository,
    client: RevenueCatClient,
    now: datetime | None = None,
) -> int:
    """Re-fetch every known subscriber from RevenueCat and persist the truth.

    Reconcile entries always win over earlier webhook state (they carry a
    fresh ``event_at``), so a missed EXPIRATION or RENEWAL is corrected here.
    Returns the number of users reconciled.
    """
    now = now or datetime.now(tz=timezone.utc)
    user_ids = repository.list_user_ids()
    reconciled = 0
    for user_id in user_ids:
        try:
            status = client.get_subscriber(user_id)
        except Exception:  # one bad user must not abort the whole sweep
            logger.exception("Reconcile failed for user %s", user_id)
            continue
        repository.apply_event(
            SubscriptionEvent(
                user_id=user_id,
                is_active=status.is_active,
                product_id=status.product_id,
                entitlement=status.entitlement,
                expires_at=status.expires_at,
                event_id=f"reconcile:{now.isoformat()}",
                event_at=now,
                raw={"source": "reconcile"},
            )
        )
        reconciled += 1
    logger.info("Reconciled %d subscription(s)", reconciled)
    return reconciled


def run_reconcile_job(config: Config) -> None:
    """Entry point for the scheduler — wires up the repo and RevenueCat client."""
    if not config.revenuecat_reconcile_enabled:
        logger.info("RevenueCat reconcile skipped: REVENUECAT_API_KEY not set")
        return
    repository = SubscriptionRepository(
        create_client(config.supabase_url, config.supabase_service_role_key)
    )
    client = RevenueCatClient(api_key=config.revenuecat_api_key)
    reconcile_subscriptions(repository, client)
