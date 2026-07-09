# Discord 發布 Bot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用一個常駐、連著 Discord Gateway 的 bot 取代固定時間的 `publisher` cron，讓 carousel 與 reel 的審核 / 排程 / 發布全部從 Discord 按鈕互動操作。

**Architecture:** 本地 `/lorescape-manual-daily-story` 維持產製並上傳 server（carousel→Supabase、reel→VPS volume），只寫一筆 `pending` 的 `social_posts` row。server 上的 bot 靠輪詢這些 row 接手：貼帶按鈕的審核訊息、處理互動、排程迴圈到點且已核准就發到 IG。Discord SDK 只集中在 `publisher_bot.py` / `bot/views.py`；狀態轉移、排程、發布執行都是吃 supabase client 的純函式，方便單元測試。

**Tech Stack:** Python 3.11、discord.py 2.4、Supabase（service role）、Meta Graph API（IG）、pytest、uv、Docker Compose。

## Global Constraints

- `requires-python >=3.11`（`backend/pyproject.toml`，勿降）。
- 新依賴上限：`discord.py>=2.4,<3`。
- 所有 Discord SDK 呼叫只能出現在 `publisher_bot.py` 與 `bot/views.py`；`interactions.py` / `scheduler.py` / `review_poster.py` / `executor.py` **不得 import discord**。
- `social_posts` 每列鍵為 `(publish_date, media_type)`，`media_type ∈ {carousel, reel}`。
- 時間一律以 UTC ISO8601 字串存 `scheduled_at`；比較用 timezone-aware `datetime`。
- `DAILY_STORY_PUBLISH_ENABLED=0` 時 bot 保持連線但排程/發布 no-op。
- 只有 `config.discord_approver_ids` 內的 Discord user 能操作審核按鈕。
- 發布前必檢查：`status` 非終態（published/rejected/failed 視情況）且 `ig_post_id` 為空，避免重複發布。
- 測試指令（在 `backend/` 下）：`uv run pytest <path> -v`。
- Commit 訊息以繁體中文為主，結尾加 `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`。

## File Structure

```
supabase/migrations/
  20260709000000_add_bot_publish_columns_to_social_posts.sql   # 新增欄位

backend/src/lorescape_backend/social/
  post_log.py            # 修改：新增 stage_pending / set_* / list_* 等 helper
  executor.py            # 新增：從 row 狀態發布 carousel / reel
  bot/
    __init__.py          # 新增
    interactions.py      # 新增：approve/reject/schedule/publish_now/republish（純資料層）
    scheduler.py         # 新增：每分鐘迴圈，發到點且已核准的 row
    review_poster.py     # 新增：貼審核訊息迴圈（Discord 貼文以 callable 注入）
    views.py             # 新增：persistent View（四顆按鈕）+ 排程 modal（唯一碰 discord.py 的邏輯檔）
  publisher_bot.py       # 新增：Gateway 進入點，註冊 View/command、啟動背景迴圈
  publisher_daemon.py    # 修改：移除 cron，改為 back-fill CLI 薄殼（或刪除）
  reel_publisher.py      # 修改：抽出 caption/cover helper 供 executor 重用

backend/
  pyproject.toml         # 修改：加 discord.py
  Dockerfile             # 修改：確保 ffmpeg
  docker-compose.yml     # 修改：publisher 服務改跑 publisher_bot

backend/tests/
  _fakes.py              # 新增：In-memory 假 supabase（狀態化查詢）
  test_post_log.py       # 修改：新 helper 測試
  test_executor.py       # 新增
  test_bot_interactions.py   # 新增
  test_bot_scheduler.py      # 新增
  test_bot_review_poster.py  # 新增
  test_publisher_daemon.py   # 修改：對應 cron 移除

scripts/
  send_carousel_for_review.py   # 修改：只上傳 + 寫 pending row，移除 Discord 貼文
  send_reel_for_review.py       # 修改：只 rsync 後寫 pending row，移除 Discord 貼文與 ffmpeg 預覽
  tests/test_send_carousel_for_review.py  # 修改
```

---

## Task 1: Migration — 加發布 bot 需要的欄位

**Files:**
- Create: `supabase/migrations/20260709000000_add_bot_publish_columns_to_social_posts.sql`

**Interfaces:**
- Produces: `social_posts` 新增欄位 `review_decision TEXT`、`scheduled_at TIMESTAMPTZ`、`reviewed_by TEXT`、`reviewed_at TIMESTAMPTZ`、`overdue_notified_at TIMESTAMPTZ`。

- [ ] **Step 1: 寫 migration**

```sql
-- Discord 發布 bot 需要的欄位。
--
-- 新流程：本地只建 pending row（無 discord_message_id）；server bot 輪詢後
-- 貼帶按鈕的審核訊息並回填 message_id，再依按鈕互動寫 review_decision /
-- scheduled_at。排程迴圈到點且 review_decision='approved' 才發布。
--
-- review_decision 與 status 正交：可「已核准未排程」或「已排程未核准」。
-- overdue_notified_at：排程時間到但未核准時只提醒一次的去重欄位。
--
-- 表級 GRANT（20260705120000）已涵蓋後加欄位，無需新 GRANT。
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS review_decision TEXT
    CHECK (review_decision IN ('approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS overdue_notified_at TIMESTAMPTZ;

-- 加一個 'scheduled' 狀態（既有 CHECK 只允許 pending/published/failed/
-- rejected/skipped）。先移除舊 CHECK 再加新的。
ALTER TABLE public.social_posts
  DROP CONSTRAINT IF EXISTS social_posts_status_check;
ALTER TABLE public.social_posts
  ADD CONSTRAINT social_posts_status_check CHECK (
    status IN ('pending', 'scheduled', 'published', 'failed',
               'rejected', 'skipped')
  );
```

- [ ] **Step 2: 本地套用驗證（若有本地 Supabase）**

Run: `supabase db reset --local`（或在遠端 dashboard 手動套用）
Expected: 無錯誤；`social_posts` 出現新欄位、`status` 允許 `scheduled`。
若無本地 Supabase，改為人工檢查 SQL 語法後於部署階段套用。

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260709000000_add_bot_publish_columns_to_social_posts.sql
git commit -m "feat(db): social_posts 加發布 bot 欄位（review_decision/scheduled_at 等）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: post_log — 新增 bot 生命週期 helper

**Files:**
- Modify: `backend/src/lorescape_backend/social/post_log.py`
- Test: `backend/tests/test_post_log.py`

