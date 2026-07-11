"""審核訊息的按鈕 View 與排程 modal（與 publisher_bot 同為僅有的 discord.py 檔）。

路由集中在 ``publisher_bot.PublisherBot.on_interaction``；本檔只負責「渲染」——
四顆帶編碼 ``custom_id`` 的按鈕與一個排程 modal，皆不掛 callback / on_submit，
好讓 bot 重啟後仍能只靠 ``on_interaction`` 解析 ``custom_id`` 路由（不依賴
persistent-view 註冊）。

``custom_id`` 格式：
- 按鈕：``<action>:<publish_date>:<media_type>``，action ∈ approve / schedule /
  publish_now / reject。
- modal：``schedule_modal:<publish_date>:<media_type>``。
"""
from __future__ import annotations

import discord

ACTION_APPROVE = "approve"
ACTION_SCHEDULE = "schedule"
ACTION_PUBLISH_NOW = "publish_now"
ACTION_REJECT = "reject"

MODAL_PREFIX = "schedule_modal"
SCHEDULE_INPUT_ID = "scheduled_at"


def build_review_view(publish_date: str, media_type: str) -> discord.ui.View:
    """回傳四顆按鈕的 View，``custom_id`` 帶 ``publish_date`` 與 ``media_type``。

    按鈕本身不掛 callback；互動由 ``on_interaction`` 集中解析 ``custom_id``
    後委派給 ``interactions`` 純函式，使 bot 重啟前的訊息按鈕仍可路由。
    """
    suffix = f"{publish_date}:{media_type}"
    view = discord.ui.View(timeout=None)
    view.add_item(
        discord.ui.Button(
            label="✅ 核准",
            style=discord.ButtonStyle.success,
            custom_id=f"{ACTION_APPROVE}:{suffix}",
        )
    )
    view.add_item(
        discord.ui.Button(
            label="🕘 排程",
            style=discord.ButtonStyle.primary,
            custom_id=f"{ACTION_SCHEDULE}:{suffix}",
        )
    )
    view.add_item(
        discord.ui.Button(
            label="🚀 立即發布",
            style=discord.ButtonStyle.primary,
            custom_id=f"{ACTION_PUBLISH_NOW}:{suffix}",
        )
    )
    view.add_item(
        discord.ui.Button(
            label="❌ 拒絕",
            style=discord.ButtonStyle.danger,
            custom_id=f"{ACTION_REJECT}:{suffix}",
        )
    )
    return view


def build_schedule_modal(
    publish_date: str, media_type: str
) -> discord.ui.Modal:
    """回傳排程 modal；submit 由 ``on_interaction`` 依 ``custom_id`` 集中處理。"""
    modal = discord.ui.Modal(
        title="排程發布時間",
        custom_id=f"{MODAL_PREFIX}:{publish_date}:{media_type}",
    )
    modal.add_item(
        discord.ui.TextInput(
            label="時間 (Asia/Taipei)",
            custom_id=SCHEDULE_INPUT_ID,
            default=f"{publish_date} 21:00",
            placeholder="2026-07-09 21:00",
        )
    )
    return modal
