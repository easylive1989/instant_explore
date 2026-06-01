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
            api_key=config.gemini_api_key, request=request
        )
    except service.UnsupportedLanguageError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("", response_model=NarrationResponse)
def post_narration(
    request: NarrationRequest,
    config: Config = Depends(get_config),
    user: AuthedUser = Depends(require_user),
) -> NarrationResponse:
    """Return the long-form 3-paragraph story for the given place."""
    try:
        return service.generate_narration(
            api_key=config.gemini_api_key, request=request
        )
    except service.UnsupportedLanguageError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
