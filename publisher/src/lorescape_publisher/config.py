"""Publisher configuration loaded from environment variables.

publisher 與 backend 完全解耦，各自維護自己的 Config 與 .env
（spec: docs/superpowers/specs/2026-07-11-social-publisher-split-design.md）。
"""
from __future__ import annotations

import os
from dataclasses import dataclass

from lorescape_publisher.genai import (
    BACKEND_AI_STUDIO,
    BACKEND_VERTEX,
    GenaiSettings,
)

_DEFAULT_CTA_TEXT = (
    "你會想親自走一趟嗎？完整故事與語音導覽都在 App 裡"
    "——點個人檔案的連結就能聽。"
)


@dataclass(frozen=True)
class Config:
    supabase_url: str
    supabase_service_role_key: str
    # Present (required) only when gemini_backend == "ai-studio"; on the
    # Vertex backend it is None because auth comes from GCP credentials.
    gemini_api_key: str | None

    # Failure-alert webhook (sends to a 'noisy' channel).
    discord_webhook_url: str | None

    # Review-flow bot. Posts the daily story and handles the review buttons.
    # When any of these is missing, the bot refuses to start (see bot.main).
    discord_bot_token: str | None
    discord_review_channel_id: str | None
    discord_approver_ids: tuple[str, ...]

    # Instagram Business via Meta Graph. When token is missing, IG is skipped.
    ig_user_id: str | None
    meta_page_access_token: str | None

    # Branding bits stamped into every published post.
    brand_handle_ig: str
    cta_text: str

    # Which Gemini backend to use. "ai-studio" authenticates with
    # GEMINI_API_KEY; "vertex" routes through a GCP project (auth via GCP
    # Application Default Credentials). Env: GEMINI_BACKEND.
    gemini_backend: str = BACKEND_AI_STUDIO
    gcp_project: str | None = None
    gcp_location: str = "us-central1"

    # Daily story pipeline flags. DAILY_STORY_ENABLED is the master switch;
    # DAILY_STORY_PUBLISH_ENABLED defaults to it but can be overridden
    # independently. Env: DAILY_STORY_ENABLED / DAILY_STORY_PUBLISH_ENABLED =
    # 0/false/off to pause.
    daily_story_enabled: bool = True
    daily_story_publish_enabled: bool = True

    # Directory holding the per-date reel videos rsynced from the operator's
    # machine (<dir>/<YYYY-MM-DD>/final.mp4 + narration.txt). Env:
    # DAILY_VIDEO_DIR.
    daily_video_dir: str | None = None

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

        daily_story_enabled = is_on("DAILY_STORY_ENABLED", "1")
        master_default = "1" if daily_story_enabled else "0"

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
            cta_text=_DEFAULT_CTA_TEXT,
            daily_story_enabled=daily_story_enabled,
            daily_story_publish_enabled=is_on(
                "DAILY_STORY_PUBLISH_ENABLED", master_default
            ),
            daily_video_dir=optional("DAILY_VIDEO_DIR"),
        )

    @property
    def genai_settings(self) -> GenaiSettings:
        """Backend selection passed to the genai client factory."""
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
