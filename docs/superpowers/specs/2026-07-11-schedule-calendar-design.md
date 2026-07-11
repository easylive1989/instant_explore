# Dashboard Scheduler 月曆視圖 — 設計

## 目標

dashboard「Scheduler 行程表」分頁改為月曆呈現：保留「今日待辦」表，
下方的三張每日／每週／每月折疊表換成當月月曆格狀視圖，點格子可看
該日明細。資料來源仍是 `SCHEDULE.md`（格式完全不動）。

## 背景

`SCHEDULE.md` 記的是重複規則（每日項天天做、週項在週一、月項在 1 號），
collector `collectors/schedule.py` 解析成三區段並以 `compute_today` 算出
今日待辦。render 端 `_schedule_html` 目前輸出今日待辦表 + 三張折疊表。

## 方案

伺服器端渲染（與 dashboard 其他區塊一致）：月曆 HTML 由 Python 生成，
JS 只負責點格子切換明細顯示。不採前端 JS 生成月曆——那會讓 schedule
成為唯一邏輯在 JS 的區塊，違反 codebase 慣例且難以用 pytest 測試。

## 設計

### Collector（`collectors/schedule.py`）

- `compute_today(sections, today)` 一般化為 `compute_for_date(sections, d)`，
  規則不變：每日項全列；週一（`weekday() == 0`）加週表；1 號加月表。
- `compute_today` 保留為 `compute_for_date` 的薄包裝，`collect()` 的
  輸出格式不變：`today` + 三區段。render 端用 `compute_for_date` 自行
  推算當月每一天的項目。

### Render（`render.py` 的 `_schedule_html`）

- 上方「今日待辦」表原樣保留。
- 三張折疊表移除，換成當月月曆：
  - 7 欄 grid（週一～週日），涵蓋當月完整週數；非當月日期為淡色空格。
  - 每格內容：日期數字 + 精簡標籤（`● 每日 4`；週一格加 `▲ 週 3`；
    1 號格加 `■ 月 2`）。今天的格子高亮。
  - 點格子在月曆下方展開該日完整明細表（週期／時間／工作／指令），
    預設選今天。明細由 Python 預先渲染為 per-day hidden 區塊，JS 僅
    切換顯示。
  - 只顯示當月，不做前後月切換（內容為純重複規則，換月僅週一與
    1 號落點不同，價值低；日後有需要再加）。
- JS 用事件委派（監聽掛在 `document`），確保 `--serve` 模式按 ↻ 就地
  替換區塊 HTML 後點擊仍有效。
- 月曆格與高亮的 CSS 加進現有 style 區，跟隨現有主題做法。

### 測試

- `tests/test_schedule.py`：`compute_for_date` 四種情境——平日、週一、
  1 號、週一恰為 1 號。
- `tests/test_render.py`：月曆 HTML 含當月天數格、今天高亮 class、
  週一格有週標籤、1 號格有月標籤、per-day 明細區塊存在且預設顯示今天。

## 不做的事

- 不改 `SCHEDULE.md` 格式與 `/lorescape-scheduler` skill。
- 不做前後月切換、週視圖、時間軸視圖。
- 不改 `collect()` 對外輸出格式（serve 模式 `/api/section/schedule` 相容）。