**Interfaces:**
- Consumes: 既有 `TABLE_NAME`、`get_post`、`mark_status`。
- Produces（全部 `supabase` 為第一位置參數，其餘 keyword-only）:
  - `stage_pending(supabase, *, publish_date: str, media_type: str, slide_urls: list[str] | None = None, caption: str | None = None) -> None`
  - `set_discord_message_id(supabase, *, publish_date: str, media_type: str, discord_message_id: str) -> None`
  - `set_review_decision(supabase, *, publish_date: str, media_type: str, decision: str, reviewed_by: str | None) -> None`
  - `set_schedule(supabase, *, publish_date: str, media_type: str, scheduled_at: str) -> None`
  - `mark_overdue_notified(supabase, *, publish_date: str, media_type: str) -> None`
  - `list_pending_unposted(supabase) -> list[dict]`
  - `list_scheduled_due(supabase, now_iso: str) -> list[dict]`

- [ ] **Step 1: 寫失敗測試**

在 `backend/tests/test_post_log.py` 末尾加：

```python
def test_stage_pending_upserts_clean_pending_row():
    client, table = _client()

    post_log.stage_pending(
        client,
        publish_date="2026-07-09",
        media_type="carousel",
        slide_urls=["https://x/1.jpg"],
        caption="cap",
    )

    payload, = table.upsert.call_args.args
    assert payload["status"] == "pending"
    assert payload["discord_message_id"] is None
    assert payload["review_decision"] is None
    assert payload["scheduled_at"] is None
    assert payload["overdue_notified_at"] is None
    assert payload["slide_urls"] == ["https://x/1.jpg"]
    assert payload["caption"] == "cap"
    assert (
        table.upsert.call_args.kwargs["on_conflict"]
        == "publish_date,media_type"
    )


def test_set_review_decision_writes_decision_and_reviewer():
    client, table = _client()

    post_log.set_review_decision(
        client,
        publish_date="2026-07-09",
        media_type="carousel",
        decision="approved",
        reviewed_by="user-1",
    )

    payload = table.update.call_args.args[0]
    assert payload["review_decision"] == "approved"
    assert payload["reviewed_by"] == "user-1"
    assert payload["reviewed_at"] is not None


def test_set_schedule_sets_scheduled_status():
    client, table = _client()

    post_log.set_schedule(
        client,
        publish_date="2026-07-09",
        media_type="reel",
        scheduled_at="2026-07-09T13:00:00+00:00",
    )

    payload = table.update.call_args.args[0]
    assert payload["scheduled_at"] == "2026-07-09T13:00:00+00:00"
    assert payload["status"] == "scheduled"


def test_list_pending_unposted_filters_status_and_null_message():
    client = MagicMock()
    chain = client.table.return_value.select.return_value
    chain.eq.return_value = chain
    chain.is_.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "r1"}])

    rows = post_log.list_pending_unposted(client)

    assert rows == [{"id": "r1"}]
    chain.eq.assert_any_call("status", "pending")
    chain.is_.assert_any_call("discord_message_id", "null")


def test_list_scheduled_due_filters_status_and_time():
    client = MagicMock()
    chain = client.table.return_value.select.return_value
    chain.eq.return_value = chain
    chain.lte.return_value = chain
    chain.execute.return_value = MagicMock(data=[{"id": "r2"}])

    rows = post_log.list_scheduled_due(client, "2026-07-09T13:00:00+00:00")

    assert rows == [{"id": "r2"}]
    chain.eq.assert_any_call("status", "scheduled")
    chain.lte.assert_any_call("scheduled_at", "2026-07-09T13:00:00+00:00")
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/test_post_log.py -v`
Expected: FAIL（`AttributeError: module ... has no attribute 'stage_pending'` 等）

- [ ] **Step 3: 實作 helper**

在 `post_log.py` 加（沿用 `from datetime import datetime, timezone`）:

```python
def stage_pending(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    slide_urls: list[str] | None = None,
    caption: str | None = None,
) -> None:
    """本地產製後建立一筆乾淨的 pending row（尚未貼 Discord）。"""
    payload: dict[str, Any] = {
        "publish_date": publish_date,
        "media_type": media_type,
        "status": "pending",
        "discord_message_id": None,
        "review_decision": None,
        "scheduled_at": None,
        "reviewed_by": None,
        "reviewed_at": None,
        "overdue_notified_at": None,
        "slide_urls": slide_urls,
        "caption": caption,
        "ig_post_id": None,
        "error": None,
        "published_at": None,
    }
    (
        supabase.table(TABLE_NAME)
        .upsert(payload, on_conflict="publish_date,media_type")
        .execute()
    )


def set_discord_message_id(
    supabase, *, publish_date: str, media_type: str, discord_message_id: str
) -> None:
    """bot 貼完審核訊息後回填 message id。"""
    _update(
        supabase, publish_date, media_type,
        {"discord_message_id": discord_message_id},
    )


def set_review_decision(
    supabase,
    *,
    publish_date: str,
    media_type: str,
    decision: str,
    reviewed_by: str | None,
) -> None:
    """寫審核意圖（approved / rejected）與稽核欄位。"""
    _update(
        supabase, publish_date, media_type,
        {
            "review_decision": decision,
            "reviewed_by": reviewed_by,
            "reviewed_at": datetime.now(timezone.utc).isoformat(),
        },
    )


def set_schedule(
    supabase, *, publish_date: str, media_type: str, scheduled_at: str
) -> None:
    """設排程時間並把狀態切到 'scheduled'。"""
    _update(
        supabase, publish_date, media_type,
        {"scheduled_at": scheduled_at, "status": "scheduled"},
    )


def mark_overdue_notified(
    supabase, *, publish_date: str, media_type: str
) -> None:
    """記下已對「排程到點但未核准」提醒過一次。"""
    _update(
        supabase, publish_date, media_type,
        {"overdue_notified_at": datetime.now(timezone.utc).isoformat()},
    )


def list_pending_unposted(supabase) -> list[dict[str, Any]]:
    """status='pending' 且還沒貼過 Discord 的 row。"""
    response = (
        supabase.table(TABLE_NAME)
        .select("*")
        .eq("status", "pending")
        .is_("discord_message_id", "null")
        .execute()
    )
    return response.data or []


def list_scheduled_due(supabase, now_iso: str) -> list[dict[str, Any]]:
    """status='scheduled' 且 scheduled_at 已到的 row。"""
    response = (
        supabase.table(TABLE_NAME)
        .select("*")
        .eq("status", "scheduled")
        .lte("scheduled_at", now_iso)
        .execute()
    )
    return response.data or []


def _update(
    supabase, publish_date: str, media_type: str, patch: dict[str, Any]
) -> None:
    (
        supabase.table(TABLE_NAME)
        .update(patch)
        .eq("publish_date", publish_date)
        .eq("media_type", media_type)
        .execute()
    )
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_post_log.py -v`
Expected: PASS（全部）

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/post_log.py backend/tests/test_post_log.py
git commit -m "feat(social): post_log 新增 bot 生命週期 helper

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: reel_publisher — 抽出 caption / cover helper 供重用

