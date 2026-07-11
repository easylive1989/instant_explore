"""輪詢尚未貼過 Discord 的 pending row，貼審核訊息並回填 message id。

實際的 Discord 貼文（下載素材 / 附按鈕）由 publisher_bot 注入的
post_review callable 執行，本模組只管迴圈與 DB 回填，維持可測試。
"""
from __future__ import annotations

import logging
from typing import Callable

from lorescape_publisher import post_log

logger = logging.getLogger(__name__)


def tick(
    supabase, *, post_review: Callable[[dict], str | None]
) -> None:
    """對每筆 pending 未貼的 row 呼叫 post_review，成功則回填 message id。"""
    for row in post_log.list_pending_unposted(supabase):
        try:
            message_id = post_review(row)
        except Exception:  # noqa: BLE001 — 單筆失敗不拖垮整輪
            logger.exception(
                "post_review failed for %s/%s",
                row.get("publish_date"), row.get("media_type"),
            )
            continue
        if message_id is None:
            continue
        post_log.set_discord_message_id(
            supabase, publish_date=row["publish_date"],
            media_type=row["media_type"], discord_message_id=message_id,
        )
