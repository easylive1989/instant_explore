# Dashboard Scheduler 月曆視圖 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** dashboard「Scheduler 行程表」分頁保留「今日待辦」表，下方三張折疊表換成當月月曆格狀視圖，點格子展開該日明細。

**Architecture:** 伺服器端渲染——collector 把 `compute_today` 一般化為 `compute_for_date(sections, d)`；`render.py` 用 stdlib `calendar` 排出當月 7 欄 grid，每日明細預先渲染成 per-day hidden 區塊，JS 只做事件委派切換顯示（存活於 `--serve` 模式的 ↻ 就地替換）。

**Tech Stack:** Python 3.13（uv 管理）、stdlib `calendar` / `datetime`、pytest；HTML/CSS/vanilla JS（單檔自包含、無外部資源）。

**Spec:** `docs/superpowers/specs/2026-07-11-schedule-calendar-design.md`

## Global Constraints

- 工作目錄 `dashboard/`；測試指令一律 `uv run python -m pytest`（不要裸跑 `uv run pytest`，可能吃到系統 Python）。
- `SCHEDULE.md` 格式與 `/lorescape-scheduler` skill 完全不動。
- `collect()` 對外輸出格式不變：`{"today": [...], "daily": [...], "weekly": [...], "monthly": [...]}`（serve 模式 `/api/section/schedule` 相容）。
- 產出 HTML 保持單檔自包含：無外部資源、無 JS 依賴。
- 程式註解與 docstring 用繁體中文（技術名詞除外）。

---

### Task 1: collector — `compute_for_date`

**Files:**
- Modify: `dashboard/src/lorescape_dashboard/collectors/schedule.py:42-49`
- Test: `dashboard/tests/test_schedule.py`

**Interfaces:**
- Consumes: 既有 `parse_schedule(text) -> dict`（回傳 `{"daily": [...], "weekly": [...], "monthly": [...]}`，每項為 `{"time", "task", "command"}`）。
- Produces: `compute_for_date(sections: dict, d: date) -> list[dict]` — 回傳該日待辦，每項附 `"cadence"`（`"每日"` / `"每週"` / `"每月"`）；`compute_today(sections, today)` 保留為薄包裝，行為不變。Task 2 的 render 會 import `compute_for_date`。

- [ ] **Step 1: 寫失敗測試**

在 `dashboard/tests/test_schedule.py` 的 import 行加上 `compute_for_date`：

```python
from lorescape_dashboard.collectors.schedule import (
    compute_for_date,
    compute_today,
    parse_schedule,
)
```

在 `TestComputeToday` class 之後新增：

```python
class TestComputeForDate:
    def test_平日只列每日項(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 7, 14))  # 週二、非 1 號
        assert [i["cadence"] for i in items] == ["每日", "每日"]

    def test_週一加列週表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 7, 13))  # 週一
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週"]

    def test_一號加列月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 8, 1))  # 週六、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每月"]

    def test_週一恰為一號同時加列週表與月表(self):
        sections = parse_schedule(SAMPLE)
        items = compute_for_date(sections, date(2026, 6, 1))  # 週一、1 號
        assert [i["cadence"] for i in items] == ["每日", "每日", "每週", "每月"]
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: 新增 4 個測試 FAIL，錯誤為 `ImportError: cannot import name 'compute_for_date'`。

- [ ] **Step 3: 最小實作**

把 `schedule.py` 的 `compute_today` 改成：

```python
def compute_for_date(sections: dict, d: date) -> list[dict]:
    """指定日期的待辦：每日項全列；週一加週表；1 號加月表。"""
    items = [{**i, "cadence": "每日"} for i in sections["daily"]]
    if d.weekday() == 0:
        items += [{**i, "cadence": "每週"} for i in sections["weekly"]]
    if d.day == 1:
        items += [{**i, "cadence": "每月"} for i in sections["monthly"]]
    return items


def compute_today(sections: dict, today: date) -> list[dict]:
    """今日待辦（compute_for_date 的薄包裝）。"""
    return compute_for_date(sections, today)
