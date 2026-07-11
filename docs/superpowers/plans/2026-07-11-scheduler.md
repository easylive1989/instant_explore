# Scheduler 行程表 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 `SCHEDULE.md` 例行工作行程表，讓 dashboard 顯示「今日待辦＋完整表」，並提供 `/lorescape-scheduler` 每日開工入口 skill。

**Architecture:** 單一 `SCHEDULE.md`（repo 根目錄）為唯一資料源，三個 `##` 區段各一張三欄 markdown 表。dashboard 新增 `schedule` collector 以 regex 解析（同 `reels_calendar.py` 模式），今日待辦由 collector 依日期運算；render 新增分頁區塊。skill 是純入口：讀表、由產出物查證完成度、依序調度既有 skills。

**Tech Stack:** Python（dashboard，uv + pytest）、markdown（SCHEDULE.md、SKILL.md）。

**Spec:** `docs/superpowers/specs/2026-07-11-scheduler-design.md`

## Global Constraints

- dashboard 測試一律在 `dashboard/` 目錄下跑 `uv run python -m pytest`（不要直接 `uv run pytest`，會吃到系統 Python）。
- 文件以繁體中文撰寫（技術名詞除外）。
- 機密不進版控；本功能不碰任何憑證。
- 每個 task 完成即 commit；commit 訊息尾加 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`。
- SCHEDULE.md 表格格式固定為三欄「時間｜工作｜指令 / skill」，collector 依此解析，勿改欄位。

---

### Task 1: SCHEDULE.md 行程表檔案

**Files:**
- Create: `SCHEDULE.md`
- Modify: `CLAUDE.md`（repo 結構表加一列）

**Interfaces:**
- Produces: `SCHEDULE.md` 的固定格式——`## 每日`、`## 每週（週一）`、`## 每月（1 號）` 三區段，各一張「時間｜工作｜指令 / skill」三欄表；Task 2 的 collector 依此解析。

- [ ] **Step 1: 建立 SCHEDULE.md**

寫入以下完整內容：

````markdown
# Lorescape Scheduler 行程表

每天、每週（週一）、每月（1 號）的例行工作。使用者開工時由
`/lorescape-scheduler` skill 讀取本表、查證完成度後依序執行；dashboard 的
「Scheduler 行程表」區塊也解析本表。格式勿改：三個 `## ` 區段、各一張
「時間｜工作｜指令 / skill」三欄表。

## 每日

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 09:00 | 產生當日每日故事 → Discord 審核 → 發布 | `/lorescape-manual-daily-story` |
| 發布後 | wander 圖組（發布流程 Step 8b 自動接）→ 審核 → 發 IG | `/lorescape-wander-carousel` |
| 發布後 | 產當日 reel 影片 → 發 IG Reels | `/lorescape-daily-reel` → `/publish-reel` |
| 09:30 | 撈前一日產品數據進 `data/metrics/*.csv` | `/lorescape-metrics` |

## 每週（週一）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 週報：分析最近 7 天數據 vs 前週 | `/marketing-weekly-audit` |
| 10:30 | 排下週每日故事景點 calendar | `/lorescape-reels-planner` |
| 11:00 | 週報行動清單寫進 `BACKLOG.md`；順檢「待部署」段有無卡住項目 | 手動 |

## 每月（1 號）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 月報：最近 30 天數據 vs 前月 | `/marketing-monthly-audit` |
| 10:30 | 月報可執行事項寫進 `BACKLOG.md` | 手動 |

註記：reels calendar 期末檢核跟「期別結束日」走（如 8/3），由
`/lorescape-reels-planner` 觸發，不綁月初。
````

- [ ] **Step 2: CLAUDE.md repo 結構表加一列**

在 `CLAUDE.md` 的 repo 結構表中 `BACKLOG.md` 那列之後插入：

```markdown
| `SCHEDULE.md` | 例行工作行程表（每日／每週一／每月 1 號）；開工用 `/lorescape-scheduler` 讀取執行，dashboard 亦解析顯示 |
```

