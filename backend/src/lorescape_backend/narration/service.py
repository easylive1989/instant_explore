"""Orchestrate on-demand narration: source pipeline → Gemini → response model."""
from __future__ import annotations

import logging

from lorescape_backend.narration import gemini_client, prompts
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    HooksResponse,
    NarrationRequest,
    NarrationResponse,
    SUPPORTED_LANGUAGES,
)
from lorescape_backend.shared.genai import GenaiSettings
from lorescape_backend.shared.story_prompt import StoryHook
from lorescape_backend.sources.models import SourceBundle
from lorescape_backend.sources.pipeline import (
    build_source_bundle,
    legacy_single_source_bundle,
)

logger = logging.getLogger(__name__)


class UnsupportedLanguageError(ValueError):
    """Raised when the request language is not one of SUPPORTED_LANGUAGES."""


def _validate_language(language: str) -> None:
    if language not in SUPPORTED_LANGUAGES:
        raise UnsupportedLanguageError(
            f"Unsupported language {language!r}; expected one of {SUPPORTED_LANGUAGES}"
        )


def _resolve_bundle(request) -> SourceBundle:
    """Build SourceBundle from either the new wikidata_id or legacy title."""
    if request.wikidata_id:
        return build_source_bundle(
            wikidata_id=request.wikidata_id,
            language=request.language,
            place_name=request.place_name,
        )
    logger.warning(
        "narration.legacy_title_path",
        extra={
            "title": request.wikipedia_title,
            "deprecated_remove_after": "2026-XX-XX",
        },
    )
    return legacy_single_source_bundle(title=request.wikipedia_title)


def generate_hooks(
    *, settings: GenaiSettings, request: HooksRequest, web_search: bool = True
) -> HooksResponse:
    """Surface 2-3 narrative angles for the request's place.

    With `web_search=True` (default) Gemini researches the place via
    Google Search grounding, so a thin Wikipedia bundle no longer
    short-circuits — the web can rescue it, and the model's own
    `insufficient_source` remains the final defence. `web_search=False`
    restores the legacy behaviour entirely (kill-switch).
    """
    _validate_language(request.language)
    bundle = _resolve_bundle(request)
    if not bundle.is_sufficient:
        logger.info(
            "narration.pre_gemini_gate",
            extra={
                "wikidata_id": bundle.wikidata_id,
                "web_search": web_search,
            },
        )
        if not web_search:
            return HooksResponse(hooks=[], insufficient_source=True)

    generate = (
        gemini_client.generate_grounded
        if web_search
        else gemini_client.generate_structured
    )
    payload = generate(
        settings=settings,
        system_instruction=prompts.hooks_system_instruction(
            request.language, web_search=web_search
        ),
        user_prompt=prompts.build_hooks_user_prompt(
            place_name=request.place_name,
            location=request.location,
            source_bundle=bundle,
            web_search=web_search,
        ),
        response_schema=prompts.hooks_response_schema(request.language),
    )
    hooks = [HookItem(**item) for item in payload.get("hooks", [])]
    return HooksResponse(
        hooks=hooks,
        insufficient_source=bool(payload.get("insufficient_source", False)),
    )


def generate_narration(
    *,
    settings: GenaiSettings,
    request: NarrationRequest,
    web_search: bool = True,
) -> NarrationResponse:
    """Generate the long-form 3-paragraph story for `request`.

    See `generate_hooks` for the `web_search` semantics (grounded by
    default; False restores the legacy gate + structured-only path).
    """
    _validate_language(request.language)
    bundle = _resolve_bundle(request)
    if not bundle.is_sufficient:
        logger.info(
            "narration.pre_gemini_gate",
            extra={
                "wikidata_id": bundle.wikidata_id,
                "web_search": web_search,
            },
        )
        if not web_search:
            return NarrationResponse(
                place_name=request.place_name,
                location=request.location,
                era="",
                paragraphs=[],
                pull_quote="",
                insufficient_source=True,
            )

    hook = (
        StoryHook(title=request.hook.title, teaser=request.hook.teaser)
        if request.hook is not None
        else None
    )
    generate = (
        gemini_client.generate_grounded
        if web_search
        else gemini_client.generate_structured
    )
    payload = generate(
        settings=settings,
        system_instruction=prompts.narration_system_instruction(
            request.language, web_search=web_search
        ),
        user_prompt=prompts.build_narration_user_prompt(
            place_name=request.place_name,
            location=request.location,
            source_bundle=bundle,
            language=request.language,
            hook=hook,
            web_search=web_search,
        ),
        response_schema=prompts.narration_response_schema(request.language),
    )
    insufficient = bool(payload.get("insufficient_source", False))
    # Defence-in-depth: when the model flagged insufficient_source, ignore
    # whatever it placed in `paragraphs` (observed: model regurgitates the
    # in-prompt example).
    raw_paragraphs = payload.get("paragraphs", []) if not insufficient else []
    return NarrationResponse(
        place_name=payload.get("place_name") or request.place_name,
        location=payload.get("place_location") or request.location,
        era=payload.get("era", ""),
        paragraphs=list(raw_paragraphs),
        pull_quote=payload.get("pull_quote", "") if not insufficient else "",
        insufficient_source=insufficient,
    )