```

- [ ] **Step 4: 跑測試確認通過**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: 全數 PASS（含既有 `TestComputeToday` 三個測試）。

- [ ] **Step 5: Commit**

```bash
git add dashboard/src/lorescape_dashboard/collectors/schedule.py dashboard/tests/test_schedule.py
git commit -m "feat(dashboard): compute_for_date——任意日期的排程待辦推算，compute_today 改為薄包裝"
```

---

### Task 2: render — 月曆 HTML + CSS + JS

**Files:**
- Modify: `dashboard/src/lorescape_dashboard/render.py`（`_schedule_html` 區段 557-586 行、`_CSS`、`section_body` 的 schedule 分支 669-670 行、`build_html` 的 `<script>` 715 行、檔頭 import）
- Test: `dashboard/tests/test_schedule.py`（`TestRender`）

**Interfaces:**
- Consumes: Task 1 的 `compute_for_date(sections: dict, d: date) -> list[dict]`；既有 `_schedule_rows(items, with_cadence=False) -> str`、`_E`、`_strip_md`；`section_body` 內已算好的 `today`（`data["generated_at"][:10]`，格式 `YYYY-MM-DD`）。
- Produces: `_schedule_html(schedule: dict, today_str: str) -> str`（簽名多一個 `today_str`）。HTML 結構供測試與 JS 依賴：格子 `<div class="cal-day" data-day="YYYY-MM-DD">`（今天為 `class="cal-day today selected"`）、明細 `<div class="cal-detail" id="cal-detail-YYYY-MM-DD">`（非今天帶 `hidden`）。

- [ ] **Step 1: 改寫失敗測試**

`dashboard/tests/test_schedule.py` 的 `TestRender.test_渲染今日待辦與三張表` 整個換成（`_data` 的 `generated_at` 是 `"2026-07-13 09:00"`，即 2026 年 7 月、週一）：

```python
    def test_渲染今日待辦與月曆(self):
        from lorescape_dashboard import render

        html = render.section_body("schedule", self._data())
        assert "今日待辦" in html
        assert "產生當日每日故事" in html
        assert "marketing-weekly-audit" in html  # 週一含週表項
        # 三張折疊表已移除
        assert "table-fold" not in html
        assert "每月（1 號）" not in html
        # 月曆：2026 年 7 月有 31 個當月格
        assert html.count("data-day=") == 31
        # 今天（7/13）高亮且預設選取，明細預設展開
        assert 'class="cal-day today selected" data-day="2026-07-13"' in html
        assert 'id="cal-detail-2026-07-13">' in html
        assert 'id="cal-detail-2026-07-14" hidden' in html
        # 週一格有週標籤、1 號格有月標籤
        assert "▲ 週 1" in html
        assert "■ 月 1" in html
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py::TestRender -v
```

Expected: `test_渲染今日待辦與月曆` FAIL（`table-fold` 仍在、`data-day` 為 0）。

- [ ] **Step 3: 實作 render**

`render.py` 檔頭 import 區（`import html` / `import re` 附近）加：

```python
import calendar
from datetime import date

from .collectors.schedule import compute_for_date
```

「---------- Scheduler 行程表 ----------」區段整段換成（`_SCHEDULE_TITLES` 刪除、`_schedule_rows` 保留不動）：

```python
# ---------- Scheduler 行程表 ----------

_WEEKDAY_NAMES = "一二三四五六日"


def _schedule_rows(items: list[dict], with_cadence: bool = False) -> str:
    return "".join(
        "<tr>"
        + (f'<td>{_E(i["cadence"])}</td>' if with_cadence else "")
        + f'<td>{_E(i["time"])}</td><td>{_E(_strip_md(i["task"]))}</td>'
        f'<td>{_E(_strip_md(i["command"]))}</td></tr>'
        for i in items
    )


def _cal_cell(d: date, month: int, schedule: dict, today: date) -> str:
    """單一日曆格：非當月為淡色空格；當月列日期與精簡標籤。"""
    if d.month != month:
        return '<div class="cal-day out"></div>'
    tags = []
    if schedule["daily"]:
        tags.append(f'<span class="cal-tag">● 每日 {len(schedule["daily"])}</span>')
    if d.weekday() == 0 and schedule["weekly"]:
        tags.append(f'<span class="cal-tag">▲ 週 {len(schedule["weekly"])}</span>')
    if d.day == 1 and schedule["monthly"]:
        tags.append(f'<span class="cal-tag">■ 月 {len(schedule["monthly"])}</span>')
    classes = "cal-day today selected" if d == today else "cal-day"
    return (
        f'<div class="{classes}" data-day="{d.isoformat()}">'
        f'<b>{d.day}</b>{"".join(tags)}</div>'
    )


def _cal_detail(d: date, schedule: dict, today: date) -> str:
    """單日明細（預先渲染、非今天隱藏，JS 點格子切換顯示）。"""
    header = (
        "<thead><tr><th>週期</th><th>時間</th><th>工作</th><th>指令 / skill</th></tr></thead>"
    )
    rows = _schedule_rows(compute_for_date(schedule, d), with_cadence=True)
    hidden = "" if d == today else " hidden"
    title = f"{d.month}/{d.day}（週{_WEEKDAY_NAMES[d.weekday()]}）"
    return (
        f'<div class="cal-detail" id="cal-detail-{d.isoformat()}"{hidden}>'
        f"<h3>{_E(title)} 待辦</h3><table>{header}<tbody>{rows}</tbody></table></div>"
    )


def _calendar_html(schedule: dict, today: date) -> str:
    weeks = calendar.Calendar().monthdatescalendar(today.year, today.month)
    head = "".join(f'<div class="cal-head">{w}</div>' for w in _WEEKDAY_NAMES)
    cells = "".join(
        _cal_cell(d, today.month, schedule, today) for week in weeks for d in week
    )
    details = "".join(
        _cal_detail(d, schedule, today)
        for week in weeks
        for d in week
        if d.month == today.month
    )
    legend = "● 每日　▲ 每週（週一）　■ 每月（1 號）　點日期看明細"
    return (
        f'<div class="callout"><b>{today.year} 年 {today.month} 月</b>　{_E(legend)}</div>'
        f'<div class="calendar">{head}{cells}</div>{details}'
    )


