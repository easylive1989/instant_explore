"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from dataclasses import dataclass

from lorescape_backend.shared.genai import (
    BACKEND_AI_STUDIO,
    BACKEND_VERTEX,
    GenaiSettings,
)

_DEFAULT_CTA_TEXT = "你會想造訪哪一座？留言告訴我 👇 喜歡的話，記得收藏這篇。"


@dataclass(frozen=True)
class Config:
    supabase_url: str
    supabase_service_role_key: str
    # Present (required) only when gemini_backend == "ai-studio"; on the
    # Vertex backend it is None because auth comes from GCP credentials.
    gemini_api_key: str | None

    # Failure-alert webhook (existing, sends to a 'noisy' channel).
    discord_webhook_url: str | None

    # Review-flow bot (new). Bot posts the daily story and reads reactions.
    # When any of these is missing, the publish flow is disabled and the
    # job degrades to "generate-only" mode.
    discord_bot_token: str | None
    discord_review_channel_id: str | None
    discord_approver_ids: tuple[str, ...]

    # Instagram Business via Meta Graph. When token is missing, IG is skipped.
    ig_user_id: str | None
    meta_page_access_token: str | None

    # Branding bits stamped into every published post.
    brand_handle_ig: str
    cta_text: str

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

    # Daily story pipeline (09:00 generate + 21:00 publish cron jobs).
    # DAILY_STORY_ENABLED is the legacy master switch; the two per-job flags
    # below default to it but can be overridden independently. This lets the
    # 21:00 IG-publish job keep running for manually-written (Claude) stories
    # while the 09:00 Gemini generate job stays paused.
    # Env: DAILY_STORY_ENABLED / DAILY_STORY_GENERATE_ENABLED /
    # DAILY_STORY_PUBLISH_ENABLED = 0/false/off to pause. The 03:00
    # subscription reconcile and all HTTP APIs are unaffected.
    daily_story_enabled: bool = True
    daily_story_generate_enabled: bool = True
    daily_story_publish_enabled: bool = True

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

        approver_raw = os.environ.get("DISCORD_APPROVER_IDS", "")
        approver_ids = tuple(
            part.strip() for part in approver_raw.split(",") if part.strip()
        )

        # The per-job flags fall back to the master switch when unset, so an
        # operator who only sets DAILY_STORY_ENABLED keeps the old all-or-
        # nothing behaviour; setting a per-job flag overrides just that job.
        daily_story_enabled = is_on("DAILY_STORY_ENABLED", "1")
        master_default = "1" if daily_story_enabled else "0"

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
            discord_webhook_url=optional("DISCORD_WEBHOOK_URL"),
            discord_bot_token=optional("DISCORD_BOT_TOKEN"),
            discord_review_channel_id=optional("DISCORD_REVIEW_CHANNEL_ID"),
            discord_approver_ids=approver_ids,
            ig_user_id=optional("IG_USER_ID"),
            meta_page_access_token=optional("META_PAGE_ACCESS_TOKEN"),
            brand_handle_ig=os.environ.get("BRAND_HANDLE_IG", ""),
            cta_text=os.environ.get("CTA_TEXT", _DEFAULT_CTA_TEXT),
            revenuecat_webhook_auth_token=optional(
                "REVENUECAT_WEBHOOK_AUTH_TOKEN"
            ),
            revenuecat_api_key=optional("REVENUECAT_API_KEY"),
            narration_web_search_enabled=is_on("NARRATION_WEB_SEARCH", "1"),
            daily_story_enabled=daily_story_enabled,
            daily_story_generate_enabled=is_on(
                "DAILY_STORY_GENERATE_ENABLED", master_default
            ),
            daily_story_publish_enabled=is_on(
                "DAILY_STORY_PUBLISH_ENABLED", master_default
            ),
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
    def review_enabled(self) -> bool:
        """True if Discord review is fully configured."""
        return bool(
            self.discord_bot_token
            and self.discord_review_channel_id
            and self.discord_approver_ids
        )

    @property
    def instagram_enabled(self) -> bool:
        return bool(self.ig_user_id and self.meta_page_access_token)

    @property
    def revenuecat_webhook_enabled(self) -> bool:
        """True if the RevenueCat webhook endpoint is configured."""
        return bool(self.revenuecat_webhook_auth_token)

    @property
    def revenuecat_reconcile_enabled(self) -> bool:
        """True if the reconcile job can call the RevenueCat REST API."""
        return bool(self.revenuecat_api_key)