**Files:**
- Modify: `backend/src/lorescape_backend/social/reel_publisher.py`
- Test: `backend/tests/test_reel_publisher.py`

把私有的 `_build_caption` 改成公開可重用的 `build_reel_caption`，讓 executor 不用複製一份。行為完全不變。

**Interfaces:**
- Produces: `build_reel_caption(config: Config, supabase, date_str: str, day_dir: Path) -> str`（等同原 `_build_caption`）。

- [ ] **Step 1: 改名並保留相容**

在 `reel_publisher.py`：把 `def _build_caption(` 改名為 `def build_reel_caption(`，並在原本 `run_reel_publish_job` 內呼叫處改成 `build_reel_caption(...)`。不改任何邏輯。

- [ ] **Step 2: 跑既有 reel 測試確認不回歸**

Run: `cd backend && uv run pytest tests/test_reel_publisher.py -v`
Expected: PASS（若測試曾引用 `_build_caption` 私名，一併改為 `build_reel_caption`）

- [ ] **Step 3: Commit**

```bash
git add backend/src/lorescape_backend/social/reel_publisher.py backend/tests/test_reel_publisher.py
git commit -m "refactor(reel): _build_caption 改公開 build_reel_caption 供 executor 重用

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: executor — 從 row 狀態發布 carousel / reel

**Files:**
- Create: `backend/src/lorescape_backend/social/executor.py`
- Test: `backend/tests/test_executor.py`

**Interfaces:**
- Consumes: `instagram.publish_carousel`、`instagram.publish_reel`、`reel_cover.build_cover_url`、`reel_publisher.build_reel_caption`、`post_log.record_post`、`config.instagram_enabled` / `daily_video_dir` / `ig_user_id` / `meta_page_access_token`。
- Produces:
  - `publish_row(config: Config, supabase, row: dict) -> bool` — 依 `row['media_type']` 分派；回傳是否成功發布。發布前守衛：`row['status']` 已是 `published` 或已有 `ig_post_id` → 直接回 True 不重發。
  - `publish_carousel_row(config, supabase, row: dict) -> bool`
  - `publish_reel_row(config, supabase, row: dict) -> bool`

- [ ] **Step 1: 寫失敗測試**

Create `backend/tests/test_executor.py`:

```python
"""executor.publish_row 發布行為測試。"""
from __future__ import annotations

import dataclasses
from unittest.mock import MagicMock, patch

import pytest

from lorescape_backend.social import executor


def _client():
    client = MagicMock()
    table = client.table.return_value
    table.upsert.return_value.execute.return_value = MagicMock(data=None)
    return client, table


def _carousel_row(**overrides):
    base = dict(
        id="r1", publish_date="2026-07-09", media_type="carousel",
        status="scheduled", review_decision="approved",
        slide_urls=["https://x/1.jpg", "https://x/2.jpg"],
        caption="cap", ig_post_id=None,
    )
    base.update(overrides)
    return base


@patch("lorescape_backend.social.executor.instagram.publish_carousel",
       return_value="ig-123")
def test_publish_carousel_row_publishes_and_records(mock_pub, fake_config):
    client, table = _client()

    ok = executor.publish_carousel_row(fake_config, client, _carousel_row())

    assert ok is True
    mock_pub.assert_called_once()
    kwargs = mock_pub.call_args.kwargs
    assert kwargs["image_urls"] == ["https://x/1.jpg", "https://x/2.jpg"]
    assert kwargs["caption"] == "cap"
    payload, = table.upsert.call_args.args
    assert payload["status"] == "published"
    assert payload["ig_post_id"] == "ig-123"


@patch("lorescape_backend.social.executor.instagram.publish_carousel",
       side_effect=RuntimeError("boom"))
def test_publish_carousel_row_records_failure(mock_pub, fake_config):
    client, table = _client()

    ok = executor.publish_carousel_row(fake_config, client, _carousel_row())

    assert ok is False
    payload, = table.upsert.call_args.args
    assert payload["status"] == "failed"
    assert "boom" in payload["error"]


@patch("lorescape_backend.social.executor.instagram.publish_carousel")
def test_publish_row_skips_already_published(mock_pub, fake_config):
    client, _ = _client()

    ok = executor.publish_row(
        fake_config, client, _carousel_row(ig_post_id="ig-old"),
    )

    assert ok is True
    mock_pub.assert_not_called()


@patch("lorescape_backend.social.executor.instagram.publish_carousel")
def test_publish_carousel_row_noops_when_ig_disabled(mock_pub):
    from lorescape_backend.config import Config
    config = Config(
        supabase_url="u", supabase_service_role_key="k", gemini_api_key="g",
        discord_webhook_url=None, discord_bot_token=None,
        discord_review_channel_id=None, discord_approver_ids=(),
        ig_user_id=None, meta_page_access_token=None,
        brand_handle_ig="", cta_text="",
    )
    client, table = _client()

    ok = executor.publish_carousel_row(config, client, _carousel_row())

    assert ok is False
    mock_pub.assert_not_called()
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/test_executor.py -v`
Expected: FAIL（`ModuleNotFoundError: ... executor`）

- [ ] **Step 3: 實作 executor**

Create `backend/src/lorescape_backend/social/executor.py`:

```python
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
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_executor.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/executor.py backend/tests/test_executor.py
git commit -m "feat(social): 新增 executor 從 row 狀態發布 carousel/reel

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: 測試用 In-memory 假 supabase

**Files:**
- Create: `backend/tests/_fakes.py`

interactions / scheduler / review_poster 的測試需要「狀態化」的 supabase（寫進去再查出來），MagicMock chain 難以表達。提供一個支援 `table().select().eq().is_().lte().execute()`、`upsert()`、`update().eq().execute()` 的最小記憶體實作。

**Interfaces:**
- Produces: `FakeSupabase()`，內部以 `list[dict]` 存 `social_posts`；`.rows` 可直接讀取驗證。

- [ ] **Step 1: 實作假 client（本身即測試載體，先寫自我驗證測試）**

Create `backend/tests/_fakes.py`:

```python
"""測試用最小記憶體 Supabase 假件（只支援 social_posts 用到的操作）。"""
from __future__ import annotations

from typing import Any


class _Result:
    def __init__(self, data):
        self.data = data


class _Query:
    def __init__(self, rows: list[dict], op: str, payload: Any = None):
        self._rows = rows
        self._op = op
        self._payload = payload
        self._filters: list[tuple[str, str, Any]] = []

    def eq(self, col, val):
        self._filters.append(("eq", col, val))
        return self

    def is_(self, col, val):
        self._filters.append(("is", col, val))
        return self

    def lte(self, col, val):
        self._filters.append(("lte", col, val))
        return self

    def limit(self, _n):
        return self

    def _match(self, row) -> bool:
        for kind, col, val in self._filters:
            if kind == "eq" and row.get(col) != val:
                return False
            if kind == "is" and not (val == "null" and row.get(col) is None):
                return False
            if kind == "lte" and not (
                row.get(col) is not None and row[col] <= val
            ):
                return False
        return True

    def execute(self):
        matched = [r for r in self._rows if self._match(r)]
        if self._op == "select":
            return _Result([dict(r) for r in matched])
        if self._op == "update":
            for r in matched:
                r.update(self._payload)
            return _Result([dict(r) for r in matched])
        raise AssertionError(f"unsupported op {self._op}")


class _Table:
    def __init__(self, rows: list[dict]):
        self._rows = rows

    def select(self, *_a, **_k):
        return _Query(self._rows, "select")

    def update(self, payload):
        return _Query(self._rows, "update", payload)

    def upsert(self, payload, *, on_conflict=None):
        key_cols = (on_conflict or "").split(",")
        existing = None
        for r in self._rows:
            if all(r.get(c) == payload.get(c) for c in key_cols if c):
                existing = r
                break
        if existing is not None:
            existing.update(payload)
        else:
            self._rows.append(dict(payload))
        return _NoopExecute()


class _NoopExecute:
    def execute(self):
        return _Result(None)


class FakeSupabase:
    """支援 social_posts CRUD 的假 client。`.rows` 為底層資料。"""

    def __init__(self, rows: list[dict] | None = None):
        self.rows = rows or []

    def table(self, name):
        assert name == "social_posts", f"unexpected table {name}"
        return _Table(self.rows)
```

Add `backend/tests/test_fakes.py`:

```python
from tests._fakes import FakeSupabase


def test_upsert_then_select_by_key():
    sb = FakeSupabase()
    sb.table("social_posts").upsert(
        {"publish_date": "d1", "media_type": "carousel", "status": "pending"},
        on_conflict="publish_date,media_type",
    ).execute()

    got = (
        sb.table("social_posts").select("*")
        .eq("publish_date", "d1").eq("media_type", "carousel").execute()
    )
    assert got.data[0]["status"] == "pending"


def test_update_mutates_matching_rows():
    sb = FakeSupabase([
        {"publish_date": "d1", "media_type": "reel", "status": "pending"},
    ])
    sb.table("social_posts").update({"status": "scheduled"}).eq(
        "publish_date", "d1"
    ).eq("media_type", "reel").execute()
    assert sb.rows[0]["status"] == "scheduled"


def test_is_null_and_lte_filters():
    sb = FakeSupabase([
        {"id": "a", "status": "pending", "discord_message_id": None},
        {"id": "b", "status": "pending", "discord_message_id": "m"},
    ])
    got = (
        sb.table("social_posts").select("*")
        .eq("status", "pending").is_("discord_message_id", "null").execute()
    )
    assert [r["id"] for r in got.data] == ["a"]
```

- [ ] **Step 2: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_fakes.py -v`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add backend/tests/_fakes.py backend/tests/test_fakes.py
git commit -m "test: 新增 In-memory 假 Supabase 供 bot 邏輯測試

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: interactions — 按鈕/指令的狀態轉移

**Files:**
- Create: `backend/src/lorescape_backend/social/bot/__init__.py`（空檔）
- Create: `backend/src/lorescape_backend/social/bot/interactions.py`
- Test: `backend/tests/test_bot_interactions.py`

**Interfaces:**
- Consumes: `post_log.set_review_decision` / `set_schedule` / `mark_status` / `get_post`、`executor.publish_row`。
- Produces（皆為純函式，不 import discord）:
  - `approve(supabase, *, publish_date, media_type, reviewed_by) -> None`
  - `reject(supabase, *, publish_date, media_type, reviewed_by) -> None`
  - `schedule(supabase, *, publish_date, media_type, scheduled_at: datetime) -> None`
  - `publish_now(config, supabase, *, publish_date, media_type, reviewed_by) -> bool`
  - `republish(config, supabase, *, publish_date, media_type) -> bool`

- [ ] **Step 1: 寫失敗測試**

Create `backend/tests/test_bot_interactions.py`:

```python
"""bot.interactions 狀態轉移測試。"""
from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import patch

from lorescape_backend.social.bot import interactions
from tests._fakes import FakeSupabase


def _pending(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="pending",
        discord_message_id="m1", review_decision=None, scheduled_at=None,
        ig_post_id=None, slide_urls=["u"], caption="c",
    )
    base.update(o)
    return base


def test_approve_sets_decision_only():
    sb = FakeSupabase([_pending()])
    interactions.approve(
        sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert sb.rows[0]["review_decision"] == "approved"
    assert sb.rows[0]["status"] == "pending"  # 未動 status


def test_reject_sets_status_rejected():
    sb = FakeSupabase([_pending()])
    interactions.reject(
        sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert sb.rows[0]["review_decision"] == "rejected"
    assert sb.rows[0]["status"] == "rejected"


def test_schedule_sets_time_and_scheduled_status():
    sb = FakeSupabase([_pending()])
    when = datetime(2026, 7, 9, 13, 0, tzinfo=timezone.utc)
    interactions.schedule(
        sb, publish_date="2026-07-09", media_type="carousel",
        scheduled_at=when,
    )
    assert sb.rows[0]["status"] == "scheduled"
    assert sb.rows[0]["scheduled_at"] == when.isoformat()


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_publish_now_approves_then_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_pending()])
    ok = interactions.publish_now(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
        reviewed_by="u1",
    )
    assert ok is True
    assert sb.rows[0]["review_decision"] == "approved"
    mock_pub.assert_called_once()


@patch("lorescape_backend.social.bot.interactions.executor.publish_row",
       return_value=True)
def test_republish_resets_terminal_and_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_pending(status="failed", review_decision="approved")])
    ok = interactions.republish(
        fake_config, sb, publish_date="2026-07-09", media_type="carousel",
    )
    assert ok is True
    mock_pub.assert_called_once()
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/test_bot_interactions.py -v`
Expected: FAIL（`ModuleNotFoundError`）

- [ ] **Step 3: 實作**

Create `backend/src/lorescape_backend/social/bot/__init__.py`（空）。

Create `backend/src/lorescape_backend/social/bot/interactions.py`:

```python
"""Discord 審核互動 → social_posts 狀態轉移（不 import discord）。

按鈕 handler（views.py）與 slash command 都轉呼叫這裡的純函式，讓狀態
機可獨立於 Gateway 單元測試。
"""
from __future__ import annotations