def _schedule_html(schedule: dict, today_str: str) -> str:
    try:
        today = date.fromisoformat(today_str)
    except ValueError:
        today = date.today()
    today_header = (
        "<thead><tr><th>週期</th><th>時間</th><th>工作</th><th>指令 / skill</th></tr></thead>"
    )
    return (
        '<div class="callout"><b>今日待辦</b></div>'
        f'<table>{today_header}<tbody>{_schedule_rows(schedule["today"], with_cadence=True)}</tbody></table>'
        + _calendar_html(schedule, today)
    )
```

`section_body` 的 schedule 分支改為：

```python
    elif key == "schedule":
        body = _schedule_html(value, today)
```

`_CSS` 末尾（`button.refresh:disabled{...}` 之後）加：

```css
.calendar{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;margin:10px 0}
.cal-head{text-align:center;font-size:12px;color:var(--ink-2);padding:4px 0}
.cal-day{background:var(--surface);border:1px solid var(--border);border-radius:8px;
  min-height:64px;padding:6px 8px;font-size:12px;cursor:pointer;display:flex;
  flex-direction:column;gap:2px}
.cal-day b{font-size:13px;font-variant-numeric:tabular-nums}
.cal-day.out{background:none;border-color:transparent;cursor:default}
.cal-day:not(.out):hover{border-color:var(--series)}
.cal-day.today b{color:var(--series)}
.cal-day.selected{border-color:var(--series);box-shadow:0 0 0 1px var(--series);
  background:var(--wash)}
.cal-tag{color:var(--ink-2);white-space:nowrap}
.cal-detail{margin-top:12px}
.cal-detail h3{font-size:13px;color:var(--ink-2);margin-bottom:6px}
```

`_LIVE_JS` 定義之後加（事件委派掛在 document，serve 模式 ↻ 就地替換 HTML 後仍有效）：

```python
# 月曆點格子 → 切換該日明細；委派到 document，確保 serve 模式 ↻ 後仍可點
_CAL_JS = """
document.addEventListener('click',e=>{
  const cell=e.target.closest('.cal-day[data-day]');
  if(!cell)return;
  const sec=cell.closest('.sec-body');
  sec.querySelectorAll('.cal-day.selected').forEach(c=>c.classList.remove('selected'));
  cell.classList.add('selected');
  sec.querySelectorAll('.cal-detail').forEach(p=>p.hidden=p.id!=='cal-detail-'+cell.dataset.day);
});
"""
```

`build_html` 的 script 行改為：

```python
<script>{_TAB_JS}{_LIVE_JS}{_CAL_JS}</script>
```

- [ ] **Step 4: 跑測試確認通過**

```bash
cd dashboard && uv run python -m pytest tests/test_schedule.py -v
```

Expected: 全數 PASS。

- [ ] **Step 5: 跑整套 dashboard 測試（防跨區塊回歸）**

```bash
cd dashboard && uv run python -m pytest
```

Expected: 全數 PASS（`test_render.py` 等其他測試不受影響）。

- [ ] **Step 6: Commit**

```bash
git add dashboard/src/lorescape_dashboard/render.py dashboard/tests/test_schedule.py
git commit -m "feat(dashboard): scheduler 分頁改月曆視圖——當月格狀 grid、點格子展開單日明細"
```

---

### Task 3: 端對端驗證（實際產出 HTML 目視檢查）

**Files:**
- 無程式改動；產出 `dashboard/out/index.html`

**Interfaces:**
- Consumes: Task 2 完成後的完整 render。
- Produces: 驗證結論（含問題清單，如有則回頭修）。

- [ ] **Step 1: 產出真實面板**

```bash
cd dashboard && uv run lorescape-dashboard --no-open --skip-tests
```

Expected: 正常結束，寫出 `dashboard/out/index.html`（部分 collector 若因環境缺 token 失敗，會渲染錯誤卡，不影響 schedule 區塊）。

- [ ] **Step 2: 目視檢查**

打開 `dashboard/out/index.html`，在「🗓 例行行程」分頁確認：

1. 上方「今日待辦」表仍在；三張折疊表已消失。
2. 月曆為當月、週一起始 7 欄；今天格高亮且明細預設展開在月曆下方。
3. 點其他日期，明細切換；點週一格看到週表項、點 1 號格看到月表項。
4. 系統深色模式下配色正常（macOS 外觀切換或 DevTools 模擬）。

Expected: 四點皆符合；不符合則回 Task 2 修正後重跑測試。

- [ ] **Step 3: （僅驗證，無 commit）**

若目視發現問題並修了 code，修正併入 Task 2 的檔案並補 commit：

```bash
git add dashboard/src/lorescape_dashboard/render.py dashboard/tests/test_schedule.py
git commit -m "fix(dashboard): scheduler 月曆目視驗證修正"
```
