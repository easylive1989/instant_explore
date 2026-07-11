# 產品面板（Notion 頁面 + 本地 Python 更新工具）設計

日期：2026-07-11
狀態：已核准（brainstorming 收斂後由使用者核准）

## 背景與目標

需要一個「產品面板」一頁看清專案全貌：backlog 項目、自動化測試狀況、測試案例、
產品數據監控。原本想做靜態網頁部署 GitHub Pages，但 repo 是 public、數據含營收
等敏感資訊；收斂後定案：**面板做成 Notion 頁面**（workspace 權限私密、手機隨處
可看），由本地 Python 工具收集資料後透過 Notion API 更新。

## 需求決定

- **形式**：Notion 頁面；不部署 GitHub Pages、不產本地 HTML。
- **更新機制**：本地 Python 工具直接打 Notion API（一次性建 integration token），
  單一指令完成更新，不需經過 Claude session。
- **測試狀況**：更新面板時在本地**實際跑** frontend / backend / publisher 三套
  unit 測試，顯示統計（總數/通過/失敗/耗時）與失敗案例清單。
- **測試案例清單**：**只列 E2E**（patrol `integration_test/` + `test/integration/`），
  從測試檔**靜態解析**案例名稱，不實際執行（patrol 需模擬器）。完整 unit 案例
  清單（550+/415+）不放——塞不進 Notion。
- **產品數據**：讀既有 lorescape-metrics 累積的 Google Sheet（不重打各 API）。
- **額外內容**：各服務部署狀態（落後 master N commits）、Epic 檢核倒數與進度、
  每日故事發布狀態、coverage 與 flutter analyze 狀態。
- **位置**：頂層新資料夾 `dashboard/`，獨立 uv 專案（比照 `publisher/` 慣例）。

## 架構

```
dashboard/
├── pyproject.toml            # uv 管理；deps: requests, python-dotenv, google-auth,
│                             #   google-api-python-client; dev: pytest, requests-mock
├── .env                      # NOTION_TOKEN + NOTION_DASHBOARD_PAGE_ID（gitignore）
├── src/lorescape_dashboard/
│   ├── cli.py                # 進入點與 orchestrator（argparse flags）
│   ├── collectors/
│   │   ├── backlog.py        # 解析 BACKLOG.md：Epic（含「- [ ] YYYY-MM-DD 回顧」檢核
│   │   │                     #   日期倒數）、features/tasks checkbox、「待部署」段落
│   │   ├── tests_flutter.py  # fvm flutter test --machine --coverage（JSON 事件流 →
│   │   │                     #   統計 + 失敗案例）＋ fvm flutter analyze --fatal-infos
│   │   │                     #   ＋ 解析 coverage/lcov.info 算 %
│   │   ├── tests_python.py   # backend、publisher：uv run pytest --junitxml=… →
│   │   │                     #   統計 + 失敗案例
│   │   ├── e2e_cases.py      # 靜態解析 patrolTest / testWidgets 案例名（regex），不執行
│   │   ├── deploys.py        # gh api 各 deploy workflow 最近一次 success run 的
│   │   │                     #   head_sha/時間；git rev-list --count 算落後 master 幾個 commit
│   │   ├── metrics.py        # 讀 metrics Google Sheet 各分頁，取近 30 天資料
│   │   └── daily_story.py    # Supabase REST 查 social_posts 今日 row（status/發布時間）
│   └── notion_writer.py      # 把各 collector JSON 組成 Notion blocks，整頁重寫
├── tests/                    # pytest：parser / block builder 用 fixture 資料測試
└── out/data/*.json           # collector 快取（gitignore）
```

### 執行方式

```bash
cd dashboard && uv run lorescape-dashboard          # 全部：跑測試 + 收集 + 更新 Notion
uv run lorescape-dashboard --skip-tests             # 跳過跑測試，測試區塊用上次快取
uv run lorescape-dashboard --only metrics,deploys   # 只刷新指定區塊
```

每個 collector 產出 JSON 存 `out/data/<name>.json`；notion_writer 讀最新 JSON。
`--skip-tests` / `--only` 靠快取讓其他區塊沿用上次結果。

### Notion 寫入策略

- 固定一個 dashboard page（ID 放 `.env`），此頁**整頁由機器擁有**：每次更新
  archive 既有 children blocks 後重新 append（最簡單、無 diff 邏輯）。
