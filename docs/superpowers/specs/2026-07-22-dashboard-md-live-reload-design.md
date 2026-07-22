# Dashboard md 即時刷新 + 快速啟動腳本

## 背景

dashboard 的 `--serve` 模式下，`GET /` 只從快取渲染，讀 md 檔的三個區塊
（`backlog` / `schedule` / `reels`）要手動按 `↻` 或重啟才會反映 md 編輯。
目標：編輯 md 存檔後這些區塊自動更新；並提供免打長 uv 指令的啟動腳本。

## 範圍

三個 md-backed 區塊與其來源檔：

| section | 來源 md |
|---|---|
| `backlog` | `BACKLOG.md` |
| `schedule` | `SCHEDULE.md` |
| `reels` | `marketing/content-calendar/_reels-place-calendar.md` |

## Part 1：mtime 偵測自動刷新

- **config.py**：新增 `SCHEDULE_PATH`、`CALENDAR_PATH` 常數，並定義
  `SECTION_SOURCE_FILES: dict[str, Path]`（section key → md 檔）。
  `schedule.py` / `reels_calendar.py` 改從 config import 路徑（DRY，比照 backlog）。
- **server.py**：新增 `GET /api/mtimes`，回傳 `{key: st_mtime | null}`，
  來源為 `SECTION_SOURCE_FILES`。實際重收集沿用既有 `POST /api/section/<key>`。
- **render.py `_LIVE_JS`**：每 2 秒 `fetch('/api/mtimes')`，記住上次值；
  某 key 的 mtime 變大就呼叫既有 `refreshSection(key)` 就地替換。
  首次輪詢只記 baseline、不觸發。`daily_story`/`deploys` 的 60 秒輪詢保留。

## Part 2：scripts/dashboard.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec uv run --project dashboard lorescape-dashboard --serve --skip-tests "$@"
```

`chmod +x`。預設帶 `--skip-tests`（首次秒開，測試區塊讀上次快取），
`"$@"` 可再加參數（如 `--port 9000`）。

## 測試

- `test_server.py`：`/api/mtimes` 回傳現有 md 的 mtime、缺檔給 null、未知路徑安全。
- `SECTION_SOURCE_FILES` 對照表指向的檔案路徑正確。

## 不做

- 不改 md 以外區塊的刷新行為；不引入檔案 watch/SSE（輪詢已足夠且無 API 成本）。
