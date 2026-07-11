# Social Publisher 拆分 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `social/` 與 `daily_story/` 從 backend 拆成平級的頂層專案 `publisher/`（lorescape-publisher），backend 只留服務 App 的程式。

**Architecture:** publisher 是獨立 Python 專案（自己的 pyproject / .env / Docker image / compose project / deploy workflow），與 backend 零 import 關係；刻意共用的 `story_prompt.py` / `genai.py` 複製兩份。`scripts/` 的 path dependency 從 backend 改指 publisher。

**Tech Stack:** Python 3.11、uv、discord.py、supabase-py、google-genai、Playwright、Jinja2、Docker Compose、GitHub Actions。

**Spec:** `docs/superpowers/specs/2026-07-11-social-publisher-split-design.md`

## Global Constraints

- Python 指令一律用 `uv run ...`；backend 測試在 `backend/` 下跑，publisher 測試在 `publisher/` 下跑。
- macOS BSD sed：in-place 一律 `sed -i ''`。
- 檔案搬移用 `git mv` 保留歷史。
- 每個 task 結尾 backend 與 publisher 的 pytest 都必須全綠才能 commit。
- Commit message 繁體中文、結尾加 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`。
- 文件（ADR、CLAUDE.md）以繁體中文撰寫。
- 不改任何 runtime 行為：bot 的排程邏輯、IG 發布流程、daily story CLI 的行為在拆分前後一致（僅 module 路徑與部署封裝改變）。

---

### Task 1: publisher 專案骨架

**Files:**
- Create: `publisher/pyproject.toml`
- Create: `publisher/.gitignore`
- Create: `publisher/src/lorescape_publisher/__init__.py`（空檔）
- Create: `publisher/tests/__init__.py`（空檔）
- Create: `publisher/scripts/__init__.py`（空檔）

**Interfaces:**
- Produces: 可 `uv sync` 的 `lorescape-publisher` 專案；後續 task 把程式搬進 `src/lorescape_publisher/`。

- [ ] **Step 1: 建立 pyproject.toml**

```toml
[project]
name = "lorescape-publisher"
version = "0.1.0"
description = "Lorescape social publisher: daily-story pipeline + Discord review bot + IG publishing"
requires-python = ">=3.11"
dependencies = [
    "supabase>=2.10,<3",
    "discord.py>=2.4,<3",
    "requests>=2.32,<3",
    "google-genai>=0.8,<2",
    "python-dotenv>=1,<2",
    "jinja2>=3.1,<4",
    "playwright>=1.45,<2",
]

