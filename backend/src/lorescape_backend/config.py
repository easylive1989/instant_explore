"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from dataclasses import dataclass

_DEFAULT_CTA_TEXT = "Explore more places with Instant Explore."


@dataclass(frozen=True)
class Config:
    supabase_url: str
    supabase_service_role_key: str
    gemini_api_key: str

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

        approver_raw = os.environ.get("DISCORD_APPROVER_IDS", "")
        approver_ids = tuple(
            part.strip() for part in approver_raw.split(",") if part.strip()
        )

        return cls(
            supabase_url=required("SUPABASE_URL"),
            supabase_service_role_key=required("SUPABASE_SERVICE_ROLE_KEY"),
            gemini_api_key=required("GEMINI_API_KEY"),
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
            narration_web_search_enabled=(
                (os.environ.get("NARRATION_WEB_SEARCH") or "1")
                .strip()
                .lower()
                not in ("0", "false", "off")
            ),
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