- 頁首放「最後更新時間」與各區塊健康燈號 callout。
- Blocks 用法：區塊標題 = heading；部署/測試統計 = table；backlog features =
  toggle（內含 tasks to-do blocks）；失敗測試與 E2E 清單 = bulleted list；
  metrics = 數字 callout（最新值 + 對上週變化 ▲▼）+ 近 7 天簡表
  （Notion 無 sparkline，用表格呈現）。
- append children 每請求上限 100 blocks、rate limit ~3 req/s：預估整頁
  100–200 blocks，數秒內完成。

### 錯誤處理

每個 collector 各自 try/except：失敗（無網路、缺憑證、測試跑不動）時該區塊在
Notion 顯示錯誤 callout 與上次成功時間，其餘區塊照常更新。缺 `NOTION_TOKEN` 等
設定時 CLI 直接報錯並指向 `docs/init/dashboard-notion-setup.md`。

## 面板區塊（Notion 頁、上到下）

1. **總覽**：最後更新時間、健康燈號 callout（測試綠/紅、部署是否落後、今日故事發了沒）。
2. **Epic 進度**：E1 目標、檢核點倒數天數、epic 底下 features 完成進度（x/y）。
3. **Backlog**：features toggle 清單（編號、標題、狀態、epic 標記，內含 tasks）；
   「⚠️ 待部署」段落獨立醒目 callout。
4. **部署狀態**：backend / publisher / landing / app 表格：最後成功部署時間、
   commit、落後 master N commits（N>0 標註）。
5. **自動化測試**：三套件統計表（總數/通過/失敗/耗時、frontend 另有 coverage % 與
   analyze 結果）；失敗案例 bulleted list（含錯誤訊息）。
6. **E2E 測試案例**：patrol 與 integration 案例名清單（靜態解析）。
7. **產品數據**：GSC 曝光/點擊、GA4 流量、IG 觸及/追蹤者、RevenueCat 訂閱/MRR、
   商店下載/評分、narration 完成率、D1/D7 留存——各來源數字 callout + 近 7 天簡表。
8. **每日故事**：今天的 daily story 狀態（pending/approved/published/沒有 row）、
   發布時間、IG 連結。

## 可重用的既有實作

- `scripts/metrics/sheets.py` 的 `SheetClient`（讀分頁）——`dashboard/` 是獨立 uv
  專案無法 import `scripts/`（package=false），把 read-only 部分（~60 行）複製進
  `collectors/metrics.py` 並註明來源（比照 ADR 0004 兩份複製前例）。
- `METRICS_SHEET_ID` / `GOOGLE_APPLICATION_CREDENTIALS`：沿用 `scripts/.env`。
- Supabase 憑證：讀 `publisher/.env`（read-only REST 查詢）。
- frontend coverage：參照 `frontend/scripts/run_unit_test_coverage.sh` 的流程，
  dashboard 自行解析 lcov。
- 部署 workflow 名單：`.github/workflows/deploy-{backend,publisher,landing,app}.yml`。
- Notion API：直接用 requests 打 REST（`api.notion.com/v1`，version header），
  不引入額外 SDK。

## 一次性設置（使用者操作）

見 `docs/init/dashboard-notion-setup.md`：建 Notion internal integration、拿
token、建/指定 dashboard 頁面並 share 給 integration、把 `NOTION_TOKEN` 與
`NOTION_DASHBOARD_PAGE_ID` 填入 `dashboard/.env`。

## 後續方向（不在本次範圍）

- **metrics 遷移到 Notion**（2026-07-11 使用者提出）：之後想讓 lorescape-metrics
  的數據直接記錄到 Notion database、不再累積到 Google Sheet。本設計的 collector
  → JSON → writer 分層已為此預留：屆時只需把 `collectors/metrics.py` 的資料來源
  從 Sheet 換成 Notion database（或面板直接嵌入該 database），其餘區塊不受影響。

## 驗證方式

- 單元：`cd dashboard && uv run pytest` 全綠。
- 端到端：完整跑一次後在 Notion 頁面肉眼檢查八個區塊；連跑兩次確認整頁重寫
  不殘留舊 blocks；故意拔掉 `GOOGLE_APPLICATION_CREDENTIALS` 再跑，確認 metrics
  區塊顯示錯誤 callout、其餘正常（錯誤隔離）。
- 對帳：面板測試統計與直接跑 `fvm flutter test`、`uv run pytest` 的數字一致；
  E2E 清單與測試檔內案例一致。
