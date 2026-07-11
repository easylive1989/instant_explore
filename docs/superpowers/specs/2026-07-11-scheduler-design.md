# Scheduler 行程表設計

日期：2026-07-11
狀態：已與使用者確認

## 目標

建立 Lorescape 的例行工作行程表：列出每天、每週（週一）、每月（1 號）
特定時間點要做的工作。使用者每天開工時呼叫入口 skill，先處理 scheduler
上的今日待辦；行程表同時顯示在產品 dashboard 上。

## 決策摘要

- 形式：純文件（repo 內 markdown），不接自動排程機制。
- 範圍：全部盤點——除使用者舉例的四項核心，納入專案已知的所有例行工作
  （wander 圖組、reel、待部署追蹤、calendar 期末檢核註記）。
- 時間點：由本設計提案預設（本地時間），使用者可後續調整。
- Dashboard 呈現：「今日待辦」＋每日/每週/每月完整表。
- 每日觸發：寫一個入口 skill（`lorescape-scheduler`），使用者每天開工時
  呼叫，不靠 hook。
- 資料格式：單一 `SCHEDULE.md` 為唯一資料源，dashboard collector 直接
  解析其 markdown 表格（與 `reels_calendar.py` 解析 calendar 檔同模式）；
  不另建 YAML 資料檔。

## 1. SCHEDULE.md（repo 根目錄）

與 `BACKLOG.md`、`MARKETING.md` 並列。三個區段各一張表，欄位固定為
「時間｜工作｜指令 / skill」，供 collector 以 regex 逐列解析。

### 每日

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 09:00 | 產生當日每日故事 → Discord 審核 → 發布 | `/lorescape-manual-daily-story` |
| 發布後 | wander 圖組（發布流程 Step 8b 自動接）→ 審核 → 發 IG | `/lorescape-wander-carousel` |
| 發布後 | 產當日 reel 影片 → 發 IG Reels | `/lorescape-daily-reel` → `/publish-reel` |
| 09:30 | 撈前一日產品數據進 `data/metrics/*.csv` | `/lorescape-metrics` |

### 每週（週一）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 週報：分析最近 7 天數據 vs 前週 | `/marketing-weekly-audit` |
| 10:30 | 排下週每日故事景點 calendar | `/lorescape-reels-planner` |
| 11:00 | 週報行動清單寫進 `BACKLOG.md`；順檢「待部署」段有無卡住項目 | 手動 |

### 每月（1 號）

| 時間 | 工作 | 指令 / skill |
|---|---|---|
| 10:00 | 月報：最近 30 天數據 vs 前月 | `/marketing-monthly-audit` |
| 10:30 | 月報可執行事項寫進 `BACKLOG.md` | 手動 |

另附註記（不進表格解析）：reels calendar 期末檢核跟「期別結束日」走
（如 8/3），由 `/lorescape-reels-planner` 觸發，不綁月初。

## 2. Dashboard 區塊

- 新 collector：`dashboard/src/lorescape_dashboard/collectors/schedule.py`。
  - 解析 `SCHEDULE.md` 三張表（regex 逐列，同 reels_calendar 模式）。
  - 檔案不存在時 raise `RuntimeError`（沿用現有錯誤處理慣例）。
  - 「今日待辦」運算：每日項全列；今天是週一才列週表項；今天是 1 號
    才列月表項。
  - 輸出 `{"today": [...], "daily": [...], "weekly": [...], "monthly": [...]}`。
- render：區塊頂部列「今日待辦」，順序為每日表→週表→月表、各依表格
  原列順序（表內已按時間排列，「發布後」等非時刻值不參與排序）；下方
  三張完整表。
  `--serve` 模式下與其他區塊一樣就地重收集。

## 3. 測試

`dashboard/tests/test_schedule.py`：

- 表格解析（三區段、欄位、附註不被解析為項目）。
- 今日待辦運算：週一/非週一、1 號/非 1 號。
- 檔案缺失時的錯誤。

執行方式：`uv run python -m pytest`（dashboard/ 目錄下）。

## 4. 入口 skill：lorescape-scheduler

位置：`.claude/skills/lorescape-scheduler/`（與其他 lorescape-* skills
同慣例）。

- 觸發：使用者每天開工時呼叫——「開工」「今天的工作」「先處理
  scheduler」`/lorescape-scheduler`。
- 行為：
  1. 讀 `SCHEDULE.md`，依今天日期算出今日待辦（每日項＋週一加週表＋
     1 號加月表）。
  2. 先查證哪些已完成再列清單——不靠狀態檔，直接看產出物：今天的
     daily story 是否已在 Supabase、`data/metrics/*.csv` 最新日期是否
     已含昨日、calendar 是否已涵蓋下週。同一天重跑不會重做。
  3. 列出今日待辦與完成狀態，依時間順序帶著做：每一項就是呼叫對應
     skill，一項完成再進下一項。
- 定位：純「入口」，不重複實作任何流程，只做排程判斷、完成度查證、
  依序調度。

## 不做的事（YAGNI）

- 不接 cron / scheduled agents / SessionStart hook 自動觸發。
- 不建 YAML/JSON 資料檔，不做雙份資料源。
- 不做完成狀態持久化（狀態檔）；完成度一律由產出物查證。