import logging
from datetime import datetime

from lorescape_backend.config import Config
from lorescape_backend.social import executor, post_log

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
    return executor.publish_row(config, supabase, row)
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_bot_interactions.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/bot/__init__.py backend/src/lorescape_backend/social/bot/interactions.py backend/tests/test_bot_interactions.py
git commit -m "feat(bot): interactions 審核互動狀態轉移

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: scheduler — 排程迴圈

**Files:**
- Create: `backend/src/lorescape_backend/social/bot/scheduler.py`
- Test: `backend/tests/test_bot_scheduler.py`

**Interfaces:**
- Consumes: `post_log.list_scheduled_due` / `mark_overdue_notified`、`executor.publish_row`、`config.daily_story_publish_enabled`。
- Produces: `tick(config: Config, supabase, *, now: datetime, notify: Callable[[str, str], None]) -> None`
  - `notify(publish_date, message)` 由 bot 注入（發 Discord 提醒），測試傳假件。

- [ ] **Step 1: 寫失敗測試**

Create `backend/tests/test_bot_scheduler.py`:

```python
"""bot.scheduler.tick 排程迴圈測試。"""
from __future__ import annotations

import dataclasses
from datetime import datetime, timezone
from unittest.mock import patch

from lorescape_backend.social.bot import scheduler
from tests._fakes import FakeSupabase

NOW = datetime(2026, 7, 9, 13, 0, tzinfo=timezone.utc)
PAST = "2026-07-09T12:00:00+00:00"
FUTURE = "2026-07-09T14:00:00+00:00"


def _row(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="scheduled",
        review_decision="approved", scheduled_at=PAST,
        overdue_notified_at=None, ig_post_id=None,
    )
    base.update(o)
    return base


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row",
       return_value=True)
def test_due_and_approved_publishes(mock_pub, fake_config):
    sb = FakeSupabase([_row()])
    notes = []
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    mock_pub.assert_called_once()
    assert notes == []


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_due_but_unapproved_notifies_once(mock_pub, fake_config):
    sb = FakeSupabase([_row(review_decision=None)])
    notes = []
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: notes.append((d, m)))
    mock_pub.assert_not_called()
    assert len(notes) == 1  # 只提醒一次
    assert sb.rows[0]["overdue_notified_at"] is not None


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_not_due_is_ignored(mock_pub, fake_config):
    sb = FakeSupabase([_row(scheduled_at=FUTURE)])
    scheduler.tick(fake_config, sb, now=NOW, notify=lambda d, m: None)
    mock_pub.assert_not_called()


@patch("lorescape_backend.social.bot.scheduler.executor.publish_row")
def test_publish_disabled_noops(mock_pub, fake_config):
    config = dataclasses.replace(fake_config, daily_story_publish_enabled=False)
    sb = FakeSupabase([_row()])
    scheduler.tick(config, sb, now=NOW, notify=lambda d, m: None)
    mock_pub.assert_not_called()
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/test_bot_scheduler.py -v`
Expected: FAIL（`ModuleNotFoundError`）

- [ ] **Step 3: 實作**

Create `backend/src/lorescape_backend/social/bot/scheduler.py`:

```python
"""排程迴圈：發布到點且已核准的 social_posts row。

由 publisher_bot 每分鐘呼叫一次 tick()。到點但尚未核准的 row 不發，
只透過注入的 notify 提醒一次（overdue_notified_at 去重）。
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Callable

from lorescape_backend.config import Config
from lorescape_backend.social import executor, post_log

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
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_bot_scheduler.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/bot/scheduler.py backend/tests/test_bot_scheduler.py
git commit -m "feat(bot): scheduler 排程迴圈（到點且已核准才發）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 8: review_poster — 貼審核訊息迴圈

**Files:**
- Create: `backend/src/lorescape_backend/social/bot/review_poster.py`
- Test: `backend/tests/test_bot_review_poster.py`

**Interfaces:**
- Consumes: `post_log.list_pending_unposted` / `set_discord_message_id`。
- Produces: `tick(supabase, *, post_review: Callable[[dict], str | None]) -> None`
  - `post_review(row)` 由 bot 注入：實際下載素材、貼帶按鈕的 Discord 訊息、回傳 message id（None 表示這輪略過，例如 reel 影片還沒 rsync 到）。

- [ ] **Step 1: 寫失敗測試**

Create `backend/tests/test_bot_review_poster.py`:

```python
"""bot.review_poster.tick 測試。"""
from __future__ import annotations

from lorescape_backend.social.bot import review_poster
from tests._fakes import FakeSupabase


def _pending(**o):
    base = dict(
        publish_date="2026-07-09", media_type="carousel", status="pending",
        discord_message_id=None, slide_urls=["u"], caption="c",
    )
    base.update(o)
    return base


def test_posts_and_backfills_message_id():
    sb = FakeSupabase([_pending()])
    review_poster.tick(sb, post_review=lambda row: "msg-77")
    assert sb.rows[0]["discord_message_id"] == "msg-77"


def test_skips_when_poster_returns_none():
    sb = FakeSupabase([_pending()])
    review_poster.tick(sb, post_review=lambda row: None)
    assert sb.rows[0]["discord_message_id"] is None


def test_ignores_already_posted_rows():
    sb = FakeSupabase([_pending(discord_message_id="already")])
    calls = []
    review_poster.tick(sb, post_review=lambda row: calls.append(row) or "x")
    assert calls == []  # list_pending_unposted 已排除有 message id 的
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/test_bot_review_poster.py -v`
Expected: FAIL

- [ ] **Step 3: 實作**

Create `backend/src/lorescape_backend/social/bot/review_poster.py`:

```python
"""輪詢尚未貼過 Discord 的 pending row，貼審核訊息並回填 message id。

實際的 Discord 貼文（下載素材 / 附按鈕）由 publisher_bot 注入的
post_review callable 執行，本模組只管迴圈與 DB 回填，維持可測試。
"""
from __future__ import annotations

import logging
from typing import Callable

from lorescape_backend.social import post_log

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
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd backend && uv run pytest tests/test_bot_review_poster.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/bot/review_poster.py backend/tests/test_bot_review_poster.py
git commit -m "feat(bot): review_poster 貼審核訊息迴圈

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 9: Discord bot 接線（views + publisher_bot）

**Files:**
- Create: `backend/src/lorescape_backend/social/bot/views.py`
- Create: `backend/src/lorescape_backend/social/publisher_bot.py`
- Modify: `backend/pyproject.toml`（加 `discord.py`）

這是唯一碰 discord.py 的實作，Gateway 無法單元測試，靠結構隔離 + 手動驗證。所有真正的判斷都委派給前面已測過的純函式。

