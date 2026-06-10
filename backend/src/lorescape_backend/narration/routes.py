"""FastAPI routes for on-demand narration."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from lorescape_backend.auth import AuthedUser, require_user
from lorescape_backend.config import Config
from lorescape_backend.dependencies import get_config
from lorescape_backend.narration import service
from lorescape_backend.narration.models import (
    HooksRequest,
    HooksResponse,
    NarrationRequest,
    NarrationResponse,
)
from lorescape_backend.subscriptions.dependencies import (
    get_subscription_repository,
)
from lorescape_backend.subscriptions.repository import SubscriptionRepository
from lorescape_backend.usage.dependencies import get_usage_repository
from lorescape_backend.usage.repository import UsageRepository

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/narration", tags=["narration"])


@router.post("/hooks", response_model=HooksResponse)
def post_hooks(
    request: HooksRequest,
    config: Config = Depends(get_config),
    user: AuthedUser = Depends(require_user),
) -> HooksResponse:
    """Return 2-3 narrative angles for the given place."""
    try:
        return service.generate_hooks(
            api_key=config.gemini_api_key,
            request=request,
            web_search=config.narration_web_search_enabled,
        )
    except service.UnsupportedLanguageError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("", response_model=NarrationResponse)
def post_narration(
    request: NarrationRequest,
    config: Config = Depends(get_config),
    user: AuthedUser = Depends(require_user),
    subscriptions: SubscriptionRepository = Depends(get_subscription_repository),
    usage: UsageRepository = Depends(get_usage_repository),
) -> NarrationResponse:
    """Return the long-form 3-paragraph story for the given place.

    Generation is unlimited for everyone — the daily free quota was
    removed. Non-premium usage is still recorded on success so we keep
    the data to reason about a future limit, and the app's 402 handling
    stays dormant should one ever return.
    """
    is_premium = subscriptions.is_subscribed(user.user_id)

    try:
        result = service.generate_narration(
            api_key=config.gemini_api_key,
            request=request,
            web_search=config.narration_web_search_enabled,
        )
    except service.UnsupportedLanguageError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if not is_premium:
        usage.consume(user.user_id)
    return result
