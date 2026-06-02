"""FastAPI dependencies for the subscriptions feature."""
from __future__ import annotations

from fastapi import Depends
from supabase import Client

from lorescape_backend.dependencies import get_supabase_client
from lorescape_backend.subscriptions.repository import SubscriptionRepository


def get_subscription_repository(
    client: Client = Depends(get_supabase_client),
) -> SubscriptionRepository:
    """FastAPI dependency providing the repository — overridden in tests."""
    return SubscriptionRepository(client)
