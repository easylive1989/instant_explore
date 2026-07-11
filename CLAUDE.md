# Lorescape 專案地圖

Lorescape 是 AI 景點故事導覽 App：為使用者眼前的景點生成以 Wikipedia 等
可信來源為本的故事，並以語音朗讀。Freemium + 訂閱制（RevenueCat）。

## Repo 結構

| 路徑 | 內容 |
|---|---|
| `frontend/` | Flutter App（iOS + Android），產品本體 |
| `backend/` | Python FastAPI 服務：narration API（含訂閱 402 驗證）、每日故事、IG 發布 bot（Discord 審核）、訂閱 webhook。Docker 部署於 VPS |
| `landing/` | Next.js 雙語官網 lorescape.app，含 `/place/[slug]` SEO 景點頁 |
| `supabase/` | Supabase schema 與 migrations |
| `marketing/` | 行銷產出：audits、content-calendar、outputs、tools（Remotion reel 等） |
| `scripts/` | 每日故事 / reel / metrics 自動化腳本（Python，uv 管理） |
| `docs/` | 專案文件：`adr/`（技術決策）、design、operations、superpowers specs/plans |
| `BACKLOG.md` | 專案工作項：features（F1…）與 tasks（T1…）；epic 見檔內「Epic」段 |
| `MARKETING.md` | 行銷設定：ICP、value prop、定價、品牌語氣、競品 |

行銷與每日故事的操作流程走各個 lorescape-* 與 marketing-* skills，不在此贅述。

## Frontend（Flutter）

- 一律用 `fvm` 執行 flutter / dart 指令。
- `lib/` 分四層：`app/`（config、router、theme、shell）、`core/`（基礎設施）、
  `shared/`（共用 widgets）、`features/`（功能模組，內部依
  data / domain / presentation 分層）。
- 依賴規則：feature 之間不互相依賴；`app/`、`core/`、`shared/` 不依賴 `features/`。
- 技術選型：Riverpod（`Notifier` / `AsyncNotifier`）、go_router、
  supabase_flutter、purchases_flutter（RevenueCat）、Firebase Analytics / AI。
- 每次改動後執行 `fvm flutter analyze --fatal-infos`，所有問題修完才算完成。
- 測試：`fvm flutter test`；`test/` 鏡射 `lib/` 結構；widget test 規範見
  flutter-widget-tests skill。E2E 用 patrol（`patrol test`）。

## Backend（Python FastAPI）

- 程式在 `backend/src/lorescape_backend/`：narration、daily_story、social、
  subscriptions、sources。
- 依賴用 uv 管理；測試 `uv run pytest`。
- 部署：GitHub Actions `deploy-backend.yml`（手動觸發）→ VPS docker compose。
  其他 workflow：`ci.yml`、`deploy-app.yml`（App 上架）、`deploy-landing.yml`。

## 外部服務

Supabase（auth / DB / storage）、Firebase（Analytics、AI / Gemini）、
Google Maps / Places、RevenueCat（訂閱）、Meta Graph API（IG 發布）。

## 慣例

- 機密只放 `.env` 與 `service-account.json`（均已 gitignore），不進版控、
  不寫死在程式碼。
- 技術決策記在 `docs/adr/`。
- 文件以繁體中文撰寫（技術名詞除外）。
