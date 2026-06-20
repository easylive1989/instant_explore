"""Shared google-genai client factory for AI Studio and Vertex AI backends.

The same `google-genai` SDK reaches Gemini two ways:

- **AI Studio** (`ai-studio`) — authenticated with an API key
  (`GEMINI_API_KEY`).
- **Vertex AI** (`vertex`) — billed against a GCP project so the bound
  billing account / AI Pro credit applies. It carries no key in code; the
  SDK reads Application Default Credentials automatically (locally via
  `gcloud auth application-default login`, on a server via
  `GOOGLE_APPLICATION_CREDENTIALS` pointing at a service-account JSON).

`GenaiSettings` captures which backend to use; `build_client` turns it
into a `genai.Client`. Centralising construction keeps the backend switch
in one place instead of scattered `genai.Client(...)` calls.
"""
from __future__ import annotations

from dataclasses import dataclass

from google import genai

BACKEND_AI_STUDIO = "ai-studio"
BACKEND_VERTEX = "vertex"


@dataclass(frozen=True)
class GenaiSettings:
    """How to reach Gemini.

    `api_key` is used only by the AI Studio backend. `project`/`location`
    are used only by Vertex AI; credentials are resolved by the SDK from
    the environment, never passed here.
    """

    backend: str
    api_key: str | None = None
    project: str | None = None
    location: str = "us-central1"


def build_client(settings: GenaiSettings) -> genai.Client:
    """Create a `genai.Client` for the configured backend."""
    if settings.backend == BACKEND_VERTEX:
        return genai.Client(
            vertexai=True,
            project=settings.project,
            location=settings.location,
        )
    return genai.Client(api_key=settings.api_key)
