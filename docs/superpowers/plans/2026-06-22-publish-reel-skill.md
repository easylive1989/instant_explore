# Publish Reel Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用本機 IG token 把 `outputs/daily_video/<date>/final.mp4` 手動發布為 Instagram Reels，caption 取自 Supabase 當天 daily story。

**Architecture:** 新增 `instagram.publish_reel()` 封裝 IG Reels resumable upload 三步驟（建 container → 直傳 bytes 到 rupload.facebook.com → 輪詢 → media_publish），與既有圖片版 `publish()` 並存。一支薄 CLI `backend/scripts/publish_reel.py` 解析影片、組 caption（重用 `social/caption.py`）、呼叫 `publish_reel()`。最後包成 `.claude/skills/publish-reel/SKILL.md`。

**Tech Stack:** Python 3, `requests`, Supabase Python client, `python-dotenv`, pytest + `requests-mock` + `pytest-mock`。所有指令從 `backend/` 以 `uv run` 執行。

## Global Constraints

- Graph API 版本固定 `v21.0`（沿用 `instagram.py` 既有 `META_GRAPH_API`）。
- 憑證只從 `backend/.env` 既有變數讀取，**不新增任何金鑰**：`IG_USER_ID`、`META_PAGE_ACCESS_TOKEN`、`SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`。
- 不寫回 Supabase（手動發布與 server 狀態機獨立）。
- caption 語言固定 `zh-TW`。
- 程式碼風格：行長 ≤ 80 字元，公開函式加 `"""docstring"""`，keyword-only 參數（沿用 `instagram.py` 的 `*` 慣例）。
- 測試從 `backend/` 執行：`uv run pytest <path> -v`。腳本以 `from scripts.publish_reel import ...` 匯入（沿用 `test_manual_daily_story.py` 慣例）。

---

### Task 1: `instagram.publish_reel()` — IG Reels resumable upload

**Files:**
- Modify: `backend/src/lorescape_backend/social/instagram.py`
- Test: `backend/tests/test_instagram_client.py`

**Interfaces:**
- Consumes: 既有模組常數 `META_GRAPH_API`、`_REQUEST_TIMEOUT`，與既有私有函式 `_publish_container(*, ig_user_id, access_token, container_id) -> str`。
- Produces: `publish_reel(*, ig_user_id: str, access_token: str, video_path: str, caption: str) -> str`（回傳 IG post id）。

- [ ] **Step 1: Write the failing tests**

新增到 `backend/tests/test_instagram_client.py` 檔尾：

```python
def test_publish_reel_runs_create_upload_poll_publish(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"fake-bytes")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-1"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-1",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-container-1",
        json={"status_code": "FINISHED"},
    )
    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media_publish",
        json={"id": "reel-post-1"},
    )

    with patch("lorescape_backend.social.instagram.time.sleep"):
        post_id = publish_reel(
            ig_user_id="ig1",
            access_token="tok",
            video_path=str(video),
            caption="my reel caption",
        )

    assert post_id == "reel-post-1"

    create_req = requests_mock.request_history[0]
    assert create_req.qs["media_type"] == ["reels"]
    assert create_req.qs["upload_type"] == ["resumable"]
    assert create_req.qs["caption"] == ["my reel caption"]

    upload_req = requests_mock.request_history[1]
    assert upload_req.headers["Authorization"] == "OAuth tok"
    assert upload_req.headers["offset"] == "0"
    assert upload_req.headers["file_size"] == "10"
    assert upload_req.body == b"fake-bytes"

    publish_req = requests_mock.request_history[-1]
    assert publish_req.qs["creation_id"] == ["reel-container-1"]


def test_publish_reel_raises_when_container_errors(requests_mock, tmp_path):
    video = tmp_path / "final.mp4"
    video.write_bytes(b"x")

    requests_mock.post(
        "https://graph.facebook.com/v21.0/ig1/media",
        json={"id": "reel-container-2"},
    )
    requests_mock.post(
        "https://rupload.facebook.com/ig-api-upload/v21.0/reel-container-2",
        json={"success": True},
    )
    requests_mock.get(
        "https://graph.facebook.com/v21.0/reel-container-2",
        json={"status_code": "ERROR"},
    )

    with patch("lorescape_backend.social.instagram.time.sleep"):
        with pytest.raises(RuntimeError):
            publish_reel(
                ig_user_id="ig1",
                access_token="tok",
                video_path=str(video),
                caption="c",
            )
```

並把匯入行改成：

```python
from lorescape_backend.social.instagram import publish, publish_reel
```

