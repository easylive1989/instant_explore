"""Discord 發布 bot：Gateway 常駐，審核 / 排程 / 發布的唯一 server 端。

所有判斷邏輯都在已測過的純模組（``interactions`` / ``scheduler`` /
``review_poster``），本檔只負責把它們接到 discord.py：

- 每分鐘一輪 ``_poll_loop``，在 worker thread 跑同步的 ``review_poster.tick``
  與 ``scheduler.tick``（supabase-py 為 blocking），實際的 Discord 送出再
  透過 ``run_coroutine_threadsafe`` 交回 event loop。
- 按鈕 / modal 互動集中在 ``on_interaction`` 依 ``custom_id`` 解析後委派給
  ``interactions`` 純函式；不依賴 persistent-view 註冊，故重啟前的訊息按鈕
  仍可路由。
"""
from __future__ import annotations

import asyncio
import io
import logging
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

import discord
import requests
from discord.ext import tasks
from supabase import create_client

from lorescape_publisher.config import Config
from lorescape_publisher.bot_flows import (
    interactions,
    review_poster,
    scheduler,
    views,
)

logger = logging.getLogger(__name__)

TAIPEI = ZoneInfo("Asia/Taipei")
VIDEO_FILENAME = "final.mp4"
# Discord 非加成伺服器附件上限 10 MB；留 multipart envelope 的餘裕。
MAX_ATTACHMENT_BYTES = int(9.5 * 1024 * 1024)
_NOT_APPROVER = "你不在核准名單內。"


