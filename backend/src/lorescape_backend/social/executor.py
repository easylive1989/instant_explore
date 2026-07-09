"""從 social_posts row 狀態發布到 Instagram（carousel / reel）。

排程迴圈與按鈕的「立即發布 / 補發」都走這裡。發布決策已由上游（bot
互動 / 排程迴圈）依 row 的 review_decision + scheduled_at 決定；executor
只負責「把這一列發出去並記錄結果」，並自帶重複發布守衛。
"""
from __future__ import annotations

import logging
from pathlib import Path

from lorescape_backend.config import Config
from lorescape_backend.social import (
    instagram,
    post_log,
    reel_cover,
    reel_publisher,
)

logger = logging.getLogger(__name__)

VIDEO_FILENAME = "final.mp4"


def publish_row(config: Config, supabase, row: dict) -> bool:
    """依 media_type 分派發布；已發布過則直接回 True。"""
    if row.get("status") == "published" or row.get("ig_post_id"):
        logger.info(
            "Row %s already published (ig=%s); skipping",
            row.get("id"), row.get("ig_post_id"),
        )
        return True
    media_type = row.get("media_type")
    if media_type == "carousel":
        return publish_carousel_row(config, supabase, row)
    if media_type == "reel":
        return publish_reel_row(config, supabase, row)
    logger.warning("Unknown media_type %r on row %s", media_type, row.get("id"))
    return False


def publish_carousel_row(config: Config, supabase, row: dict) -> bool:
    """發布 pre-rendered carousel（slide_urls + caption）。"""
    date_str = row["publish_date"]
    slide_urls = list(row.get("slide_urls") or ())
    if not config.instagram_enabled:
        logger.warning("Instagram not configured; skip carousel %s", date_str)
        return False
    if not slide_urls:
        logger.warning("Carousel %s has no slide_urls; cannot publish",
                       date_str)
        _record_failed(supabase, date_str, "carousel", "no_slide_urls")
        return False
    try:
        ig_post_id = instagram.publish_carousel(
            ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
            access_token=config.meta_page_access_token,  # type: ignore[arg-type]
            image_urls=slide_urls,
            caption=row.get("caption") or "",
        )
    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Carousel publish failed for %s", date_str)
        _record_failed(supabase, date_str, "carousel", _truncate(str(exc)))
        return False
    post_log.record_post(
        supabase, publish_date=date_str, media_type="carousel",
        status="published", ig_post_id=ig_post_id,
    )
    logger.info("Published carousel for %s: %s", date_str, ig_post_id)
    return True


def publish_reel_row(config: Config, supabase, row: dict) -> bool:
    """發布 reel（讀 VPS volume 上的 final.mp4）。"""
    date_str = row["publish_date"]
    if not config.instagram_enabled:
        logger.warning("Instagram not configured; skip reel %s", date_str)
        return False
    if not config.daily_video_dir:
        logger.warning("DAILY_VIDEO_DIR unset; cannot publish reel %s",
                       date_str)
        _record_failed(supabase, date_str, "reel", "no_video_dir")
        return False
    video_path = Path(config.daily_video_dir) / date_str / VIDEO_FILENAME
    if not video_path.is_file():
        logger.warning("No reel video at %s", video_path)
        _record_failed(supabase, date_str, "reel", f"no_video:{video_path}")
        return False
    ig_caption = reel_publisher.build_reel_caption(
        config, supabase, date_str, video_path.parent
    )
    cover_url = None
    try:
        cover_url = reel_cover.build_cover_url(supabase, date_str)
    except Exception as exc:  # noqa: BLE001 — cover is best-effort
        logger.warning("Reel cover build failed (%s); using frame", exc)
    try:
        ig_post_id = instagram.publish_reel(
            ig_user_id=config.ig_user_id,  # type: ignore[arg-type]
            access_token=config.meta_page_access_token,  # type: ignore[arg-type]
            video_path=str(video_path),
            caption=ig_caption,
            cover_url=cover_url,
        )
    except Exception as exc:  # noqa: BLE001 — orchestrator catches all
        logger.exception("Reel publish failed for %s", date_str)
        _record_failed(supabase, date_str, "reel", _truncate(str(exc)))
        return False
    post_log.record_post(
        supabase, publish_date=date_str, media_type="reel",
        status="published", ig_post_id=ig_post_id,
    )
    logger.info("Published reel for %s: %s", date_str, ig_post_id)
    return True


def _record_failed(supabase, date_str: str, media_type: str, error: str) -> None:
    post_log.record_post(
        supabase, publish_date=date_str, media_type=media_type,
        status="failed", error=error,
    )


def _truncate(text: str, limit: int = 1000) -> str:
    return text if len(text) <= limit else text[: limit - 1] + "…"
