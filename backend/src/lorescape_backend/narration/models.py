"""Pydantic models for the on-demand narration endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field, model_validator


SUPPORTED_LANGUAGES = ("zh-TW", "en")


class HookItem(BaseModel):
    """One narrative angle the App can offer the user."""

    id: str = Field(..., description="Stable slug, e.g. 'van-gogh-1888'.")
    title: str = Field(..., description="6-14 chars (zh) / chars (en) headline.")
    teaser: str = Field(..., description="One-line cliffhanger, up to 40 chars.")


class HooksRequest(BaseModel):
    place_name: str
    location: str = ""
    wikidata_id: str | None = Field(
        default=None, description="Wikidata Q-id, e.g. 'Q12345'.",
    )
    wikipedia_title: str | None = Field(
        default=None,
        deprecated=True,
        description=(
            "Deprecated since 2026-05-29. Old App versions only. "
            "Remove after legacy clients phase out."
        ),
    )
    language: str = Field(..., description="zh-TW or en")

    @model_validator(mode="after")
    def _require_one_identity(self):
        if not self.wikidata_id and not self.wikipedia_title:
            raise ValueError(
                "Either wikidata_id or wikipedia_title must be provided"
            )
        return self


class HooksResponse(BaseModel):
    hooks: list[HookItem]
    insufficient_source: bool = False


class NarrationRequest(BaseModel):
    place_name: str
    location: str = ""
    wikidata_id: str | None = Field(
        default=None, description="Wikidata Q-id, e.g. 'Q12345'.",
    )
    wikipedia_title: str | None = Field(
        default=None,
        deprecated=True,
        description=(
            "Deprecated since 2026-05-29. Old App versions only. "
            "Remove after legacy clients phase out."
        ),
    )
    language: str = Field(..., description="zh-TW or en")
    hook: HookItem | None = None

    @model_validator(mode="after")
    def _require_one_identity(self):
        if not self.wikidata_id and not self.wikipedia_title:
            raise ValueError(
                "Either wikidata_id or wikipedia_title must be provided"
            )
        return self


class NarrationResponse(BaseModel):
    place_name: str
    location: str
    era: str
    paragraphs: list[str]
    pull_quote: str
    insufficient_source: bool = False
