"""Webhook endpoint that ingests RevenueCat subscription events."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Body, Depends, Header, HTTPException, status

from lorescape_backend.config import Config
from lorescape_backend.dependencies import get_config
from lorescape_backend.subscriptions.dependencies import (
    get_subscription_repository,
)
from lorescape_backend.subscriptions.models import parse_webhook
from lorescape_backend.subscriptions.repository import SubscriptionRepository

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


@router.post("/revenuecat")
def revenuecat_webhook(
    payload: dict = Body(...),
    authorization: str | None = Header(default=None),
    config: Config = Depends(get_config),
    repository: SubscriptionRepository = Depends(get_subscription_repository),
) -> dict[str, str]:
    """Persist a RevenueCat event after verifying the shared auth token.

    RevenueCat sends the exact string configured in its dashboard as the
    ``Authorization`` header; we reject anything that does not match.
    """
    if not config.revenuecat_webhook_enabled:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="RevenueCat webhook not configured",
        )
    if authorization != config.revenuecat_webhook_auth_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid webhook authorization",
        )

    event = parse_webhook(payload)
    if event is None:
        logger.warning("Ignoring unparseable RevenueCat webhook payload")
        return {"status": "ignored"}

    repository.apply_event(event)
    return {"status": "ok"}