**Interfaces:**
- Consumes: `interactions`（approve/reject/schedule/publish_now/republish）、`scheduler.tick`、`review_poster.tick`、`post_log`、`card_storage`、`instagram`（重用發布）、`discord_review`（沿用附件貼法可參考）。
- Produces: `python -m lorescape_backend.social.publisher_bot` 進入點。

- [ ] **Step 1: 加依賴**

在 `backend/pyproject.toml` 的 `dependencies` 加一行：

```toml
    "discord.py>=2.4,<3",
```

Run: `cd backend && uv lock && uv sync`
Expected: 成功解析，`discord.py` 進 lock。

- [ ] **Step 2: 寫 views.py（persistent View + modal）**

要點（實作時照 discord.py 2.x API）：

```python
"""審核訊息的按鈕 View 與排程 modal（唯一碰 discord.py 的邏輯檔）。"""
from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo

import discord

from lorescape_backend.config import Config
from lorescape_backend.social.bot import interactions

TAIPEI = ZoneInfo("Asia/Taipei")


def _parse_target(custom_id: str) -> tuple[str, str]:
    """custom_id 形如 'approve:2026-07-09:carousel' → (date, media_type)。"""
    _, publish_date, media_type = custom_id.split(":")
    return publish_date, media_type


class ReviewView(discord.ui.View):
    """persistent View：四顆按鈕，custom_id 帶 date + media_type。"""

    def __init__(self, config: Config, supabase, publish_date: str,
                 media_type: str):
        super().__init__(timeout=None)
        self._config = config
        self._supabase = supabase
        suffix = f"{publish_date}:{media_type}"
        # 為每顆按鈕設穩定 custom_id，使重啟後仍可路由（persistent view）。
        self.approve.custom_id = f"approve:{suffix}"
        self.schedule.custom_id = f"schedule:{suffix}"
        self.publish_now.custom_id = f"publish_now:{suffix}"
        self.reject.custom_id = f"reject:{suffix}"

    async def _guard(self, interaction: discord.Interaction) -> bool:
        if str(interaction.user.id) not in self._config.discord_approver_ids:
            await interaction.response.send_message(
                "你不在核准名單內。", ephemeral=True)
            return False
        return True

    @discord.ui.button(label="✅ 核准", style=discord.ButtonStyle.success)
    async def approve(self, interaction, button):
        if not await self._guard(interaction):
            return
        d, m = _parse_target(button.custom_id)
        interactions.approve(self._supabase, publish_date=d, media_type=m,
                             reviewed_by=str(interaction.user.id))
        await interaction.response.send_message(
            f"已核准 {m} {d}。排程到點會自動發，或按 🚀 立即發布。",
            ephemeral=True)

    @discord.ui.button(label="🕘 排程", style=discord.ButtonStyle.primary)
    async def schedule(self, interaction, button):
        if not await self._guard(interaction):
            return
        d, m = _parse_target(button.custom_id)
        await interaction.response.send_modal(
            ScheduleModal(self._supabase, d, m))

    @discord.ui.button(label="🚀 立即發布", style=discord.ButtonStyle.primary)
    async def publish_now(self, interaction, button):
        if not await self._guard(interaction):
            return
        d, m = _parse_target(button.custom_id)
        await interaction.response.defer(ephemeral=True)
        ok = interactions.publish_now(
            self._config, self._supabase, publish_date=d, media_type=m,
            reviewed_by=str(interaction.user.id))
        await interaction.followup.send(
            f"{'已發布' if ok else '發布失敗，見 log'} {m} {d}。",
            ephemeral=True)

    @discord.ui.button(label="❌ 拒絕", style=discord.ButtonStyle.danger)
    async def reject(self, interaction, button):
        if not await self._guard(interaction):
            return
        d, m = _parse_target(button.custom_id)
        interactions.reject(self._supabase, publish_date=d, media_type=m,
                            reviewed_by=str(interaction.user.id))
        await interaction.response.send_message(
            f"已拒絕 {m} {d}。", ephemeral=True)


class ScheduleModal(discord.ui.Modal, title="排程發布時間"):
    """輸入 Asia/Taipei 的 YYYY-MM-DD HH:MM。"""

    when = discord.ui.TextInput(
        label="時間 (Asia/Taipei)", placeholder="2026-07-09 21:00")

    def __init__(self, supabase, publish_date: str, media_type: str):
        super().__init__()
        self._supabase = supabase
        self._publish_date = publish_date
        self._media_type = media_type
        self.when.default = f"{publish_date} 21:00"

    async def on_submit(self, interaction: discord.Interaction):
        try:
            naive = datetime.strptime(self.when.value.strip(),
                                      "%Y-%m-%d %H:%M")
        except ValueError:
            await interaction.response.send_message(
                "格式需為 YYYY-MM-DD HH:MM。", ephemeral=True)
            return
        when_utc = naive.replace(tzinfo=TAIPEI).astimezone(timezone.utc)
        interactions.schedule(
            self._supabase, publish_date=self._publish_date,
            media_type=self._media_type, scheduled_at=when_utc)
        await interaction.response.send_message(
            f"已排程 {self._media_type} {self._publish_date} 於 "
            f"{self.when.value}（需已核准才會發）。", ephemeral=True)
```

- [ ] **Step 3: 寫 publisher_bot.py（Gateway 進入點）**

要點：

```python
"""Discord 發布 bot：Gateway 常駐，審核/排程/發布的唯一 server 端。"""
from __future__ import annotations

import asyncio
import io
import logging
from pathlib import Path

import discord
import requests
from discord.ext import tasks
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.social import card_storage, post_log, reel_publisher
from lorescape_backend.social.bot import review_poster, scheduler
from lorescape_backend.social.bot.views import ReviewView

logger = logging.getLogger(__name__)
VIDEO_FILENAME = "final.mp4"
MAX_ATTACHMENT_BYTES = int(9.5 * 1024 * 1024)


class PublisherBot(discord.Client):
    def __init__(self, config: Config):
        intents = discord.Intents.default()
        super().__init__(intents=intents)
        self._config = config
        self._supabase = create_client(
            config.supabase_url, config.supabase_service_role_key)

    async def setup_hook(self):
        # persistent view：註冊一個「模板」讓重啟前訊息的按鈕仍可路由。
        self.add_view(ReviewView(self._config, self._supabase, "*", "*"))
        self._poll_loop.start()

    def _post_review(self, row: dict) -> str | None:
        """在審核頻道貼帶按鈕的訊息，回傳 message id（reel 未就緒回 None）。"""
        channel = self.get_channel(int(self._config.discord_review_channel_id))
        files, content = self._build_attachments(row)
        if files is None:
            return None
        view = ReviewView(self._config, self._supabase,
                          row["publish_date"], row["media_type"])
        # discord.py 的 send 是 async；用 run_coroutine_threadsafe 或在
        # loop 內呼叫。實作時把 _post_review 也改 async 並於 loop 內 await。
        msg = asyncio.run_coroutine_threadsafe(
            channel.send(content=content, files=files, view=view),
            self.loop).result()
        return str(msg.id)

    def _build_attachments(self, row):
        """carousel 從 slide_urls 下載；reel 從 volume 讀並轉 720p 預覽。"""
        # ...（見下方註記）
        ...

    @tasks.loop(seconds=60)
    async def _poll_loop(self):
        review_poster.tick(self._supabase, post_review=self._post_review)
        scheduler.tick(
            self._config, self._supabase,
            now=discord.utils.utcnow(), notify=self._notify)

    def _notify(self, publish_date: str, message: str):
        channel = self.get_channel(int(self._config.discord_review_channel_id))
        asyncio.run_coroutine_threadsafe(
            channel.send(f"[{publish_date}] {message}"), self.loop)


def main():
    logging.basicConfig(level=logging.INFO)
    config = Config.from_env()
    if not config.review_enabled:
        raise SystemExit("review not configured (bot token/channel/approvers)")
    PublisherBot(config).run(config.discord_bot_token)


if __name__ == "__main__":
    main()
```

