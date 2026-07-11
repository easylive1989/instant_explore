"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from dataclasses import dataclass

from lorescape_backend.shared.genai import (
    BACKEND_AI_STUDIO,
    BACKEND_VERTEX,
    GenaiSettings,
)


@dataclass(frozen=True)
class Config:
    supabase_url: str
    supabase_service_role_key: str
    # Present (required) only when gemini_backend == "ai-studio"; on the
    # Vertex backend it is None because auth comes from GCP credentials.
    gemini_api_key: str | None

    # RevenueCat. Webhook auth token guards the /webhooks/revenuecat endpoint
    # (must match the "Authorization" header configured in the RevenueCat
    # dashboard). The secret API key is used by the reconcile job to re-read
    # subscriber status. Either being absent disables that half of the flow.
    revenuecat_webhook_auth_token: str | None = None
    revenuecat_api_key: str | None = None

    # Which Gemini backend to use. "ai-studio" authenticates with
    # GEMINI_API_KEY; "vertex" routes through a GCP project so the bound
    # billing account / AI Pro credit applies (auth via GCP Application
    # Default Credentials, no key in code). Env: GEMINI_BACKEND.
    gemini_backend: str = BACKEND_AI_STUDIO
    # GCP project + region, used only by the Vertex backend.
    # Env: GOOGLE_CLOUD_PROJECT / GOOGLE_CLOUD_LOCATION.
    gcp_project: str | None = None
    gcp_location: str = "us-central1"

    # Narration Google-Search grounding. Disabling restores the legacy
    # Wikipedia-only behaviour (kill-switch for grounding-quota
    # emergencies). Env: NARRATION_WEB_SEARCH=0/false to disable.
    narration_web_search_enabled: bool = True

    @classmethod
    def from_env(cls) -> "Config":
        def required(name: str) -> str:
            value = os.environ.get(name)
            if not value:
                raise RuntimeError(f"Missing required env var: {name}")
            return value

        def optional(name: str) -> str | None:
            return os.environ.get(name) or None

        def is_on(name: str, default: str) -> bool:
            return (
                (os.environ.get(name) or default).strip().lower()
                not in ("0", "false", "off")
            )

        # On the Vertex backend the API key is unused (auth comes from GCP
        # credentials) and a project is required instead.
        gemini_backend = (
            os.environ.get("GEMINI_BACKEND") or BACKEND_AI_STUDIO
        ).strip().lower()
        gcp_project = optional("GOOGLE_CLOUD_PROJECT")
        if gemini_backend == BACKEND_VERTEX:
            if not gcp_project:
                raise RuntimeError(
                    "GEMINI_BACKEND=vertex requires GOOGLE_CLOUD_PROJECT"
                )
            gemini_api_key = optional("GEMINI_API_KEY")
        else:
            gemini_api_key = required("GEMINI_API_KEY")

        return cls(
            supabase_url=required("SUPABASE_URL"),
            supabase_service_role_key=required("SUPABASE_SERVICE_ROLE_KEY"),
            gemini_api_key=gemini_api_key,
            gemini_backend=gemini_backend,
            gcp_project=gcp_project,
            gcp_location=os.environ.get("GOOGLE_CLOUD_LOCATION")
            or "us-central1",
            revenuecat_webhook_auth_token=optional(
                "REVENUECAT_WEBHOOK_AUTH_TOKEN"
            ),
            revenuecat_api_key=optional("REVENUECAT_API_KEY"),
            narration_web_search_enabled=is_on("NARRATION_WEB_SEARCH", "1"),
        )

    @property
    def genai_settings(self) -> GenaiSettings:
        """Backend selection passed to the shared genai client factory."""
        return GenaiSettings(
            backend=self.gemini_backend,
            api_key=self.gemini_api_key,
            project=self.gcp_project,
            location=self.gcp_location,
        )

    @property
    def revenuecat_webhook_enabled(self) -> bool:
        """True if the RevenueCat webhook endpoint is configured."""
        return bool(self.revenuecat_webhook_auth_token)

    @property
    def revenuecat_reconcile_enabled(self) -> bool:
        """True if the reconcile job can call the RevenueCat REST API."""
        return bool(self.revenuecat_api_key)