- [ ] **Step 3: Commit**

```bash
git add SCHEDULE.md CLAUDE.md
git commit -m "docs: SCHEDULE.md 例行工作行程表——每日/每週一/每月1號三張表

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: dashboard schedule collector（TDD）

**Files:**
- Create: `dashboard/src/lorescape_dashboard/collectors/schedule.py`
- Test: `dashboard/tests/test_schedule.py`

**Interfaces:**
- Consumes: Task 1 的 `SCHEDULE.md` 格式；`lorescape_dashboard.config.REPO_ROOT`。
- Produces:
  - `parse_schedule(text: str) -> dict`：回傳 `{"daily": [...], "weekly": [...], "monthly": [...]}`，每項為 `{"time": str, "task": str, "command": str}`。
  - `compute_today(sections: dict, today: datetime.date) -> list[dict]`：每項多帶 `"cadence"` 鍵（`"每日"`/`"每週"`/`"每月"`）。
  - `collect() -> dict`：`{"today": [...], "daily": [...], "weekly": [...], "monthly": [...]}`；`SCHEDULE.md` 不存在時 raise `RuntimeError`。
  - 模組層常數 `SCHEDULE_PATH`（Task 5 的 skill 文件與測試 monkeypatch 會引用）。

- [ ] **Step 1: 寫失敗測試**

建立 `dashboard/tests/test_schedule.py`：

```python
"""schedule collector 的解析與今日待辦測試。"""
from datetime import date

import pytest

from lorescape_dashboard.collectors import schedule
from lorescape_dashboard.collectors.schedule import compute_today, parse_schedule

SAMPLE = """\
# Lorescape Scheduler 行程表

說明文字，不解析。

## 每日

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 09:00 | 產生當日每日故事 → Discord 審核 → 發布 | `/lorescape-manual-daily-story` |
| 發布後 | wander 圖組 → 審核 → 發 IG | `/lorescape-wander-carousel` |

## 每週（週一）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 週報：分析最近 7 天數據 vs 前週 | `/marketing-weekly-audit` |

## 每月（1 號）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 月報：最近 30 天數據 vs 前月 | `/marketing-monthly-audit` |

註記：reels calendar 期末檢核跟「期別結束日」走，不綁月初。
"""


class TestParseSchedule:
    def test_解析三區段與欄位(self):
        sections = parse_schedule(SAMPLE)
        assert len(sections["daily"]) == 2
        assert len(sections["weekly"]) == 1
        assert len(sections["monthly"]) == 1
        assert sections["daily"][0] == {
            "time": "09:00",
            "task": "產生當日每日故事 → Discord 審核 → 發布",
            "command": "`/lorescape-manual-daily-story`",
        }

    def test_表頭分隔列與註記不被解析為項目(self):
        sections = parse_schedule(SAMPLE)
        all_items = sections["daily"] + sections["weekly"] + sections["monthly"]
        assert all(i["time"] not in ("時間", "---") for i in all_items)
        assert all("註記" not in i["task"] for i in all_items)


class TestComputeToday:
    def test_平日只列每日項(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 7, 14))  # 週二、非 1 號
        assert [i["cadence"] for i in items] == ["每日", "每日"]

    def test_週一加列週表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 7, 13))  # 週一
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週"]
        assert items[-1]["command"] == "`/marketing-weekly-audit`"

    def test_一號加列月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_today(sections, date(2026, 8, 1))  # 週六、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每月"]


class TestCollect:
    def test_檔案缺失時報錯(self, monkeypatch, tmp_path):
        monkeypatch.setattr(schedule, "SCHEDULE_PATH", tmp_path / "SCHEDULE.md")
        with pytest.raises(RuntimeError, match="行程表不存在"):
            schedule.collect()

    def test_讀檔並含今日待辦(self, monkeypatch, tmp_path):
        path = tmp_path / "SCHEDULE.md"
        path.write_text(SAMPLE, encoding="utf-8")
        monkeypatch.setattr(schedule, "SCHEDULE_PATH", path)
        result = schedule.collect()
        assert len(result["daily"]) == 2
        assert all(i["cadence"] == "每日" for i in result["today"][:2])