> 實作註記：
> - `_post_review` / `_build_attachments` 建議整段寫成 async 並在 `_poll_loop`（已在 event loop 內）直接 `await`，避免 `run_coroutine_threadsafe` 的繞法。上面示意用的是同步簽名以對齊 `review_poster` 注入的 callable；實作時把 `review_poster.tick` 的 `post_review` 改成可接受 async callable，或在 bot 內用一個同步包裝在 loop 上 await。**擇一即可，二者都行**——關鍵是判斷邏輯已在純函式測過，這裡只接線。
> - carousel `_build_attachments`：對 `row["slide_urls"]` 逐一 `requests.get` 下載成 `discord.File(io.BytesIO(bytes), filename=...)`；content 用「Wander carousel {date} — 按鈕操作」。
> - reel `_build_attachments`：`video = Path(config.daily_video_dir)/row["publish_date"]/final.mp4`；不存在則回 `(None, None)`（回 None → 這輪略過，等 rsync 完成）；>9.5MB 用 ffmpeg 轉 720p 預覽（見 scripts/send_reel_for_review.py 既有指令）當附件。
> - persistent view 的 `*:*` 模板：discord.py 以 `custom_id` 前綴路由；若「模板」無法涵蓋動態 date，改為在 `on_interaction` 手動解析 `custom_id` 前綴並呼叫 interactions，不依賴 add_view 的欄位比對。實作時二選一，以能路由重啟前訊息為準。

- [ ] **Step 4: 匯入健全性檢查**

Run: `cd backend && uv run python -c "import lorescape_backend.social.publisher_bot; import lorescape_backend.social.bot.views; print('ok')"`
Expected: 印出 `ok`（無 import 錯誤）

- [ ] **Step 5: 全套單元測試回歸**

Run: `cd backend && uv run pytest -q`
Expected: PASS（新舊測試全綠）

- [ ] **Step 6: 手動驗證（在有 .env 的環境）**

1. `cd backend && uv run python -m lorescape_backend.social.publisher_bot`，確認 log 出現 bot 上線、`_poll_loop` 啟動。
2. 手動在 Supabase 插一筆 carousel pending row（帶 slide_urls），確認一分鐘內審核頻道出現帶四顆按鈕的訊息。
3. 按 🚀 立即發布 → 確認 IG 出現貼文、row 變 `published`。
4. 另一筆按 🕘 排程設近未來時間但不按 ✅ → 到點收到「尚未核准」提醒且未發布；按 ✅ 後下一輪發布。

- [ ] **Step 7: Commit**

```bash
git add backend/src/lorescape_backend/social/bot/views.py backend/src/lorescape_backend/social/publisher_bot.py backend/pyproject.toml backend/uv.lock
git commit -m "feat(bot): Discord Gateway 發布 bot（按鈕/modal + 排程/貼審核迴圈）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 10: 部署 — 換掉 publisher_daemon，容器改跑 bot

**Files:**
- Modify: `backend/docker-compose.yml`
- Modify: `backend/Dockerfile`（確保 ffmpeg）
- Modify: `backend/src/lorescape_backend/social/publisher_daemon.py`
- Modify: `backend/tests/test_publisher_daemon.py`

**Interfaces:**
- Produces: `publisher` 容器改跑 `python -m lorescape_backend.social.publisher_bot`；`publisher_daemon` 的三個固定 cron 移除。

- [ ] **Step 1: docker-compose 換 command**

在 `backend/docker-compose.yml` 的 `publisher` 服務，把 `command` 改為：

```yaml
    command: ["python", "-m", "lorescape_backend.social.publisher_bot"]
```

（保留 `env_file`、`DAILY_VIDEO_DIR` 環境變數與 `daily_video` volume、`restart: unless-stopped`、`depends_on: [api]`。）

- [ ] **Step 2: Dockerfile 確保 ffmpeg**

檢查 `backend/Dockerfile` 是否已裝 `ffmpeg`；若無，在系統套件安裝層加入（Debian 基底範例）：

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*
```

Run: `cd backend && docker build -t lorescape-backend:latest .`
Expected: build 成功；`docker run --rm lorescape-backend:latest ffmpeg -version` 有輸出。

- [ ] **Step 3: publisher_daemon 移除 cron（改為 back-fill CLI 薄殼）**

把 `publisher_daemon.py` 內 `_register_jobs`／APScheduler／cron 常數整段移除，改成保留一個手動 back-fill 用途的最小 CLI（呼叫既有 `run_publish_job` / `run_reel_publish_job`），或直接刪檔並在 README 指向 `publisher.py` / `reel_publisher.py` 的既有 CLI。**建議**：刪除 `publisher_daemon.py` 與其測試，因為排程已由 bot 承擔、back-fill 由既有兩支 CLI 與 bot 的 `/republish` 覆蓋。

- [ ] **Step 4: 調整 / 移除 daemon 測試**

若刪除 `publisher_daemon.py`：`git rm backend/tests/test_publisher_daemon.py`。
若保留薄殼：改寫 `test_publisher_daemon.py` 只驗證薄殼 CLI 呼叫 `run_publish_job` / `run_reel_publish_job`，移除 cron 相關斷言。

Run: `cd backend && uv run pytest -q`
Expected: PASS（無殘留 import 錯誤）

- [ ] **Step 5: Commit**

