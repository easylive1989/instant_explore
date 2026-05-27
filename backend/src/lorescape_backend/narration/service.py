"""Orchestrate on-demand narration: wiki fetch → Gemini → response model."""
from __future__ import annotations

import logging

from lorescape_backend.daily_story import wikipedia
from lorescape_backend.narration import gemini_client, prompts
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    HooksResponse,
    NarrationRequest,
    NarrationResponse,
    SUPPORTED_LANGUAGES,
)
from lorescape_backend.shared.story_prompt import StoryHook

logger = logging.getLogger(__name__)


class UnsupportedLanguageError(ValueError):
    """Raised when the request language is not one of SUPPORTED_LANGUAGES."""


def _validate_language(language: str) -> None:
    if language not in SUPPORTED_LANGUAGES:
        raise UnsupportedLanguageError(
            f"Unsupported language {language!r}; expected one of {SUPPORTED_LANGUAGES}"
        )


def generate_hooks(*, api_key: str, request: HooksRequest) -> HooksResponse:
    """Surface 2-3 narrative angles for `request.wikipedia_title`."""
    _validate_language(request.language)
    extract = wikipedia.fetch_intro_extract(request.wikipedia_title)
    payload = gemini_client.generate_structured(
        api_key=api_key,
        system_instruction=prompts.hooks_system_instruction(request.language),
        user_prompt=prompts.build_hooks_user_prompt(
            place_name=request.place_name,
            location=request.location,
            wikipedia_title=request.wikipedia_title,
            wikipedia_extract=extract,
        ),
        response_schema=prompts.hooks_response_schema(request.language),
    )
    hooks = [HookItem(**item) for item in payload.get("hooks", [])]
    return HooksResponse(
        hooks=hooks,
        insufficient_source=bool(payload.get("insufficient_source", False)),
    )


def generate_narration(
    *, api_key: str, request: NarrationRequest
) -> NarrationResponse:
    """Generate the long-form 3-paragraph story for `request`."""
    _validate_language(request.language)
    extract = wikipedia.fetch_intro_extract(request.wikipedia_title)
    hook = (
        StoryHook(title=request.hook.title, teaser=request.hook.teaser)
        if request.hook is not None
        else None
    )
    payload = gemini_client.generate_structured(
        api_key=api_key,
        system_instruction=prompts.narration_system_instruction(request.language),
        user_prompt=prompts.build_narration_user_prompt(
            place_name=request.place_name,
            location=request.location,
            wikipedia_title=request.wikipedia_title,
            wikipedia_extract=extract,
            language=request.language,
            hook=hook,
        ),
        response_schema=prompts.narration_response_schema(request.language),
    )
    return NarrationResponse(
        place_name=payload["place_name"],
        location=payload["place_location"],
        era=payload["era"],
        paragraphs=list(payload.get("paragraphs", [])),
        pull_quote=payload.get("pull_quote", ""),
        insufficient_source=bool(payload.get("insufficient_source", False)),
    )