```

日期依據：2026-07-13 是週一、2026-07-14 是週二、2026-08-01 是週六且為 1 號。

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: FAIL — `ModuleNotFoundError: No module named 'lorescape_dashboard.collectors.schedule'`

- [ ] **Step 3: 實作 collector**

建立 `dashboard/src/lorescape_dashboard/collectors/schedule.py`：

```python
"""Scheduler 行程表：解析 SCHEDULE.md 三張例行工作表。"""
from __future__ import annotations

import re
from datetime import date

from ..config import REPO_ROOT

SCHEDULE_PATH = REPO_ROOT / "SCHEDULE.md"

_SECTION_KEYS = {"每日": "daily", "每週": "weekly", "每月": "monthly"}
_HEADING_RE = re.compile(r"^##\s*(每日|每週|每月)")
# 排程列：| 09:00 | 工作描述 | `/skill` |
_ROW_RE = re.compile(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$")


def parse_schedule(text: str) -> dict:
    """解析三個區段的三欄表；表頭列與分隔列略過。"""
    sections: dict = {"daily": [], "weekly": [], "monthly": []}
    current: str | None = None
    for line in text.splitlines():
        stripped = line.strip()
        heading = _HEADING_RE.match(stripped)
        if heading:
            current = _SECTION_KEYS[heading.group(1)]
            continue
        if stripped.startswith("## "):
            current = None
            continue
        m = _ROW_RE.match(stripped)
        if not m or current is None:
            continue
        time_ = m.group(1)
        if time_ == "時間" or set(time_) <= {"-", ":"}:
            continue
        sections[current].append(
            {"time": time_, "task": m.group(2), "command": m.group(3)}
        )
    return sections


def compute_today(sections: dict, today: date) -> list[dict]:
    """今日待辦：每日項全列；週一加週表；1 號加月表。"""
    items = [{**i, "cadence": "每日"} for i in sections["daily"]]
    if today.weekday() == 0:
        items += [{**i, "cadence": "每週"} for i in sections["weekly"]]
    if today.day == 1:
        items += [{**i, "cadence": "每月"} for i in sections["monthly"]]
    return items


def collect() -> dict:
    if not SCHEDULE_PATH.exists():
        raise RuntimeError(f"行程表不存在：{SCHEDULE_PATH}")
    sections = parse_schedule(SCHEDULE_PATH.read_text(encoding="utf-8"))
    return {"today": compute_today(sections, date.today()), **sections}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: 7 passed

- [ ] **Step 5: Commit**

```bash
git add dashboard/src/lorescape_dashboard/collectors/schedule.py dashboard/tests/test_schedule.py
git commit -m "feat(dashboard): schedule collector——解析 SCHEDULE.md 與今日待辦運算

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: dashboard render 區塊與 registry 接線

**Files:**
- Modify: `dashboard/src/lorescape_dashboard/render.py`（新增 `_schedule_html`、`section_body` 分支、`_TABS` 新分頁）
- Modify: `dashboard/src/lorescape_dashboard/cli.py:17-32`（`_registry` 加 `schedule`）
- Test: `dashboard/tests/test_schedule.py`（追加 render 與 registry 測試）

**Interfaces:**
- Consumes: Task 2 的 collect 輸出 `{"today", "daily", "weekly", "monthly"}`。
- Produces: `render.section_body("schedule", data)` 可渲染；registry 鍵名 `"schedule"`（`--only schedule` 與 `--serve` 的 `POST /api/section/schedule` 都因此可用，server 不需改）。

- [ ] **Step 1: 追加失敗測試**

在 `dashboard/tests/test_schedule.py` 檔尾加：

```python
class TestRender:
    def _data(self) -> dict:
        sections = parse_schedule(SAMPLE)
        return {
            "errors": {},
            "collected_at": {},
            "generated_at": "2026-07-13 09:00",
            "schedule": {
                "today": compute_today(sections, date(2026, 7, 13)),
                **sections,
            },
        }

    def test_渲染今日待辦與三張表(self):
        from lorescape_dashboard import render

        html = render.section_body("schedule", self._data())
        assert "今日待辦" in html
        assert "產生當日每日故事" in html
        assert "marketing-weekly-audit" in html  # 週一含週表項
        assert "每月（1 號）" in html  # 完整表仍列出

    def test_registry_含_schedule(self):
        from lorescape_dashboard.cli import _registry

        assert "schedule" in _registry()
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: `test_渲染今日待辦與三張表` FAIL（section_body 回傳「未知的區塊」錯誤卡片，找不到「今日待辦」）；`test_registry_含_schedule` FAIL。

- [ ] **Step 3: 實作 render 區塊**

在 `render.py` 的「---------- Reels 排程 ----------」段之後、「---------- 組頁 ----------」之前，加入：

```python
# ---------- Scheduler 行程表 ----------

_SCHEDULE_TITLES = [("daily", "每日"), ("weekly", "每週（週一）"), ("monthly", "每月（1 號）")]


def _schedule_rows(items: list[dict], with_cadence: bool = False) -> str:
    return "".join(
        "<tr>"
        + (f'<td>{_E(i["cadence"])}</td>' if with_cadence else "")
        + f'<td>{_E(i["time"])}</td><td>{_E(_strip_md(i["task"]))}</td>'
        f'<td>{_E(_strip_md(i["command"]))}</td></tr>'
        for i in items
    )


def _schedule_html(schedule: dict) -> str:
    today_header = (
        "<thead><tr><th>週期</th><th>時間</th><th>工作</th><th>指令 / skill</th></tr></thead>"
    )
    header = "<thead><tr><th>時間</th><th>工作</th><th>指令 / skill</th></tr></thead>"
    parts = [
        '<div class="callout"><b>今日待辦</b></div>',
        f'<table>{today_header}<tbody>{_schedule_rows(schedule["today"], with_cadence=True)}</tbody></table>',
    ]
    for key, title in _SCHEDULE_TITLES:
        parts.append(
            f'<details class="table-fold" open><summary>{_E(title)}（{len(schedule[key])} 項）</summary>'
            f'<table>{header}<tbody>{_schedule_rows(schedule[key])}</tbody></table></details>'
        )
    return "".join(parts)
```

`section_body` 的 elif 鏈中、`else` 之前加分支：

```python
    elif key == "schedule":
        body = _schedule_html(value)
```

`_TABS` 清單最前面插入新分頁：

```python
    ("routine", "🗓 例行行程", [
        ("schedule", "🗓 Scheduler 行程表"),
    ]),
```

- [ ] **Step 4: registry 接線**

`cli.py` 的 `_registry`：import 行加 `schedule`（依字母序放進既有兩行 import），回傳 dict 加一鍵：

```python
    from .collectors import backlog, daily_story, deploys, e2e_cases, metrics
    from .collectors import reels_calendar, schedule, tests_flutter, tests_python
```

```python
        "schedule": schedule.collect,
```

- [ ] **Step 5: 跑測試確認通過（全套）**

```bash
cd dashboard && uv run python -m pytest -v
```

Expected: 全部通過（既有測試不受影響，test_schedule.py 9 項全過）。

- [ ] **Step 6: Commit**

```bash
git add dashboard/src/lorescape_dashboard/render.py dashboard/src/lorescape_dashboard/cli.py dashboard/tests/test_schedule.py
git commit -m "feat(dashboard): Scheduler 行程表分頁——今日待辦 + 每日/每週/每月完整表

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: lorescape-scheduler 入口 skill

**Files:**
- Create: `.claude/skills/lorescape-scheduler/SKILL.md`

**Interfaces:**
- Consumes: Task 1 的 `SCHEDULE.md`。
- Produces: 使用者可用 `/lorescape-scheduler`（或「開工」等語句）觸發的開工流程。

- [ ] **Step 1: 建立 SKILL.md**

寫入以下完整內容：

````markdown
---
name: lorescape-scheduler
description: Use when the user starts the day's work on Lorescape — 「開工」「開始今天的工作」「先處理 scheduler」「今天要做什麼」/lorescape-scheduler — to read SCHEDULE.md, verify from artifacts which routine items are already done, list today's todos, and drive them in order by invoking each item's skill.
---

# Lorescape Scheduler：每日開工入口

讀 repo 根目錄的 `SCHEDULE.md`，算出今日待辦，由產出物查證完成度，
依序帶著做。本 skill 是純入口：不重複實作任何流程，只做排程判斷、
完成度查證、依序調度。SCHEDULE.md 是唯一資料源，項目增刪改一律改該檔。

## 步驟

### 1. 算出今日待辦

- 每日表：全列。
- 每週表：今天是週一才列。
- 每月表：今天是 1 號才列。
- 表格外的「註記」不是待辦項（如 reels calendar 期末檢核，跟期別結束日走）。

### 2. 查證哪些已完成（不靠狀態檔，看產出物）

| 項目 | 查證方式 |
|---|---|
| 每日故事 | 用 /lorescape-debug 的今日狀態查法看 Supabase 今天是否已有發布記錄 |
| wander 圖組 / reel | 同上看今日 posts 的 media type；reel 另看 `marketing/outputs/daily_video/<今天>/` 是否有成品 |
| metrics | `data/metrics/*.csv` 各檔最新日期是否已含昨日 |
| 週：下週 calendar | `marketing/content-calendar/_reels-place-calendar.md` 的範圍是否已涵蓋下週 |
| 週報 / 月報 | `marketing/audits/` 是否已有本期報告檔；沒有落地檔就直接問使用者 |
| 手動項（寫 BACKLOG） | 問使用者或看 `BACKLOG.md` 當日 diff |

### 3. 列清單並依序執行

- 以 checklist 列出每項：時間、工作、狀態（✅ 已完成 / ⬜ 待做）。
- 依表格順序逐項做：每項呼叫「指令 / skill」欄對應的 skill，
  一項完成再進下一項。
- 「手動」項：提出具體建議內容，請使用者確認後代為執行。
- 同一天重跑：已完成項直接跳過，不重做。
````

- [ ] **Step 2: 人工驗證 frontmatter**

檢查 SKILL.md frontmatter 只有 `name` 與 `description` 兩鍵、description 含觸發語句與行為摘要（與其他 lorescape-* skills 慣例一致）。

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/lorescape-scheduler/SKILL.md
git commit -m "feat(skills): lorescape-scheduler 每日開工入口——讀 SCHEDULE.md、查證完成度、依序調度

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: 端到端驗證

**Files:**
- 無新檔；驗證 Task 1–4 成果。

- [ ] **Step 1: 全套 dashboard 測試**

```bash
cd dashboard && uv run python -m pytest
```

Expected: 全部通過。

- [ ] **Step 2: 實際產面板驗證區塊**

```bash
cd dashboard && uv run lorescape-dashboard --only schedule --no-open
```

Expected: stdout 列出 `schedule: ✅`；接著確認輸出檔含新區塊：

```bash
grep -c "Scheduler 行程表" dashboard/out/index.html
```

Expected: ≥ 1（分頁按鈕與區塊標題）。再 grep 今日待辦：

```bash
grep -c "今日待辦" dashboard/out/index.html
```

Expected: ≥ 1。

- [ ] **Step 3: 檢視 HTML（人工）**

開 `dashboard/out/index.html` 確認「🗓 例行行程」分頁：今日待辦表在頂部、下方三張完整表、light/dark 皆正常。

- [ ] **Step 4: 若有修正則 commit**

```bash
git add -A && git commit -m "fix(dashboard): scheduler 區塊驗證修正

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

（無修正則略過。）
