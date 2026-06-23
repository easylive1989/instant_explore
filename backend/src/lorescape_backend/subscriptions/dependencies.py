"""FastAPI dependencies for the subscriptions feature."""
from __future__ import annotations

from fastapi import Depends
from supabase import Client

from lorescape_backend.config import Config
from lorescape_backend.dependencies import get_config, get_supabase_client
from lorescape_backend.subscriptions.repository import SubscriptionRepository
from lorescape_backend.subscriptions.revenuecat import RevenueCatClient
from lorescape_backend.subscriptions.service import SubscriptionChecker


def get_subscription_repository(
    client: Client = Depends(get_supabase_client),
) -> SubscriptionRepository:
    """FastAPI dependency providing the repository — overridden in tests."""
    return SubscriptionRepository(client)


def get_subscription_checker(
    config: Config = Depends(get_config),
    repository: SubscriptionRepository = Depends(get_subscription_repository),
) -> SubscriptionChecker:
    """The subscription gate, with a live RevenueCat fallback when configured.

    The REST client is wired only when ``REVENUECAT_API_KEY`` is set; without
    it the checker degrades to a table-only lookup.
    """
    client = (
        RevenueCatClient(config.revenuecat_api_key)
        if config.revenuecat_reconcile_enabled
        else None
    )
    return SubscriptionChecker(repository, client)