```bash
git add backend/docker-compose.yml backend/Dockerfile
git rm backend/src/lorescape_backend/social/publisher_daemon.py backend/tests/test_publisher_daemon.py  # 若採刪除方案
git commit -m "chore(deploy): publisher 容器改跑 Discord bot，移除固定 cron

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 11: 本地端 — send 腳本只上傳 + 寫 pending row

**Files:**
- Modify: `scripts/send_carousel_for_review.py`
- Modify: `scripts/send_reel_for_review.py`
- Modify: `scripts/upload_reel_to_vps.sh`（若它呼叫 send_reel_for_review）
- Test: `scripts/tests/test_send_carousel_for_review.py`

**Interfaces:**
- Consumes: `post_log.stage_pending`、`card_storage.upload_card_image`。
- Produces: carousel/reel 的本地步驟只「上傳素材 + `stage_pending`」，不再貼 Discord。

- [ ] **Step 1: 改寫 send_carousel_for_review 的測試**

在 `scripts/tests/test_send_carousel_for_review.py`：移除對 `discord_review.send_images_for_review` 的期待，改為斷言「呼叫 `card_storage.upload_card_image` 上傳每張、呼叫 `post_log.stage_pending` 帶 slide_urls + caption、不呼叫任何 discord_review 函式」。（保留既有「找不到 slide/ caption 檔即報錯」的測試。）

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd scripts && uv run pytest tests/test_send_carousel_for_review.py -v`
Expected: FAIL（仍在呼叫 discord）

- [ ] **Step 3: 改寫 send_carousel_for_review.py**

把 `main()` 內「`discord_review.send_images_for_review(...)` + `post_log.record_review_pending(...)`」整段換成：

```python
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )
    slide_urls = [
        card_storage.upload_card_image(
            supabase, data,
            path=f"wander/{args.date}/{path.name}",
            content_type="image/jpeg",
        )
        for path, data in zip(slide_paths, slide_bytes)
    ]
    post_log.stage_pending(
        supabase,
        publish_date=args.date,
        media_type="carousel",
        slide_urls=slide_urls,
        caption=caption,
    )
    print(
        f"Uploaded {len(slide_urls)} slides + staged pending row for "
        f"{args.date}. 發布 bot 會在一分鐘內於 Discord 貼審核訊息。"
    )
    return 0
```

移除不再需要的 `discord_review` import 與 Discord 設定檢查（bot 端才需要 token；本地只需 Supabase）。移除 `MAX_ATTACHMENT_BYTES` 相關的附件上限檢查（不再走 Discord 附件；改由 bot 端處理）。

- [ ] **Step 4: 跑測試確認通過**

Run: `cd scripts && uv run pytest tests/test_send_carousel_for_review.py -v`
Expected: PASS

- [ ] **Step 5: 改寫 send_reel_for_review.py**

把 Discord 貼文 + 720p 預覽轉檔整段移除，改為：rsync（若此腳本負責）後，只 `post_log.stage_pending(supabase, publish_date=date, media_type="reel")`（reel row 無 slide_urls/caption；caption 由 bot 端從 narration.txt + story row 組）。ffmpeg 預覽轉檔的責任移到 bot 端（Task 9）。若 `upload_reel_to_vps.sh` 呼叫本腳本，確認其流程仍為「rsync 影片 → 寫 pending row」。

- [ ] **Step 6: scripts 全測試回歸**

Run: `cd scripts && uv run pytest -q`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add scripts/send_carousel_for_review.py scripts/send_reel_for_review.py scripts/upload_reel_to_vps.sh scripts/tests/test_send_carousel_for_review.py
git commit -m "refactor(scripts): send 腳本只上傳素材 + 建 pending row，Discord 貼文交給 bot

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 12: 文件 — 更新 skill 與 README

**Files:**
- Modify: `.claude/skills/lorescape-manual-daily-story/SKILL.md`
- Modify: `.claude/skills/lorescape-wander-carousel/SKILL.md`
- Modify: `backend/README.md`

**Interfaces:**
- Produces: 文件反映新流程（本地上傳 → bot Discord 審核/排程/發布），移除 21:00/21:10/23:10 cron 的敘述。

- [ ] **Step 1: 更新 manual-daily-story SKILL**

Step 8b（carousel 送審）與 reel Step 11：把「react ✅ before 21:00/21:10 Asia/Taipei to publish」「VPS 21:00 publisher」等敘述改為：「本地 `send_carousel_for_review` / `send_reel_for_review` 只上傳素材並建立 pending row；發布 bot 會在 Discord 貼帶按鈕的審核訊息，你按 ✅核准 / 🕘排程 / 🚀立即發布 / ❌拒絕。」

- [ ] **Step 2: 更新 wander-carousel SKILL**

把送審後「等 21:00 publisher」敘述改為 bot 按鈕流程。

- [ ] **Step 3: 更新 backend/README.md**

移除 publisher 三個固定 cron 的說明，改述 `publisher_bot`：Discord 驅動的審核/排程/發布、`/republish` back-fill、`DAILY_STORY_PUBLISH_ENABLED=0` 暫停行為、需開啟 Gateway intents 與 application commands。

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/lorescape-manual-daily-story/SKILL.md .claude/skills/lorescape-wander-carousel/SKILL.md backend/README.md
git commit -m "docs: 更新每日故事 skill 與 README 為 Discord 發布 bot 流程

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## 分階段建議

- **階段一（Task 1–8）**：純資料 + 邏輯層，全單元測試覆蓋，不需 Discord 環境即可完成並驗證。
- **階段二（Task 9）**：Discord 接線，需 bot token 與審核頻道做手動驗證。
- **階段三（Task 10–12）**：部署切換與文件；建議先在 VPS 上以新 `publisher_bot` 跟舊 `publisher` 並存觀察一天，確認無誤再移除舊 cron（Task 10 的刪除可延後到觀察期後）。

## Self-Review Notes

- Spec §2/§3/§4/§5 分別對應 Task 11/1-2/9/7；§6 元件切分對應 Task 4/6/7/8/9；§7 部署對應 Task 9/10；§8 文件對應 Task 12；§9 測試散落各 task 的 TDD 步驟。
- 型別一致性：`publish_row` 回傳 `bool`（Task 4）被 `interactions.publish_now/republish`（Task 6）與 `scheduler.tick`（Task 7）取用一致；`list_scheduled_due(supabase, now_iso)`（Task 2）被 scheduler 以 `now.isoformat()` 呼叫一致；`stage_pending` 欄位（Task 2）與 migration 欄位（Task 1）一致。
- Placeholder 掃描：無 TBD/TODO；Task 9 的 discord.py 接線因 Gateway 無法單元測試，以結構隔離 + import 健全性檢查 + 手動驗證清單覆蓋（判斷邏輯已在 Task 4/6/7/8 純函式測過）。