class PublisherBot(discord.Client):
    """審核頻道的 Gateway client：貼審核訊息、處理按鈕、跑排程迴圈。"""

    def __init__(self, config: Config):
        super().__init__(intents=discord.Intents.default())
        self._config = config
        self._supabase = create_client(
            config.supabase_url, config.supabase_service_role_key
        )

    async def setup_hook(self) -> None:
        self._poll_loop.start()

    # ── 每分鐘輪詢：貼審核訊息 + 發到點且已核准的排程 ──────────────

    @tasks.loop(seconds=60)
    async def _poll_loop(self) -> None:
        await asyncio.to_thread(self._run_ticks)

    @_poll_loop.before_loop
    async def _before_poll(self) -> None:
        await self.wait_until_ready()

    def _run_ticks(self) -> None:
        """在 worker thread 執行同步 tick；send 透過 loop 再回主執行緒。"""
        try:
            review_poster.tick(self._supabase, post_review=self._post_review)
        except Exception:  # noqa: BLE001 — 單輪失敗不拖垮 bot
            logger.exception("review_poster.tick failed")
        try:
            scheduler.tick(
                self._config,
                self._supabase,
                now=datetime.now(timezone.utc),
                notify=self._notify,
            )
        except Exception:  # noqa: BLE001
            logger.exception("scheduler.tick failed")

    def _post_review(self, row: dict) -> str | None:
        """review_poster 注入的同步 callback（worker thread）。"""
        future = asyncio.run_coroutine_threadsafe(
            self._do_post_review(row), self.loop
        )
        return future.result()

    def _notify(self, publish_date: str, message: str) -> None:
        """scheduler 注入的同步 notify（worker thread）。"""
        future = asyncio.run_coroutine_threadsafe(
            self._send_channel(f"[{publish_date}] {message}"), self.loop
        )
        future.result()

    # ── 於 event loop 上執行的實際 Discord I/O ──────────────────────

    async def _do_post_review(self, row: dict) -> str | None:
        """貼帶按鈕的審核訊息，回傳 message id；素材未就緒回 ``None``。"""
        files, content = await self._build_attachments(row)
        if files is None:
            return None
        channel = await self._review_channel()
        view = views.build_review_view(row["publish_date"], row["media_type"])
        msg = await channel.send(content=content, files=files, view=view)
        return str(msg.id)

    async def _send_channel(self, text: str) -> None:
        channel = await self._review_channel()
        await channel.send(text)

    async def _review_channel(self) -> discord.abc.Messageable:
        channel_id = int(self._config.discord_review_channel_id)
        channel = self.get_channel(channel_id)
        if channel is None:
            channel = await self.fetch_channel(channel_id)
        return channel

    async def _build_attachments(
        self, row: dict
    ) -> tuple[list[discord.File] | None, str | None]:
        """carousel 從 ``slide_urls`` 下載；reel 從 volume 讀（過大轉 720p）。"""
        publish_date = row["publish_date"]
        if row["media_type"] == "reel":
            return await self._build_reel_attachment(publish_date)
        return await self._build_carousel_attachments(row, publish_date)

    async def _build_carousel_attachments(
        self, row: dict, publish_date: str
    ) -> tuple[list[discord.File] | None, str | None]:
        urls = row.get("slide_urls") or []
        files: list[discord.File] = []
        for index, url in enumerate(urls):
            data = await asyncio.to_thread(self._download, url)
            files.append(
                discord.File(
                    io.BytesIO(data), filename=f"slide_{index:02d}.jpg"
                )
            )
        if not files:
            return None, None
        return files, f"Wander carousel {publish_date} — 按鈕操作發布"

    async def _build_reel_attachment(
        self, publish_date: str
    ) -> tuple[list[discord.File] | None, str | None]:
        if not self._config.daily_video_dir:
            return None, None
        video = Path(self._config.daily_video_dir) / publish_date / VIDEO_FILENAME
        if not video.is_file():
            return None, None
        data = await asyncio.to_thread(self._load_reel_bytes, video)
        files = [discord.File(io.BytesIO(data), filename=f"reel_{publish_date}.mp4")]
        return files, f"Reel {publish_date} — 按鈕操作發布"

    @staticmethod
    def _download(url: str) -> bytes:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.content

    @staticmethod
    def _load_reel_bytes(video: Path) -> bytes:
        """回傳影片 bytes，過大時轉 720p 預覽（僅供審核，發布仍用原檔）。"""
        if video.stat().st_size <= MAX_ATTACHMENT_BYTES:
            return video.read_bytes()
        logger.info("reel exceeds Discord limit; encoding 720p preview: %s", video)
        with tempfile.NamedTemporaryFile(suffix=".mp4") as preview:
            subprocess.run(
                [
                    "ffmpeg", "-y", "-i", str(video),
                    "-vf", "scale=-2:720",
                    "-c:v", "libx264", "-crf", "28", "-preset", "veryfast",
                    "-c:a", "aac", "-b:a", "96k",
                    preview.name,
                ],
                check=True,
                capture_output=True,
            )
            return Path(preview.name).read_bytes()

    # ── 集中式互動路由（不依賴 persistent-view 註冊）────────────────

    async def on_interaction(self, interaction: discord.Interaction) -> None:
        try:
            if interaction.type == discord.InteractionType.component:
                await self._handle_component(interaction)
            elif interaction.type == discord.InteractionType.modal_submit:
                await self._handle_modal_submit(interaction)
        except Exception:  # noqa: BLE001 — 互動失敗不拖垮 bot
            logger.exception("on_interaction failed")

    async def _handle_component(self, interaction: discord.Interaction) -> None:
        action, publish_date, media_type = self._split_custom_id(interaction)
        if not await self._guard(interaction):
            return
        reviewed_by = str(interaction.user.id)
        if action == views.ACTION_APPROVE:
            await asyncio.to_thread(
                interactions.approve, self._supabase,
                publish_date=publish_date, media_type=media_type,
                reviewed_by=reviewed_by,
            )
            await interaction.response.send_message(
                f"已核准 {media_type} {publish_date}。排程到點會自動發，"
                f"或按 🚀 立即發布。",
                ephemeral=True,
            )
        elif action == views.ACTION_REJECT:
            await asyncio.to_thread(
                interactions.reject, self._supabase,
                publish_date=publish_date, media_type=media_type,
                reviewed_by=reviewed_by,
            )
            await interaction.response.send_message(
                f"已拒絕 {media_type} {publish_date}。", ephemeral=True
            )
        elif action == views.ACTION_PUBLISH_NOW:
            await interaction.response.defer(ephemeral=True)
            ok = await asyncio.to_thread(
                interactions.publish_now, self._config, self._supabase,
                publish_date=publish_date, media_type=media_type,
                reviewed_by=reviewed_by,
            )
            await interaction.followup.send(
                f"{'已發布' if ok else '發布失敗，見 log'} "
                f"{media_type} {publish_date}。",
                ephemeral=True,
            )
        elif action == views.ACTION_SCHEDULE:
            await interaction.response.send_modal(
                views.build_schedule_modal(publish_date, media_type)
            )

    async def _handle_modal_submit(
        self, interaction: discord.Interaction
    ) -> None:
        _, publish_date, media_type = self._split_custom_id(interaction)
        if not await self._guard(interaction):
            return
        raw = interaction.data["components"][0]["components"][0]["value"]
        try:
            naive = datetime.strptime(raw.strip(), "%Y-%m-%d %H:%M")
        except ValueError:
            await interaction.response.send_message(
                "格式需為 YYYY-MM-DD HH:MM。", ephemeral=True
            )
            return
        when_utc = naive.replace(tzinfo=TAIPEI).astimezone(timezone.utc)
        await asyncio.to_thread(
            interactions.schedule, self._supabase,
            publish_date=publish_date, media_type=media_type,
            scheduled_at=when_utc,
        )
        await interaction.response.send_message(
            f"已排程 {media_type} {publish_date} 於 {raw}"
            f"（需已核准才會發）。",
            ephemeral=True,
        )

    async def _guard(self, interaction: discord.Interaction) -> bool:
        if str(interaction.user.id) not in self._config.discord_approver_ids:
            await interaction.response.send_message(
                _NOT_APPROVER, ephemeral=True
            )
            return False
        return True

    @staticmethod
    def _split_custom_id(
        interaction: discord.Interaction,
    ) -> tuple[str, str, str]:
        """``<action>:<publish_date>:<media_type>`` → 三段 tuple。"""
        prefix, publish_date, media_type = interaction.data["custom_id"].split(
            ":"
        )
        return prefix, publish_date, media_type


def main() -> None:
    """CLI 進入點：``python -m lorescape_publisher.bot``。"""
    logging.basicConfig(level=logging.INFO)
    config = Config.from_env()
    if not config.review_enabled:
        raise SystemExit(
            "review not configured (bot token/channel/approvers)"
        )
    PublisherBot(config).run(config.discord_bot_token)


if __name__ == "__main__":
    main()