> 註：`requests_mock` 把查詢字串小寫化，故 `media_type` 斷言為 `["reels"]`（送出的值仍是 `REELS`）。

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/test_instagram_client.py -v`
Expected: FAIL — `ImportError: cannot import name 'publish_reel'`。

- [ ] **Step 3: Implement `publish_reel` and helpers**

在 `backend/src/lorescape_backend/social/instagram.py`：

把頂部 import 區補上 `os`：

```python
import logging
import os
import time
```

新增常數（接在既有 `_CONTAINER_READY_DELAY_SECONDS = 5` 之後）：

```python
RUPLOAD_API = "https://rupload.facebook.com/ig-api-upload/v21.0"
_UPLOAD_TIMEOUT = 300
_REEL_POLL_INTERVAL_SECONDS = 5
_REEL_POLL_MAX_ATTEMPTS = 60
```

新增函式（放在既有 `_publish_container` 之後）：

```python
def publish_reel(
    *,
    ig_user_id: str,
    access_token: str,
    video_path: str,
    caption: str,
) -> str:
    """Create + resumable-upload + publish an IG Reel. Returns the IG post id.

    Uploads the local video bytes directly to Meta's resumable upload
    endpoint — no public URL or intermediate storage is needed.
    """
    container_id = _create_reel_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        caption=caption,
    )
    _upload_reel_bytes(
        container_id=container_id,
        access_token=access_token,
        video_path=video_path,
    )
    _wait_until_finished(container_id=container_id, access_token=access_token)
    return _publish_container(
        ig_user_id=ig_user_id,
        access_token=access_token,
        container_id=container_id,
    )


