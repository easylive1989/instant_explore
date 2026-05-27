"""Pydantic models for the on-demand narration endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field


SUPPORTED_LANGUAGES = ("zh-TW", "en")


class HookItem(BaseModel):
    """One narrative angle the App can offer the user."""

    id: str = Field(..., description="Stable slug, e.g. 'van-gogh-1888'.")
    title: str = Field(..., description="6-14 chars (zh) / chars (en) headline.")
    teaser: str = Field(..., description="One-line cliffhanger, up to 40 chars.")


class HooksRequest(BaseModel):
    place_name: str
    location: str = ""
    wikipedia_title: str
    language: str = Field(..., description="zh-TW or en")


class HooksResponse(BaseModel):
    hooks: list[HookItem]
    insufficient_source: bool = False


class NarrationRequest(BaseModel):
    place_name: str
    location: str = ""
    wikipedia_title: str
    language: str = Field(..., description="zh-TW or en")
    hook: HookItem | None = None


class NarrationResponse(BaseModel):
    place_name: str
    location: str
    era: str
    paragraphs: list[str]
    pull_quote: str
    insufficient_source: bool = False