[project.optional-dependencies]
dev = [
    "pytest>=8,<9",
    "pytest-mock>=3.14,<4",
    "requests-mock>=1.12,<2",
    "pillow>=10,<12",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
pythonpath = ["src"]
testpaths = ["tests"]
```

- [ ] **Step 2: 建立 .gitignore 與空套件檔**

`publisher/.gitignore`：

```
.env
service-account.json
__pycache__/
.venv/
```

```bash
mkdir -p publisher/src/lorescape_publisher publisher/tests publisher/scripts
touch publisher/src/lorescape_publisher/__init__.py publisher/tests/__init__.py publisher/scripts/__init__.py
```

- [ ] **Step 3: 驗證 uv sync**

Run: `cd publisher && uv sync --extra dev`
Expected: 成功建立 `.venv` 並 lock 依賴（產出 `uv.lock`）。

- [ ] **Step 4: Commit**

```bash
git add publisher/
git commit -m "chore(publisher): 建立 lorescape-publisher 專案骨架"
```

---

### Task 2: publisher 自有基礎 — genai、story_prompt、config、.env.example

**Files:**
- Create: `publisher/src/lorescape_publisher/genai.py`（複製自 `backend/src/lorescape_backend/shared/genai.py`）
- Create: `publisher/src/lorescape_publisher/story_prompt.py`（複製自 `backend/src/lorescape_backend/shared/story_prompt.py`，內嵌 SourceExtract / SourceBundle）
- Create: `publisher/src/lorescape_publisher/config.py`
- Create: `publisher/tests/conftest.py`
- Create: `publisher/tests/test_config.py`
- Create: `publisher/.env.example`

**Interfaces:**
- Consumes: Task 1 的專案骨架。
- Produces: `lorescape_publisher.config.Config`（欄位見 Step 3；properties：`genai_settings`、`review_enabled`、`instagram_enabled`）、`lorescape_publisher.genai`（`BACKEND_AI_STUDIO`、`BACKEND_VERTEX`、`GenaiSettings`、`build_client`）、`lorescape_publisher.story_prompt`（`LANGUAGE_NAMES`、`StoryHook`、`SourceExtract`、`SourceBundle`、`build_story_system_instruction`、`build_story_user_prompt`）、pytest fixture `fake_config`。

- [ ] **Step 1: 複製 genai.py**

```bash
cp backend/src/lorescape_backend/shared/genai.py publisher/src/lorescape_publisher/genai.py
```

檔案頂部 docstring 補一行來源註記（手動編輯）：

```python
"""(原文 docstring 保留)

Copied from backend/src/lorescape_backend/shared/genai.py on 2026-07-11.
Deliberately duplicated: backend and publisher are fully decoupled (spec
2026-07-11-social-publisher-split-design.md, 決策 3).
"""
```

- [ ] **Step 2: 複製 story_prompt.py 並內嵌 source models**

```bash
cp backend/src/lorescape_backend/shared/story_prompt.py publisher/src/lorescape_publisher/story_prompt.py
```

編輯 `publisher/src/lorescape_publisher/story_prompt.py`：

1. docstring 同樣補上 `Copied from ... on 2026-07-11. Deliberately duplicated ...` 註記。
2. 刪掉這段 TYPE_CHECKING import（backend 專屬）：

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from lorescape_backend.sources.models import SourceBundle
```

3. 在原 import 區之後，`LANGUAGE_NAMES` 之前，貼上 `backend/src/lorescape_backend/sources/models.py` 裡 `SourceExtract` 與 `SourceBundle` 兩個 dataclass 的完整定義（逐字複製，含各自的 docstring 與欄位；該檔僅 32 行、兩個 dataclass）。
4. 全檔把字串型別註解 `"SourceBundle"` 保持原樣（本地類別已可解析）。

- [ ] **Step 3: 寫 config.py**

```python
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

    # Daily story pipeline flags. DAILY_STORY_ENABLED is the legacy master
    # switch; the per-job flags default to it but can be overridden
    # independently. Env: DAILY_STORY_ENABLED / DAILY_STORY_GENERATE_ENABLED /
    # DAILY_STORY_PUBLISH_ENABLED = 0/false/off to pause.
    daily_story_enabled: bool = True
    daily_story_generate_enabled: bool = True
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
            daily_story_generate_enabled=is_on(
                "DAILY_STORY_GENERATE_ENABLED", master_default
            ),
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
```

- [ ] **Step 4: 寫 tests/conftest.py（fake_config fixture）**

```python
"""Shared pytest fixtures."""
from __future__ import annotations

import pytest

from lorescape_publisher.config import Config


@pytest.fixture
def fake_config() -> Config:
    """A Config with dummy non-empty values for testing."""
    return Config(
        supabase_url="https://test.supabase.co",
        supabase_service_role_key="test_service_role_key",
        gemini_api_key="test_gemini_key",
        discord_webhook_url="https://discord.com/api/webhooks/test",
        discord_bot_token="test_bot_token",
        discord_review_channel_id="111222333444555666",
        discord_approver_ids=("999888777666555444",),
        ig_user_id="ig_user_1",
        meta_page_access_token="meta_page_token",
        brand_handle_ig="@love.lorescape",
        cta_text="Explore more places with Lorescape.",
    )
```

- [ ] **Step 5: 寫 tests/test_config.py（先寫，此時應該會過——本 task 是新程式，不是搬移，仍按「先測後實作」的精神：如果你按順序先寫了 config.py，至少先跑測試確認紅→綠的關鍵斷言）**

```python
"""Tests for publisher Config."""
from __future__ import annotations

import pytest

from lorescape_publisher.config import Config

_REQUIRED = {
    "SUPABASE_URL": "https://x.supabase.co",
    "SUPABASE_SERVICE_ROLE_KEY": "srk",
    "GEMINI_API_KEY": "gk",
}


def _set_required(monkeypatch):
    for key, value in _REQUIRED.items():
        monkeypatch.setenv(key, value)


def test_from_env_loads_required(monkeypatch):
    _set_required(monkeypatch)
    config = Config.from_env()
    assert config.supabase_url == "https://x.supabase.co"
    assert config.supabase_service_role_key == "srk"
    assert config.gemini_api_key == "gk"


def test_from_env_raises_when_required_missing(monkeypatch):
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "srk")
    monkeypatch.setenv("GEMINI_API_KEY", "gk")
    with pytest.raises(RuntimeError, match="SUPABASE_URL"):
        Config.from_env()


def test_from_env_parses_approver_ids_as_tuple(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111, 222 ,333")
    config = Config.from_env()
    assert config.discord_approver_ids == ("111", "222", "333")


def test_review_enabled_requires_all_three(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DISCORD_BOT_TOKEN", "t")
    monkeypatch.setenv("DISCORD_REVIEW_CHANNEL_ID", "c")
    monkeypatch.delenv("DISCORD_APPROVER_IDS", raising=False)
    assert Config.from_env().review_enabled is False
    monkeypatch.setenv("DISCORD_APPROVER_IDS", "111")
    assert Config.from_env().review_enabled is True


def test_instagram_enabled_flag(monkeypatch):
    _set_required(monkeypatch)
    assert Config.from_env().instagram_enabled is False
    monkeypatch.setenv("IG_USER_ID", "ig1")
    monkeypatch.setenv("META_PAGE_ACCESS_TOKEN", "tok")
    assert Config.from_env().instagram_enabled is True


def test_daily_story_defaults_on_and_kill_switch(monkeypatch):
    _set_required(monkeypatch)
    assert Config.from_env().daily_story_enabled is True
    monkeypatch.setenv("DAILY_STORY_ENABLED", "0")
    config = Config.from_env()
    assert config.daily_story_enabled is False
    assert config.daily_story_generate_enabled is False
    assert config.daily_story_publish_enabled is False


def test_per_job_flags_override_master_switch(monkeypatch):
    _set_required(monkeypatch)
    monkeypatch.setenv("DAILY_STORY_ENABLED", "0")
    monkeypatch.setenv("DAILY_STORY_PUBLISH_ENABLED", "1")
    config = Config.from_env()
    assert config.daily_story_generate_enabled is False
    assert config.daily_story_publish_enabled is True


def test_gemini_backend_vertex_requires_project_not_key(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://x.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "srk")
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setenv("GEMINI_BACKEND", "vertex")
    monkeypatch.delenv("GOOGLE_CLOUD_PROJECT", raising=False)
    with pytest.raises(RuntimeError, match="GOOGLE_CLOUD_PROJECT"):
        Config.from_env()
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", "proj-1")
    config = Config.from_env()
    assert config.gemini_backend == "vertex"
    assert config.gemini_api_key is None
```

注意：測試環境可能殘留使用者 shell 的環境變數；如有 flaky，比照 backend `tests/test_config.py` 開頭的清理方式（先看該檔怎麼隔離 env，沿用同一手法）。

- [ ] **Step 6: 建立 .env.example**

```bash
# Supabase (use the SERVICE_ROLE key — bypasses RLS for writes)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# ── Gemini backend（daily story 產生用）──────────────────────────────────────
#   ai-studio (default) — authenticate with GEMINI_API_KEY below.
#   vertex              — route through a GCP project; auth via GCP ADC
#                         (GOOGLE_APPLICATION_CREDENTIALS=/app/service-account.json in Docker).
# GEMINI_BACKEND=ai-studio
GEMINI_API_KEY=your_gemini_api_key
# GOOGLE_CLOUD_PROJECT=instant-explore-7b442
# GOOGLE_CLOUD_LOCATION=us-central1

# Daily story pipeline flags（目前 generate 停用、走手動流程）
# DAILY_STORY_ENABLED=1
# DAILY_STORY_GENERATE_ENABLED=0
# DAILY_STORY_PUBLISH_ENABLED=1

# Discord webhook for failure alerts (optional but recommended)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# ── Discord review bot（缺任一項 bot 會 SystemExit）───────────────────────────
DISCORD_BOT_TOKEN=
DISCORD_REVIEW_CHANNEL_ID=
# Comma-separated Discord user IDs allowed to approve/reject
DISCORD_APPROVER_IDS=

# ── Instagram Business via Meta Graph API ─────────────────────────────────────
# Obtain via: scripts/meta_token_helper.py --platform instagram
IG_USER_ID=
META_PAGE_ACCESS_TOKEN=

# ── Branding ──────────────────────────────────────────────────────────────────
BRAND_HANDLE_IG=@love.lorescape

# DAILY_VIDEO_DIR is set by docker-compose (container path of the media volume);
# only set it here for local runs.
# DAILY_VIDEO_DIR=/media/daily_video
```

- [ ] **Step 7: 跑測試**

Run: `cd publisher && uv run pytest -v`
Expected: `test_config.py` 全 PASS。

- [ ] **Step 8: Commit**

```bash
git add publisher/
git commit -m "feat(publisher): 自有 Config、genai、story_prompt（與 backend 解耦複製）"
```

---

### Task 3: backend 先解除對 daily_story 的依賴（api cron 移除 + sources 自帶 fetch_intro_extract）

**Files:**
- Modify: `backend/src/lorescape_backend/api.py`
- Modify: `backend/tests/test_api.py`
- Modify: `backend/src/lorescape_backend/sources/wikipedia.py`
- Modify: `backend/src/lorescape_backend/sources/pipeline.py:22`
- Modify: `backend/tests/sources/test_wikipedia.py`

**Interfaces:**
- Consumes: 現有 `lorescape_backend.api._register_jobs`、`sources/pipeline.fetch_intro_extract_legacy`。
- Produces: `lorescape_backend.sources.wikipedia.fetch_intro_extract(title: str) -> str`；api 只註冊 reconcile job。Task 4 之後 backend 不再有任何 `daily_story` import。

- [ ] **Step 1: 在 tests/sources/test_wikipedia.py 加失敗測試**

在檔尾加（import 沿用該檔既有的 wikipedia module import 方式）：

```python
def test_fetch_intro_extract_returns_extract(requests_mock):
    requests_mock.get(
        "https://en.wikipedia.org/w/api.php",
        json={"query": {"pages": {"123": {"extract": "Intro text."}}}},
    )
    assert wikipedia.fetch_intro_extract("Some Title") == "Intro text."


def test_fetch_intro_extract_empty_when_missing(requests_mock):
    requests_mock.get(
        "https://en.wikipedia.org/w/api.php",
        json={"query": {"pages": {"-1": {"missing": ""}}}},
    )
    assert wikipedia.fetch_intro_extract("No Such Page") == ""
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd backend && uv run pytest tests/sources/test_wikipedia.py -v`
Expected: 新增兩個測試 FAIL（`AttributeError: ... has no attribute 'fetch_intro_extract'`）。

- [ ] **Step 3: sources/wikipedia.py 加入 fetch_intro_extract**

從 `backend/src/lorescape_backend/daily_story/wikipedia.py:210-243` 逐字複製 `fetch_intro_extract` 函式到 `sources/wikipedia.py` 檔尾，並在檔內補上它用到的常數（`daily_story/wikipedia.py:20` 的 `_API_URL = "https://en.wikipedia.org/w/api.php"`；若 `sources/wikipedia.py` 尚無同值常數，新增 `_EN_WIKI_API_URL` 並把函式內的 `_API_URL` 改成它）。`USER_AGENT` 用 `sources/wikipedia.py` 既有的常數。函式 docstring 補一行：`Copied from daily_story/wikipedia.py — legacy wikipedia_title App path (see sources/pipeline.py).`

- [ ] **Step 4: pipeline.py 改 import**

`backend/src/lorescape_backend/sources/pipeline.py:22`：

```python
# 舊
from lorescape_backend.daily_story.wikipedia import fetch_intro_extract as fetch_intro_extract_legacy  # noqa: F401  (re-exported for monkeypatch in tests)
# 新
from lorescape_backend.sources.wikipedia import fetch_intro_extract as fetch_intro_extract_legacy  # noqa: F401  (re-exported for monkeypatch in tests)
```

- [ ] **Step 5: 跑 sources 測試**

Run: `cd backend && uv run pytest tests/sources -v`
Expected: 全 PASS（`test_pipeline.py` 的 monkeypatch 沿用 `fetch_intro_extract_legacy` 名稱，不需要改）。

- [ ] **Step 6: api.py 移除 generate cron**

`backend/src/lorescape_backend/api.py`：

1. 刪除 `from datetime import date` 與 `from lorescape_backend.daily_story.job import run_generate_and_review`。
2. 刪除常數 `GENERATE_JOB_ID`、`GENERATE_HOUR`。
3. `_register_jobs` 改為：

```python
def _register_jobs(scheduler: BackgroundScheduler, config: Config) -> None:
    """Register the subscription reconcile job on the scheduler.

    Daily-story generation/publishing lives in the standalone publisher
    project (publisher/, `python -m lorescape_publisher.daily_story` /
    `python -m lorescape_publisher.bot`).
    """

    def _reconcile() -> None:
        run_reconcile_job(config)

    if config.revenuecat_reconcile_enabled:
        scheduler.add_job(
            _reconcile,
            trigger=CronTrigger(hour=RECONCILE_HOUR, minute=0),
            id=RECONCILE_JOB_ID,
            replace_existing=True,
        )
```

4. 模組 docstring 中提到 `python -m lorescape_backend.daily_story` 與 `lorescape_backend.social.publisher_bot` 的行，改指到 publisher 專案（`python -m lorescape_publisher.daily_story`、`lorescape_publisher.bot`）。

- [ ] **Step 7: 改寫 test_api.py**

整檔改為：

```python
"""Tests for the FastAPI app + in-container scheduler wiring.

The daily-story pipeline and Instagram publishing live in the standalone
publisher project (lorescape_publisher); the api scheduler only carries the
subscription reconcile job.
"""
from __future__ import annotations

import dataclasses
from unittest.mock import MagicMock

from apscheduler.triggers.cron import CronTrigger

from lorescape_backend.api import (
    RECONCILE_HOUR,
    RECONCILE_JOB_ID,
    _register_jobs,
    health,
)


def test_health_returns_ok():
    assert health() == {"status": "ok"}


def test_register_jobs_schedules_only_reconcile(fake_config):
    # fake_config carries a REVENUECAT_API_KEY, so reconcile is scheduled.
    scheduler = MagicMock()
    _register_jobs(scheduler, fake_config)

    calls_by_id = {
        call.kwargs["id"]: call for call in scheduler.add_job.call_args_list
    }
    assert set(calls_by_id) == {RECONCILE_JOB_ID}
    trigger = calls_by_id[RECONCILE_JOB_ID].kwargs["trigger"]
    assert isinstance(trigger, CronTrigger)
    fields = {field.name: str(field) for field in trigger.fields}
    assert fields["hour"] == str(RECONCILE_HOUR)
    assert fields["minute"] == "0"
    assert calls_by_id[RECONCILE_JOB_ID].kwargs["replace_existing"] is True


def test_register_jobs_skips_reconcile_when_revenuecat_disabled(fake_config):
    config = dataclasses.replace(fake_config, revenuecat_api_key=None)
    scheduler = MagicMock()
    _register_jobs(scheduler, config)

    assert scheduler.add_job.call_args_list == []
```

- [ ] **Step 8: 跑 backend 全測試**

Run: `cd backend && uv run pytest -v`
Expected: 全 PASS（daily_story / social 測試此時還在 backend、照常跑）。

- [ ] **Step 9: Commit**

```bash
git add backend/src/lorescape_backend/api.py backend/tests/test_api.py \
        backend/src/lorescape_backend/sources/wikipedia.py \
        backend/src/lorescape_backend/sources/pipeline.py \
        backend/tests/sources/test_wikipedia.py
git commit -m "refactor(backend): api 移除 daily_story cron，sources 自帶 fetch_intro_extract"
```

---

### Task 4: 搬移 social + daily_story 到 publisher（含測試與工具腳本）

**Files:**
- Delete: `backend/src/lorescape_backend/social/publisher.py`、`backend/tests/test_publisher.py`、`backend/tests/test_publisher_prerendered.py`（legacy reaction-check CLI，已被 bot 取代）
- Move: `backend/src/lorescape_backend/daily_story/` → `publisher/src/lorescape_publisher/daily_story/`
- Move: `backend/src/lorescape_backend/social/publisher_bot.py` → `publisher/src/lorescape_publisher/bot.py`
- Move: `backend/src/lorescape_backend/social/bot/` → `publisher/src/lorescape_publisher/bot_flows/`
- Move: `backend/src/lorescape_backend/social/card/`、`wander/` → `publisher/src/lorescape_publisher/card/`、`wander/`（含 template、fonts 靜態資產）
- Move: `backend/src/lorescape_backend/social/{executor,instagram,post_log,caption,card_storage,reel_cover,reel_publisher}.py` → `publisher/src/lorescape_publisher/` 同名
- Delete: `backend/src/lorescape_backend/social/__init__.py`（social 目錄清空後移除）
- Delete: `backend/src/lorescape_backend/shared/story_prompt.py`?——**不刪**，narration 還在用；只刪 social/ 與 daily_story/
- Move: backend/tests 的 `_fakes.py`、`test_fakes.py`、`test_bot_interactions.py`、`test_bot_review_poster.py`、`test_bot_scheduler.py`、`test_caption.py`、`test_card_content.py`、`test_card_fit.py`、`test_card_mapper.py`、`test_card_renderer.py`、`test_card_storage.py`、`test_card_template.py`、`test_discord_notify.py`、`test_discord_review.py`、`test_executor.py`、`test_gemini_client.py`、`test_instagram_client.py`、`test_job.py`、`test_place_picker.py`、`test_post_log.py`、`test_prompts.py`、`test_reel_cover.py`、`test_reel_publisher.py`、`test_story_writer.py`、`test_wander_content.py`、`test_wander_renderer.py`、`test_wander_template.py`、`test_wikipedia.py`、`test_backfill_card_fields.py` → `publisher/tests/`
- Move: `backend/scripts/{backfill_card_fields,diagnose_daily_story,download_card_fonts}.py` → `publisher/scripts/`

**Interfaces:**
- Consumes: Task 2 的 `lorescape_publisher.config.Config`、`genai`、`story_prompt`（含 `SourceBundle`、`SourceExtract`）。
- Produces: `python -m lorescape_publisher.bot`（Gateway bot 進入點）、`python -m lorescape_publisher.daily_story`（手動產生 CLI）。模組面：`lorescape_publisher.{executor,instagram,post_log,caption,card_storage,reel_cover,reel_publisher}`、`lorescape_publisher.bot_flows.{scheduler,review_poster,interactions,views}`、`lorescape_publisher.card`、`lorescape_publisher.wander`、`lorescape_publisher.daily_story.*` —— Task 8 scripts 依這些名稱 import。

- [ ] **Step 1: 刪 legacy publisher CLI 與其測試**

```bash
git rm backend/src/lorescape_backend/social/publisher.py \
       backend/tests/test_publisher.py backend/tests/test_publisher_prerendered.py
```

- [ ] **Step 2: git mv 程式與測試**

```bash
# daily_story 整包
git mv backend/src/lorescape_backend/daily_story publisher/src/lorescape_publisher/daily_story

# social：bot 進入點改名 + bot/ 改名 bot_flows/ + 其餘攤平
git mv backend/src/lorescape_backend/social/publisher_bot.py publisher/src/lorescape_publisher/bot.py
git mv backend/src/lorescape_backend/social/bot publisher/src/lorescape_publisher/bot_flows
git mv backend/src/lorescape_backend/social/card publisher/src/lorescape_publisher/card
git mv backend/src/lorescape_backend/social/wander publisher/src/lorescape_publisher/wander
for m in executor instagram post_log caption card_storage reel_cover reel_publisher; do
  git mv backend/src/lorescape_backend/social/$m.py publisher/src/lorescape_publisher/$m.py
done
git rm backend/src/lorescape_backend/social/__init__.py
rm -rf backend/src/lorescape_backend/social  # 清掉殘留 __pycache__

# 測試
for t in _fakes test_fakes test_bot_interactions test_bot_review_poster \
         test_bot_scheduler test_caption test_card_content test_card_fit \
         test_card_mapper test_card_renderer test_card_storage \
         test_card_template test_discord_notify test_discord_review \
         test_executor test_gemini_client test_instagram_client test_job \
         test_place_picker test_post_log test_prompts test_reel_cover \
         test_reel_publisher test_story_writer test_wander_content \
         test_wander_renderer test_wander_template test_wikipedia \
         test_backfill_card_fields; do
  git mv backend/tests/$t.py publisher/tests/$t.py
done

# 工具腳本
for s in backfill_card_fields diagnose_daily_story download_card_fonts; do
  git mv backend/scripts/$s.py publisher/scripts/$s.py
done
```

- [ ] **Step 3: 批次改寫 import 路徑（順序敏感：特定路徑先換）**

```bash
LC_ALL=C find publisher/src publisher/tests publisher/scripts -name "*.py" -exec sed -i '' \
  -e 's/lorescape_backend\.social\.publisher_bot/lorescape_publisher.bot/g' \
  -e 's/lorescape_backend\.social\.bot/lorescape_publisher.bot_flows/g' \
  -e 's/lorescape_backend\.social\.card/lorescape_publisher.card/g' \
  -e 's/lorescape_backend\.social\.wander/lorescape_publisher.wander/g' \
  -e 's/lorescape_backend\.social/lorescape_publisher/g' \
  -e 's/lorescape_backend\.daily_story/lorescape_publisher.daily_story/g' \
  -e 's/lorescape_backend\.shared\.genai/lorescape_publisher.genai/g' \
  -e 's/lorescape_backend\.shared\.story_prompt/lorescape_publisher.story_prompt/g' \
  -e 's/lorescape_backend\.sources\.models/lorescape_publisher.story_prompt/g' \
  -e 's/lorescape_backend\.config/lorescape_publisher.config/g' \
  {} +
```

改寫後驗證沒有殘留：

```bash
grep -rn "lorescape_backend" publisher/ --include="*.py" | grep -v uv.lock
```

Expected: 無輸出（若有殘留——例如註解裡的路徑——逐一手動修正指向 publisher 的對應位置）。

- [ ] **Step 4: 手動修正已知的殘留點**

1. `publisher/src/lorescape_publisher/daily_story/__main__.py` docstring：sed 後會出現 `python -m lorescape_publisher.publisher`（原指 legacy CLI，已刪），改成 `python -m lorescape_publisher.bot`（審核 / 發布現在都在 bot）。
2. `publisher/src/lorescape_publisher/bot.py` 的 CLI docstring（`main()` 上方）：`python -m lorescape_backend.social.publisher_bot` 應已被 sed 換成 `python -m lorescape_publisher.bot`，確認無誤。
3. `publisher/src/lorescape_publisher/daily_story/prompts.py`：`from lorescape_publisher.story_prompt import SourceBundle, SourceExtract`（sed 產物）——確認 Task 2 的 story_prompt.py 有這兩個類別。

- [ ] **Step 5: 跑 publisher 測試**

Run: `cd publisher && uv run pytest -v`
Expected: 全 PASS。若 card renderer 測試因缺瀏覽器失敗：`uv run playwright install chromium` 後重跑。

- [ ] **Step 6: 跑 backend 測試 + 驗證 backend 無殘留 import**

```bash
cd backend && uv run pytest -v
grep -rn "daily_story\|\.social" src/lorescape_backend --include="*.py" | grep -v __pycache__ | grep "import"
```

Expected: pytest 全 PASS；grep 無輸出。

- [ ] **Step 7: Commit**

```bash
git add -A backend/src backend/tests backend/scripts publisher/
git commit -m "refactor: social 與 daily_story 搬移至 publisher 專案，刪除 legacy publisher CLI"
```

---

### Task 5: backend 瘦身（Config、依賴、Dockerfile、.env.example）

**Files:**
- Modify: `backend/src/lorescape_backend/config.py`
- Modify: `backend/tests/conftest.py`
- Modify: `backend/tests/test_config.py`
- Modify: `backend/pyproject.toml`
- Modify: `backend/Dockerfile`
- Modify: `backend/.env.example`

**Interfaces:**
- Consumes: Task 4 完成後的 backend（已無 social / daily_story 程式）。
- Produces: 精簡的 `lorescape_backend.config.Config`（欄位：`supabase_url`、`supabase_service_role_key`、`gemini_api_key`、`gemini_backend`、`gcp_project`、`gcp_location`、`narration_web_search_enabled`、`revenuecat_webhook_auth_token`、`revenuecat_api_key`；properties：`genai_settings`、`revenuecat_webhook_enabled`、`revenuecat_reconcile_enabled`）。

- [ ] **Step 1: 先改 test_config.py（紅燈）**

刪除以下測試函式（已隨 Config 欄位遷往 publisher/tests/test_config.py）：
`test_from_env_parses_approver_ids_as_tuple`、`test_review_enabled_requires_all_three`、`test_instagram_enabled_flag`、`test_daily_story_defaults_on_and_kill_switch`、`test_per_job_flags_fall_back_to_master_switch`、`test_per_job_flags_override_master_switch`。

保留並按需修剪：`test_from_env_loads_all_required`、`test_from_env_optionals_default_to_none_or_empty`（拿掉 discord bot / IG / brand 斷言，保留 revenuecat / webhook url→改為僅 revenuecat）、`test_revenuecat_flags_enabled_when_set`、`test_from_env_raises_when_required_missing`、`test_narration_web_search_defaults_on_and_kill_switch`、`test_gemini_backend_*` 四個。

- [ ] **Step 2: 跑測試確認紅燈方向正確**

Run: `cd backend && uv run pytest tests/test_config.py -v`
Expected: 修剪後的既有測試此時仍 PASS（Config 還沒改，多餘欄位不影響）；這一步主要確認沒改壞留下來的測試。

- [ ] **Step 3: 精簡 config.py**

從 `Config` dataclass 與 `from_env` 刪除：`discord_webhook_url`、`discord_bot_token`、`discord_review_channel_id`、`discord_approver_ids`、`ig_user_id`、`meta_page_access_token`、`brand_handle_ig`、`cta_text`、`daily_story_enabled`、`daily_story_generate_enabled`、`daily_story_publish_enabled`、`daily_video_dir`，以及 `_DEFAULT_CTA_TEXT` 常數、`approver_raw` 解析、daily_story flag 解析、properties `review_enabled` 與 `instagram_enabled`。保留 supabase / gemini / narration / revenuecat 相關全部。

- [ ] **Step 4: 精簡 conftest.py 的 fake_config**

```python
@pytest.fixture
def fake_config() -> Config:
    """A Config with dummy non-empty values for testing."""
    return Config(
        supabase_url="https://test.supabase.co",
        supabase_service_role_key="test_service_role_key",
        gemini_api_key="test_gemini_key",
        revenuecat_webhook_auth_token="test_webhook_token",
        revenuecat_api_key="test_rc_api_key",
    )
```

- [ ] **Step 5: 跑 backend 全測試**

Run: `cd backend && uv run pytest -v`
Expected: 全 PASS（narration / subscriptions / sources / shared / api / auth / config）。

- [ ] **Step 6: 精簡 pyproject.toml 依賴**

先驗證再刪：

```bash
cd backend
grep -rn "discord\|playwright\|jinja2\|googleapiclient\|google.analytics\|google_auth\|google.oauth2\|PIL\|pillow" src tests --include="*.py" | grep -v __pycache__
```

Expected: 無輸出。然後從 `dependencies` 刪除：`playwright`、`jinja2`、`discord.py`、`google-api-python-client`、`google-auth`、`google-analytics-data`；從 dev extras 刪除 `pillow`。

Run: `uv sync --extra dev && uv run pytest -q`
Expected: sync 成功、測試全 PASS。

- [ ] **Step 7: 精簡 Dockerfile**

1. `apt-get install` 行移除 `ffmpeg`（保留 `tzdata`，APScheduler 需要），並更新上方註解（刪掉 publisher bot / ffmpeg 相關語句）。
2. 刪除 `RUN playwright install --with-deps chromium` 區塊與其註解。
3. 檔尾 CMD 註解「The cron job is invoked separately」改為指出 daily story 已移至 publisher 專案。

- [ ] **Step 8: 精簡 .env.example**

刪除區塊：Discord review bot（DISCORD_BOT_TOKEN / DISCORD_REVIEW_CHANNEL_ID / DISCORD_APPROVER_IDS）、Instagram（IG_USER_ID / META_PAGE_ACCESS_TOKEN）、Branding（BRAND_HANDLE_IG）、DISCORD_WEBHOOK_URL、Daily story pipeline 段。檔尾補一行註解：`# Social publishing 與 daily story 的環境變數在 publisher/.env — 見 publisher/.env.example。`

- [ ] **Step 9: Commit**

```bash
git add backend/
git commit -m "refactor(backend): 移除 social 相關 Config 欄位與依賴，Dockerfile 瘦身"
```

---

### Task 6: publisher Docker 化；backend compose 移除 publisher service

**Files:**
- Create: `publisher/Dockerfile`
- Create: `publisher/docker-compose.yml`
- Modify: `backend/docker-compose.yml`（刪除 `publisher` service 段，即 `docker-compose.yml:26-43`）

**Interfaces:**
- Consumes: Task 4 的 `python -m lorescape_publisher.bot` 進入點。
- Produces: `lorescape-publisher:latest` image 與獨立 compose project；Task 7 的 workflow 依 `cd /opt/lorescape/publisher && docker compose up -d --build` 部署。

- [ ] **Step 1: 寫 publisher/Dockerfile**

```dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Taipei

WORKDIR /app

# tzdata: bot 的 zoneinfo.ZoneInfo("Asia/Taipei")（排程 modal 的時間解析）
# 需要 /usr/share/zoneinfo，slim base 沒帶。ffmpeg: bot 產 720p reel 預覽。
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata ffmpeg && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip && \
    pip install -e .

# Playwright Chromium + 系統依賴（IG card / reel 封面渲染）。
RUN playwright install --with-deps chromium

# Discord Gateway 常駐 bot：審核訊息、按鈕互動、排程發布。
CMD ["python", "-m", "lorescape_publisher.bot"]
```

- [ ] **Step 2: 寫 publisher/docker-compose.yml**

```yaml
services:
  publisher:
    build: .
    image: lorescape-publisher:latest
    container_name: lorescape-publisher
    restart: unless-stopped
    env_file: .env
    environment:
      # Container path of the volume below; the reel flow reads
      # <DAILY_VIDEO_DIR>/<date>/final.mp4 + narration.txt, rsynced from the
      # operator's machine by scripts/upload_reel_to_vps.sh.
      DAILY_VIDEO_DIR: /media/daily_video
    volumes:
      - /opt/lorescape-media/daily_video:/media/daily_video:ro
      # Vertex AI service-account key（僅 GEMINI_BACKEND=vertex 時需要；
      # .env 的 GOOGLE_APPLICATION_CREDENTIALS 指向 CONTAINER 路徑）。
      - ./service-account.json:/app/service-account.json:ro
```

- [ ] **Step 3: backend/docker-compose.yml 刪除 publisher service**

刪除 `# Social publisher: ...` 註解起至 `depends_on:\n      - api` 止的整段（原 26-43 行），只留 `api` service。

- [ ] **Step 4: 語法驗證**

Run: `cd publisher && docker compose config -q && cd ../backend && docker compose config -q`
Expected: 兩者皆無錯誤輸出（警告 `service-account.json` 不存在屬正常——compose config 不檢查 volume 來源）。若本機沒有 docker，改用 `python -c "import yaml,sys;yaml.safe_load(open('docker-compose.yml'))"` 驗證兩檔。

- [ ] **Step 5: Commit**

```bash
git add publisher/Dockerfile publisher/docker-compose.yml backend/docker-compose.yml
git commit -m "feat(publisher): 獨立 Dockerfile 與 compose；backend compose 移除 publisher service"
```

---

### Task 7: 部署 workflow 拆分

**Files:**
- Create: `.github/workflows/deploy-publisher.yml`
- Modify: `.github/workflows/deploy-backend.yml`

**Interfaces:**
- Consumes: Task 6 的 `publisher/docker-compose.yml`。
- Produces: 兩條互相獨立的手動部署 workflow。

- [ ] **Step 1: 寫 deploy-publisher.yml**

```yaml
name: Deploy Publisher

# 只部署 social publisher（Discord 審核 bot + IG 發布）+ 推 Supabase migration。
# 與 deploy-backend.yml 互相獨立；db push 兩邊都跑（冪等）。
#
# 第一次部署需手動到 VPS：建立 /opt/lorescape/publisher/.env（自
# backend/.env 拆出 Discord / IG / Gemini / Supabase 值；見
# publisher/.env.example），若用 Vertex 另外放 service-account.json，
# 然後跑一次 `docker compose up -d --build`。
on:
  workflow_dispatch:

jobs:
  push-supabase-db:
    name: Push Supabase DB Schema
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: supabase

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: master

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link Supabase project to setup IPv4
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_PROD_DB_PASSWORD }}

      - name: Push database migrations
        run: supabase db push
        env:
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_PROD_DB_PASSWORD }}

  deploy-publisher:
    name: Deploy Publisher to VPS
    runs-on: ubuntu-latest
    needs: [push-supabase-db]
    steps:
      - name: Deploy + gateway check via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            set -e
            cd /opt/lorescape
            git fetch --prune origin master
            git reset --hard origin/master
            cd publisher
            docker compose up -d --build

            echo "=== docker compose ps ==="
            docker compose ps

            # publisher 容器必須存在且為 running（bad token 會 SystemExit → restart-loop）
            cid=$(docker compose ps -q publisher)
            if [ -z "$cid" ]; then
              echo "❌ no publisher container found"
              docker compose ps
              exit 1
            fi
            state=$(docker inspect -f '{{.State.Status}}' "$cid")
            echo "publisher state: $state"
            if [ "$state" != "running" ]; then
              echo "❌ publisher not running (state=$state)"
              docker compose logs --tail=60 publisher
              exit 1
            fi

            # bot 必須連上 Discord Gateway（最多等 ~50s）
            echo "=== waiting for bot to connect to Discord Gateway ==="
            connected=0
            for i in $(seq 1 10); do
              if docker compose logs --tail=200 publisher 2>&1 \
                   | grep -qiE "connected to gateway|has connected"; then
                connected=1
                break
              fi
              sleep 5
            done
            if [ "$connected" = "1" ]; then
              echo "✅ bot connected to Discord Gateway"
            else
              echo "❌ bot did not connect to Gateway within ~50s"
              docker compose logs --tail=80 publisher
              exit 1
            fi

            echo "=== publisher recent logs ==="
            docker compose logs --tail=30 publisher

  deploy-status:
    name: Deploy Status Report
    runs-on: ubuntu-latest
    needs: [push-supabase-db, deploy-publisher]
    if: always()

    steps:
      - name: Report Status
        run: |
          echo "## 🚀 Publisher 部署狀態報告"
          echo "- Supabase DB 推送: ${{ needs.push-supabase-db.result }}"
          echo "- Publisher 部署: ${{ needs.deploy-publisher.result }}"
```

- [ ] **Step 2: 修改 deploy-backend.yml**

1. 檔頭註解：拿掉「（含 publisher Discord bot）」與 DISCORD_* 首次部署說明，改為「只部署 backend api + 推 Supabase migration。publisher bot 走獨立的 deploy-publisher.yml。」
2. 刪除 SSH script 中 api /health 檢查之後的整段 publisher 驗證（`# publisher 容器必須存在...` 起，至 `docker compose logs --tail=30 publisher` 止）。
3. SSH script 加一行清孤兒容器：把 `docker compose up -d --build` 改為 `docker compose up -d --build --remove-orphans`（舊 publisher 容器從 backend compose 移除後由此清掉）。
4. `deploy-status` job 的 `- Backend + bot 部署:` 改為 `- Backend 部署:`。

- [ ] **Step 3: YAML 語法驗證**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-publisher.yml')); yaml.safe_load(open('.github/workflows/deploy-backend.yml')); print('ok')"`
Expected: `ok`。

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/deploy-publisher.yml .github/workflows/deploy-backend.yml
git commit -m "ci: 拆分 deploy-publisher workflow，deploy-backend 只管 api"
```

---

### Task 8: scripts/ 依賴切換到 lorescape-publisher

**Files:**
- Modify: `scripts/pyproject.toml`
- Modify: `scripts/archive_ig_cards.py:29`、`scripts/daily_video_post.py:525-526`、`scripts/manual_daily_story.py:45-46`、`scripts/publish_reel.py:25-26`、`scripts/send_carousel_for_review.py:27-28`、`scripts/send_reel_for_review.py:26-27`、`scripts/tests/conftest.py:6`

**Interfaces:**
- Consumes: Task 4 的 `lorescape_publisher.*` 模組面。
- Produces: scripts/ 不再依賴 lorescape-backend。

- [ ] **Step 1: pyproject 換 path dependency**

`scripts/pyproject.toml`：

```toml
# 舊
    "lorescape-backend",
[tool.uv.sources]
lorescape-backend = { path = "../backend", editable = true }
# 新
    "lorescape-publisher",
[tool.uv.sources]
lorescape-publisher = { path = "../publisher", editable = true }
```

同時把依賴清單上方的註解改為指向 publisher（`import the publisher package and reuse its Config / daily_story / publishing code`）。

- [ ] **Step 2: 批次改 import**

```bash
LC_ALL=C find scripts -name "*.py" -not -path "*/.venv/*" -exec sed -i '' \
  -e 's/lorescape_backend\.social\.wander/lorescape_publisher.wander/g' \
  -e 's/lorescape_backend\.social/lorescape_publisher/g' \
  -e 's/lorescape_backend\.daily_story/lorescape_publisher.daily_story/g' \
  -e 's/lorescape_backend\.shared\.genai/lorescape_publisher.genai/g' \
  -e 's/lorescape_backend\.config/lorescape_publisher.config/g' \
  {} +
grep -rn "lorescape_backend" scripts --include="*.py" | grep -v .venv
```

Expected: grep 無輸出。注意 `scripts/tests/conftest.py:6` 的 fake config 建構：若它建立了 backend Config 的完整欄位，改成 publisher `Config`（欄位對照 Task 2 Step 4 的 fixture）。`send_carousel_for_review.py` docstring 裡的 `python -m lorescape_backend.social.wander.renderer` 會被 sed 換成 `python -m lorescape_publisher.wander.renderer` —— 確認無誤即可。

- [ ] **Step 3: sync 與測試**

Run: `cd scripts && uv sync && uv run pytest -v`
Expected: sync 成功（依賴樹出現 lorescape-publisher、不再有 lorescape-backend）、測試全 PASS。

- [ ] **Step 4: Commit**

```bash
git add scripts/
git commit -m "refactor(scripts): path dependency 改指 lorescape-publisher"
```

---

### Task 9: 文件收尾與殘留引用清掃

**Files:**
- Modify: `CLAUDE.md`（repo 結構表）
- Create: `docs/adr/0004-split-social-publisher-from-backend.md`
- Modify: 全 repo 殘留引用（以 grep 盤點）

**Interfaces:**
- Consumes: 前面所有 task 的最終結構。
- Produces: 文件與實際結構一致；VPS 手動遷移步驟記錄在 ADR。

- [ ] **Step 1: 更新 CLAUDE.md repo 結構表**

`backend/` 一列改為：

```
| `backend/` | Python FastAPI 服務（只服務 App）：narration API（含訂閱 402 驗證）、訂閱 webhook 與 reconcile。Docker 部署於 VPS |
```

其下新增一列：

```
| `publisher/` | Social publisher（Python）：daily story 產線、Discord 審核 bot、IG 發布。獨立 image 與 .env，Docker 部署於 VPS |
```

「Backend（Python FastAPI）」段落的模組清單同步修正（移除 daily_story、social；補充 publisher 一句話與 `deploy-publisher.yml`）。

- [ ] **Step 2: 寫 ADR 0004**

`docs/adr/0004-split-social-publisher-from-backend.md`，內容涵蓋：

1. **背景**：bot / daily story 與 App API 同套件、同 image，邊界不清、部署綁定。
2. **決策**：拆出頂層 `publisher/`（lorescape-publisher）；backend 只服務 App；`story_prompt.py` / `genai.py` 刻意複製兩份（接受分岔、換完全解耦）；scripts 依賴改指 publisher；部署 workflow 各自獨立。
3. **VPS 一次性遷移步驟**（照抄進 ADR）：
   ```
   1. ssh VPS → cd /opt/lorescape && git pull
   2. 建立 publisher/.env：自 backend/.env 搬走 DISCORD_*、IG_USER_ID、
      META_PAGE_ACCESS_TOKEN、BRAND_HANDLE_IG、DAILY_STORY_*，並複製
      SUPABASE_URL、SUPABASE_SERVICE_ROLE_KEY、GEMINI_*（對照
      publisher/.env.example）
   3. 若 GEMINI_BACKEND=vertex：cp backend/service-account.json publisher/
   4. cd backend && docker compose up -d --build --remove-orphans
      （--remove-orphans 會清掉舊的 lorescape-publisher 容器）
   5. cd ../publisher && docker compose up -d --build
   6. 驗證：docker compose logs publisher | grep -i "connected to gateway"
   7. backend/.env 中已搬走的變數可刪（保留亦無害，backend 不再讀取）
   ```
4. **後果**：改 story_prompt 需人工同步兩份；新增 publisher 部署需先完成上述手動步驟。

- [ ] **Step 3: 全 repo 殘留引用清掃**

```bash
grep -rn "lorescape_backend\.social\|lorescape_backend\.daily_story\|social/publisher_bot\|backend/scripts/diagnose_daily_story\|backend/scripts/backfill" \
  --include="*.md" --include="*.py" --include="*.yml" --include="*.sh" \
  . | grep -v ".venv\|__pycache__\|docs/superpowers\|uv.lock\|node_modules"
```

對每個命中（預期出現在 `docs/`、`.claude/`、`scripts/*.sh` 等）把路徑改為 publisher 對應位置（例：`python -m lorescape_backend.social.publisher_bot` → `python -m lorescape_publisher.bot`；`backend/scripts/diagnose_daily_story.py` → `publisher/scripts/diagnose_daily_story.py`）。`docs/superpowers/` 的歷史 spec/plan 不改。

- [ ] **Step 4: 最終驗證**

```bash
cd backend && uv run pytest -q && cd ../publisher && uv run pytest -q && cd ../scripts && uv run pytest -q
```

Expected: 三個專案全綠。

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md docs/adr/ $(git diff --name-only)
git commit -m "docs: publisher 拆分收尾——CLAUDE.md、ADR 0004、殘留引用清掃"
```

---

## 部署注意事項（實作完成後、merge 前提醒使用者）

- VPS 手動遷移步驟見 ADR 0004（publisher/.env 必須先建好才能跑 deploy-publisher.yml）。
- 部署順序：先 `Deploy Backend`（清掉舊 publisher 容器），再手動完成 .env 遷移，最後 `Deploy Publisher`。
- 使用者的 Claude 記憶（daily-story-publish-bot.md）記載 bot 在 backend——實作完成後更新。
