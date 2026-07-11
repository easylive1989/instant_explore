"""排程迴圈：發布到點且已核准的 social_posts row。

由 publisher_bot 每分鐘呼叫一次 tick()。到點但尚未核准的 row 不發，
只透過注入的 notify 提醒一次（overdue_notified_at 去重）。
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Callable

from lorescape_publisher.config import Config
from lorescape_publisher import executor, post_log

logger = logging.getLogger(__name__)


def tick(
    config: Config,
    supabase,
    *,
    now: datetime,
    notify: Callable[[str, str], None],
) -> None:
    """處理所有 scheduled 且到點的 row。"""
    if not config.daily_story_publish_enabled:
        return
    due_rows = post_log.list_scheduled_due(supabase, now.isoformat())
    for row in due_rows:
        if row.get("review_decision") == "approved":
            executor.publish_row(config, supabase, row)
        elif row.get("review_decision") == "rejected":
            continue  # 保險：reject 已切終態，理論上不會出現在 due
        else:
            if not row.get("overdue_notified_at"):
                notify(
                    row["publish_date"],
                    f"排程時間到但尚未核准（{row['media_type']}）——"
                    f"請在 Discord 按 ✅ 或 🚀 立即發布。",
                )
                post_log.mark_overdue_notified(
                    supabase, publish_date=row["publish_date"],
                    media_type=row["media_type"],
                )
