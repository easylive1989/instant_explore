# Lorescape Metrics 數據抓取 Skill — 設計

日期：2026-06-24
狀態：已核可，待寫實作計畫

## 目標

提供一個 `lorescape-metrics` skill，讓使用者在本機手動抓取 Lorescape 各
產品數據來源，輸出成可累積、可比較趨勢的報告檔。涵蓋搜尋流量（GSC）、
landing 與 App 流量（GA4）、Instagram 數據（IG Graph API），以及 App
Store / Google Play 的下載與評分（第一版用瀏覽器自動化 fallback）。

設計原則：能用官方 API 抓就用 API；抓不到 API 介面的來源（商店後台）
用 Chrome 自動化當 fallback。各來源彼此獨立隔離，單一來源失敗不影響其他
來源。

## 範圍

第一版納入四個來源：GSC、GA4、IG、App Store / Play。輸出為報告檔存檔，
方便累積與比較趨勢。包成單一總管 skill `lorescape-metrics`。

明確排除（YAGNI）：
- 不做 Supabase metrics 表或 dashboard（第一版只存檔）。
- 不做排程自動跑（純手動觸發）。
- App Store Connect API / Play Developer API 第二期再補；第一版商店數據
  走瀏覽器自動化。

## 整體結構

```
backend/scripts/metrics/
├── __init__.py
├── _common.py      # 設定載入(.env / property IDs / site URL)、日期區間、
│                   #   markdown / csv 輸出工具、報告路徑
├── gsc.py          # Google Search Console API → 搜尋流量
├── ga4.py          # GA4 Data API → landing(web) + app 流量
├── ig.py           # Instagram Graph API → IG 數據
├── stores.py       # App Store Connect / Play Console 抓取（瀏覽器 fallback 引導）
└── report.py       # 總管：跑所有可用來源 → 合併報告 + 各來源 csv

.claude/skills/lorescape-metrics/
├── SKILL.md
└── references/
    ├── google-setup.md     # 一次性 ADC 登入 + GA4 property ID 取得
    └── stores-browser.md   # Chrome 自動化抓商店後台步驟

docs/metrics/<YYYY-MM-DD>/
├── summary.md      # 中文跨來源重點摘要
├── gsc.csv
├── ga4.csv
└── ig.csv          # 原始列，方便累積比較（進 git，保留趨勢歷史）
```

執行慣例沿用專案既有模式：`cd backend && uv run python -m scripts.metrics.<module>`。

## 各來源抓取內容

### GSC（Google Search Console）
- 區間（預設近 7 / 28 天，可參數指定）的總 clicks、impressions、CTR、
  平均排名。
- Top queries 與 top pages（依 clicks 排序）。
- 透過 Search Console API（`searchanalytics.query`）。

### GA4（landing + app）
- landing(web) 與 app 兩個 stream：active users、new users、來源/媒介、
  關鍵事件、平台分佈。
- landing 的 measurement ID 為 `G-TCYSEZX8T6`；App 走 Firebase 專案
  `instant-explore-7b442`。兩者可能是不同 GA4 property，腳本支援多
  property 設定（`GA4_PROPERTY_ID_WEB` / `GA4_PROPERTY_ID_APP`）。
- 透過 GA4 Data API（`runReport`）。

### IG（Instagram Graph API）
- 粉絲數、reach、profile views、近期貼文 / Reels 的觸及與互動。
- 沿用 `backend/.env` 既有的 `IG_USER_ID`、`META_PAGE_ACCESS_TOKEN`。

### App Store / Play（瀏覽器 fallback）
- 第一版用 Chrome 自動化開 App Store Connect 與 Play Console，讀下載數
  與評分，截圖存證。
- 靠使用者已登入的 Chrome session；步驟寫在 `references/stores-browser.md`。

## 認證與前置條件

- **Google（GSC + GA4）**：一次性由使用者自己跑
  `gcloud auth application-default login --scopes=openid,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/webmasters.readonly`。
  帳號 `easylive1989@gmail.com` 須對該 GA4 property 與 Search Console 網站
  有讀取權限。GA4 numeric property ID 第一次跑時優先用 GA4 Admin API
  自動探測（依 measurement ID 對應），探測失敗才請使用者貼上；確認後
  存進 `backend/.env`（`GA4_PROPERTY_ID_WEB` / `GA4_PROPERTY_ID_APP`、
  `GSC_SITE_URL`）。
- **IG**：沿用現有 `.env`，無額外設定。
- **Stores**：靠使用者已登入的 Chrome session。

## 行為與錯誤處理

- 每個來源獨立隔離：缺憑證 / API 失敗時，只在報告標註
  `skipped: <原因>` 並繼續其他來源，不整批中斷。
- 提供 `--check` 模式：只驗證設定與憑證、印出將抓的 property / site，
  不實際抓取。用於安全地 debug 設定。
- API 為主、商店後台網頁為輔，全部彙整進同一份 `summary.md`。
- 日期區間預設近 7 天，可用參數覆寫（如 `--days 28` 或起訖日）。

## 相依套件（backend，用 uv 加）

- `google-api-python-client` + `google-auth`：GSC 與 GA4 Admin（property 探測）。
- `google-analytics-data`：GA4 Data API。
- IG 沿用現有 HTTP client（與既有 `scripts/publish_reel.py` 等一致）。

## Skill 設計

`lorescape-metrics` 單一 SKILL.md，description 觸發詞涵蓋：
「產品數據報告」「這週/這月數據」「抓 GSC / 搜尋流量」
「GA4 / landing / App 流量」「IG 數據 / 觸及」「App 下載 / 評分」。

行為：
- 「做數據報告」→ 跑 `report.py`，所有可用來源 → 合併報告。
- 「只抓 IG / 只抓 GSC」→ 跑對應單一 module。
- 各來源「前置條件」分段寫清楚；Google 與 Stores 的設定細節放
  `references/` 內，SKILL.md 保持精簡。

## 測試

- 腳本以 I/O 為主；重點對 `_common.py` 的純函式寫單元測試（日期區間
  計算、markdown / csv 格式化、報告路徑）。
- 抓取層用 `--check` 模式手動驗證憑證與設定。

## 待釐清 / 已決議

- 輸出位置：`docs/metrics/<日期>/`，進 git 以保留趨勢歷史。（已決）
- GA4 property：優先自動探測，失敗才請使用者貼 ID。（已決）
- 四個來源照設計，無增減。（已決）
```
