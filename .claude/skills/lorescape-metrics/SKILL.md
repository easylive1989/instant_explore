---
name: lorescape-metrics
description: Use when the user wants to pull Lorescape product metrics into a saved report — Google Search Console search traffic, GA4 landing + app traffic, Instagram reach/followers, or App Store / Play downloads & ratings. Triggers on 「產品數據報告」「這週/這月數據」「抓 GSC / 搜尋流量」「GA4 / landing / App 流量」「IG 數據 / 觸及」「App 下載 / 評分」. API-first (GSC/GA4/IG); App Store / Play captured via the Chrome browser. Writes to docs/metrics/<date>/. Local, read-only, does not touch the server.
---

# Lorescape 數據抓取報告

手動把 Lorescape 各來源的產品數據抓成報告檔，存到
`docs/metrics/<結束日>/`（`summary.md` + 各來源 `.csv`）。
API 為主（GSC / GA4 / IG），App Store / Play 用瀏覽器抓。

## 前置條件

- **Google（GSC + GA4）**：見 `references/google-setup.md`（一次性 ADC 登入 +
  在 `backend/.env` 填 `GSC_SITE_URL` / `GA4_PROPERTY_ID_WEB` /
  `GA4_PROPERTY_ID_APP`）。
- **IG**：沿用 `backend/.env` 既有的 `IG_USER_ID` / `META_PAGE_ACCESS_TOKEN`。
- **App Store / Play**：使用者已在 Chrome 登入 App Store Connect 與 Play
  Console，見 `references/stores-browser.md`。

## 步驟

1. 跟使用者確認區間（預設近 7 天，可用 `--days 28` 或 `--start/--end`）與
   要抓哪些來源（預設全部）。

2. **先 dry-run** 檢查設定與憑證（不抓資料）：

       cd backend && uv run python -m scripts.metrics.report --check

   把每個來源的 ready / missing 狀態念給使用者；缺設定的先補。

3. 抓 API 來源並產生報告：

       cd backend && uv run python -m scripts.metrics.report --days 7

   只抓單一來源時用 `--only`，例如 `--only ig` 或 `--only gsc,ga4`。
   完成後讀出 `docs/metrics/<結束日>/summary.md` 的重點給使用者。

4. **App Store / Play（瀏覽器）**：依使用者要求，按
   `references/stores-browser.md` 用 Chrome 抓下載數與評分，截圖存到
   報告資料夾，並把數字附加成 `summary.md` 的「## stores」段落。

## 注意

- 全程本機、唯讀，不寫 Supabase、不碰 server 排程。
- 某來源缺憑證或失敗時，報告會標 `skipped: <原因>` 並照常產出其他來源，
  不需整批重跑。
