"""Discord 審核互動 → social_posts 狀態轉移（不 import discord）。

按鈕 handler（views.py）與 slash command 都轉呼叫這裡的純函式，讓狀態
機可獨立於 Gateway 單元測試。
"""
from __future__ import annotations

import logging
from datetime import datetime

from lorescape_publisher.config import Config
from lorescape_publisher import executor, post_log

logger = logging.getLogger(__name__)


def approve(
    supabase, *, publish_date: str, media_type: str, reviewed_by: str
) -> None:
    """標記已核准（不動 status）。到點且已核准才會由排程迴圈發布。"""
    post_log.set_review_decision(
        supabase, publish_date=publish_date, media_type=media_type,
        decision="approved", reviewed_by=reviewed_by,
    )


def reject(
    supabase, *, publish_date: str, media_type: str, reviewed_by: str
) -> None:
    """標記拒絕並切到終態 rejected。"""
    post_log.set_review_decision(
        supabase, publish_date=publish_date, media_type=media_type,
        decision="rejected", reviewed_by=reviewed_by,
    )
    post_log.mark_status(
        supabase, publish_date=publish_date, media_type=media_type,
        status="rejected",
    )


def schedule(
    supabase, *, publish_date: str, media_type: str, scheduled_at: datetime
) -> None:
    """設排程時間（status→scheduled）。發布仍需 review_decision=approved。"""
    post_log.set_schedule(
        supabase, publish_date=publish_date, media_type=media_type,
        scheduled_at=scheduled_at.isoformat(),
    )


def publish_now(
    config: Config, supabase, *, publish_date: str, media_type: str,
    reviewed_by: str,
) -> bool:
    """隱含核准並立即發布。"""
    approve(
        supabase, publish_date=publish_date, media_type=media_type,
        reviewed_by=reviewed_by,
    )
    row = post_log.get_post(supabase, publish_date, media_type)
    if row is None:
        logger.warning("publish_now: no row for %s/%s",
                       publish_date, media_type)
        return False
    return executor.publish_row(config, supabase, row)


def republish(
    config: Config, supabase, *, publish_date: str, media_type: str
) -> bool:
    """補發 / 重試：清掉終態的 ig 結果欄位後重新發布。"""
    row = post_log.get_post(supabase, publish_date, media_type)
    if row is None:
        logger.warning("republish: no row for %s/%s",
                       publish_date, media_type)
        return False
    row = dict(row)
    row["status"] = "pending"
    row["ig_post_id"] = None
    return executor.publish_row(config, supabase, row, force=True)