def _create_reel_container(
    *, ig_user_id: str, access_token: str, caption: str
) -> str:
    response = requests.post(
        f"{META_GRAPH_API}/{ig_user_id}/media",
        params={
            "media_type": "REELS",
            "upload_type": "resumable",
            "caption": caption,
            "access_token": access_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()["id"]


def _upload_reel_bytes(
    *, container_id: str, access_token: str, video_path: str
) -> None:
    file_size = os.path.getsize(video_path)
    with open(video_path, "rb") as video_file:
        response = requests.post(
            f"{RUPLOAD_API}/{container_id}",
            headers={
                "Authorization": f"OAuth {access_token}",
                "offset": "0",
                "file_size": str(file_size),
            },
            data=video_file,
            timeout=_UPLOAD_TIMEOUT,
        )
    response.raise_for_status()


def _wait_until_finished(*, container_id: str, access_token: str) -> None:
    for _ in range(_REEL_POLL_MAX_ATTEMPTS):
        response = requests.get(
            f"{META_GRAPH_API}/{container_id}",
            params={"fields": "status_code", "access_token": access_token},
            timeout=_REQUEST_TIMEOUT,
        )
        response.raise_for_status()
        status = response.json().get("status_code")
        if status == "FINISHED":
            return
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(
                f"Reel container {container_id} failed: {status}"
            )
        time.sleep(_REEL_POLL_INTERVAL_SECONDS)
    raise TimeoutError(
        f"Reel container {container_id} not ready after polling"
    )
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/test_instagram_client.py -v`
Expected: PASS（4 個測試：原 2 個 + 新 2 個）。

- [ ] **Step 5: Commit**

```bash
git add backend/src/lorescape_backend/social/instagram.py backend/tests/test_instagram_client.py
git commit -m "feat(social): add publish_reel for IG Reels resumable upload

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `publish_reel.py` CLI script

**Files:**
- Create: `backend/scripts/publish_reel.py`
- Test: `backend/tests/test_publish_reel_script.py`

**Interfaces:**
- Consumes: `instagram.publish_reel(...)`（Task 1）、`caption.StoryCopy` 與 `caption.build_full_caption(...)`（既有）、`Config.from_env()`、`supabase.create_client`。
- Produces:
  - `_resolve_video(date_str: str, override: str | None) -> Path`
  - `_load_story_row(supabase, date_str: str) -> dict | None`
  - `_read_narration(date_str: str) -> str | None`
  - `_build_caption(supabase, config, date_str: str, override: str | None) -> str`
  - `main(argv: list[str]) -> int`

- [ ] **Step 1: Write the failing tests**

Create `backend/tests/test_publish_reel_script.py`:

```python
"""Tests for the manual IG Reels publish script."""
from __future__ import annotations

from types import SimpleNamespace

import pytest

from scripts import publish_reel


def test_resolve_video_returns_final_mp4(tmp_path, monkeypatch):
    day_dir = tmp_path / "2026-06-22"
    day_dir.mkdir()
    (day_dir / "final.mp4").write_bytes(b"v")
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)

    result = publish_reel._resolve_video("2026-06-22", None)

    assert result == day_dir / "final.mp4"


def test_resolve_video_raises_when_missing(tmp_path, monkeypatch):
    (tmp_path / "2026-06-22").mkdir()
    monkeypatch.setattr(publish_reel, "DAILY_VIDEO_DIR", tmp_path)

    with pytest.raises(FileNotFoundError):
        publish_reel._resolve_video("2026-06-22", None)


def test_build_caption_prefers_override():
    result = publish_reel._build_caption(
        supabase=None, config=None, date_str="2026-06-22", override="hello"
    )
    assert result == "hello"


def test_build_caption_from_story_row(mocker):
    config = SimpleNamespace(
        brand_handle_ig="@love.lorescape", cta_text="Explore."
    )
    mocker.patch.object(
        publish_reel,
        "_load_story_row",
        return_value={
            "place_name": "Alhambra",
            "era": "13th century",
            "story": "A Moorish palace tale.",
            "hashtags": ["Spain"],
            "image_attribution": None,
        },
    )
    result = publish_reel._build_caption(
        supabase=object(), config=config, date_str="2026-06-22", override=None
    )
    assert "Alhambra" in result
    assert "#Spain" in result


def test_build_caption_falls_back_to_narration(mocker):
    mocker.patch.object(publish_reel, "_load_story_row", return_value=None)
    mocker.patch.object(
        publish_reel, "_read_narration", return_value="narration line"
    )
    result = publish_reel._build_caption(
        supabase=object(), config=object(), date_str="2026-06-22", override=None
    )
    assert result == "narration line"


def test_build_caption_raises_when_nothing_available(mocker):
    mocker.patch.object(publish_reel, "_load_story_row", return_value=None)
    mocker.patch.object(publish_reel, "_read_narration", return_value=None)
    with pytest.raises(ValueError):
        publish_reel._build_caption(
            supabase=object(),
            config=object(),
            date_str="2026-06-22",
            override=None,
        )
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && uv run pytest tests/test_publish_reel_script.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.publish_reel'`。

- [ ] **Step 3: Implement the script**

Create `backend/scripts/publish_reel.py`:

```python
"""Manually publish a daily video to Instagram Reels from your machine.

Reads the finished video at outputs/daily_video/<date>/final.mp4, builds the
caption from the Supabase daily story for that date (zh-TW), and publishes it
as an IG Reel using the local IG credentials in backend/.env. This is fully
local and independent of the server's scheduled publish job — nothing is
written back to Supabase.

Run from backend/:

    uv run python -m scripts.publish_reel 2026-06-22
    uv run python -m scripts.publish_reel 2026-06-22 --dry-run
    uv run python -m scripts.publish_reel 2026-06-22 --caption "自訂文案"
    uv run python -m scripts.publish_reel 2026-06-22 --video /path/to/clip.mp4
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.social import caption, instagram

REPO_ROOT = Path(__file__).resolve().parents[2]
DAILY_VIDEO_DIR = REPO_ROOT / "outputs" / "daily_video"
PUBLISH_LANGUAGE = "zh-TW"


def _resolve_video(date_str: str, override: str | None) -> Path:
    """Return the video file to publish for the given date."""
    if override:
        path = Path(override)
        if not path.is_file():
            raise FileNotFoundError(f"Video not found: {path}")
        return path
    day_dir = DAILY_VIDEO_DIR / date_str
    path = day_dir / "final.mp4"
    if not path.is_file():
        existing = (
            sorted(p.name for p in day_dir.iterdir())
            if day_dir.is_dir()
            else []
        )
        raise FileNotFoundError(
            f"final.mp4 not found in {day_dir}. Existing files: {existing}"
        )
    return path


def _load_story_row(supabase, date_str: str) -> dict | None:
    """Return the zh-TW daily_stories row for the date, or None."""
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", date_str)
        .eq("language", PUBLISH_LANGUAGE)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


def _read_narration(date_str: str) -> str | None:
    """Return the narration.txt text for the date, or None."""
    path = DAILY_VIDEO_DIR / date_str / "narration.txt"
    if path.is_file():
        return path.read_text(encoding="utf-8").strip()
    return None


def _build_caption(
    supabase, config, date_str: str, override: str | None
) -> str:
    """Build the IG caption: override → Supabase story → narration.txt."""
    if override:
        return override
    row = _load_story_row(supabase, date_str)
    if row is not None:
        story_copy = caption.StoryCopy(
            place_name=row["place_name"],
            era=row["era"],
            story=row["story"],
            hashtags=tuple(row.get("hashtags") or ()),
            image_attribution=row.get("image_attribution"),
        )
        return caption.build_full_caption(
            story=story_copy,
            brand_handle=config.brand_handle_ig,
            cta_text=config.cta_text,
        )
    narration = _read_narration(date_str)
    if narration:
        return narration
    raise ValueError(
        f"No daily_stories row for {date_str} and no narration.txt; "
        f"pass --caption to provide the text."
    )


def main(argv: list[str]) -> int:
    """CLI entrypoint."""
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("date", help="Publish date, YYYY-MM-DD")
    parser.add_argument("--caption", help="Override the caption text")
    parser.add_argument("--video", help="Override the video file path")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the video and caption without publishing",
    )
    args = parser.parse_args(argv)

    config = Config.from_env()
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )

    video = _resolve_video(args.date, args.video)
    ig_caption = _build_caption(supabase, config, args.date, args.caption)

    if args.dry_run:
        print(f"[dry-run] video:   {video}")
        print(f"[dry-run] caption:\n{ig_caption}")
        return 0

    if not config.instagram_enabled:
        print(
            "Instagram not configured: set IG_USER_ID and "
            "META_PAGE_ACCESS_TOKEN in backend/.env",
            file=sys.stderr,
        )
        return 1

    post_id = instagram.publish_reel(
        ig_user_id=config.ig_user_id,
        access_token=config.meta_page_access_token,
        video_path=str(video),
        caption=ig_caption,
    )
    print(f"Published reel: {post_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && uv run pytest tests/test_publish_reel_script.py -v`
Expected: PASS（6 個測試）。

- [ ] **Step 5: Run the full backend suite to confirm no regressions**

Run: `cd backend && uv run pytest -q`
Expected: 全部 PASS。

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/publish_reel.py backend/tests/test_publish_reel_script.py
git commit -m "feat(scripts): manual IG Reels publish script

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `publish-reel` skill packaging

**Files:**
- Create: `.claude/skills/publish-reel/SKILL.md`

**Interfaces:**
- Consumes: `backend/scripts/publish_reel.py`（Task 2）的 CLI 介面。
- Produces: 一個可被 Skill 工具觸發的 skill。

- [ ] **Step 1: Write `SKILL.md`**

Create `.claude/skills/publish-reel/SKILL.md`:

```markdown
---
name: publish-reel
description: Use when the user wants to manually publish a specific day's finished video from outputs/daily_video/<date>/ to Instagram Reels using the local IG token in backend/.env — e.g. "發布某天的影片到 IG reels", "把今天的影片發到 Reels", "publish reel for 2026-06-22". Local-only, does not touch the server's scheduled publish job.
---

# Publish a daily video to Instagram Reels (local)

手動把 `outputs/daily_video/<date>/final.mp4` 用本機 IG token 發布為 IG Reels。
完全在本機執行，不經 server 排程、不寫回 Supabase。

## 前置條件

- `backend/.env` 已填好 `IG_USER_ID`、`META_PAGE_ACCESS_TOKEN`、
  `SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`（取得方式見
  `docs/social_publisher_setup.md`）。
- 目標日期的 `outputs/daily_video/<date>/final.mp4` 已存在。

## 步驟

1. 跟使用者確認要發布的日期（如 `2026-06-22`）。
2. **先 dry-run** 檢查影片路徑與將送出的 caption：

   ```bash
   cd backend && uv run python -m scripts.publish_reel <date> --dry-run
   ```

   把 caption 念給使用者確認。caption 來源優先序：`--caption` 覆寫 →
   Supabase 當天 zh-TW daily story → 該天 `narration.txt`。

3. 使用者確認後，正式發布：

   ```bash
   cd backend && uv run python -m scripts.publish_reel <date>
   ```

   成功會印出 `Published reel: <ig_post_id>`。

4. 提醒使用者到 Instagram App 確認 Reel 已上架（Reels 處理需要幾秒到幾分鐘）。

## 常用旗標

- `--caption "自訂文案"`：手動覆寫文案。
- `--video /path/to/clip.mp4`：發布非預設檔案。
- `--dry-run`：只印影片與 caption，不實際發布。

## 疑難排解

- `Instagram not configured`：`backend/.env` 缺 `IG_USER_ID` 或
  `META_PAGE_ACCESS_TOKEN`。
- `final.mp4 not found`：確認該天資料夾與檔名，或用 `--video` 指定。
- `No daily_stories row ... and no narration.txt`：用 `--caption` 提供文案。
- 發布失敗會印出 Graph API 的錯誤訊息（多半是 token 過期或帳號未設為
  商業/創作者帳號）。
```

- [ ] **Step 2: Verify the skill file is well-formed**

Run: `head -5 .claude/skills/publish-reel/SKILL.md`
Expected: 看到 `---` frontmatter 與 `name: publish-reel`、`description:` 兩行。

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/publish-reel/SKILL.md
git commit -m "feat(skill): publish-reel for manual IG Reels publishing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Manual verification (after all tasks)

實際發布一次（需要有效 IG 憑證與當天 `final.mp4`）：

```bash
cd backend && uv run python -m scripts.publish_reel 2026-06-22 --dry-run   # 先看 caption
cd backend && uv run python -m scripts.publish_reel 2026-06-22             # 正式發布
```

到 Instagram App 確認 Reel 上架、caption 正確。
