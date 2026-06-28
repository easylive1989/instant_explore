---
name: lorescape-metrics
description: Use when the user wants to update Lorescape's accumulating daily metrics — Google Search Console search traffic, GA4 landing + app traffic, Instagram account reach/followers, per-post IG/Reels insights, or App Store / Play downloads & ratings. Triggers on 「產品數據報告」「這週/這月數據」「抓 GSC / 搜尋流量」「GA4 / landing / App 流量」「IG 數據 / 觸及」「每則貼文 / 貼文成效」「App 下載 / 評分」. API-first (GSC/GA4/IG); App Store / Play captured via the Chrome browser. Accumulates into docs/metrics/daily/. Local, read-only, does not touch the server.
---

# Lorescape 數據抓取報告

把 Lorescape 各來源的產品數據**累積**成固定資料集，存到
`docs/metrics/daily/`（每來源一個 CSV，逐日一列、跨次累積）。
API 為主（GSC / GA4 / IG / IG 逐則貼文），App Store / Play 用瀏覽器抓。

預設抓**昨天**；執行時自動偵測「最後紀錄日 → 昨天」的缺口並逐日補抓，
資料集首次（或檔案空）時回溯 30 天建立基線。重跑同一天會覆蓋、不重複。

## 來源與輸出檔

| 來源 | 檔案 | key | 內容 |
| --- | --- | --- | --- |
| `gsc` | `gsc.csv` | date | 站台每日 clicks / impressions / ctr / position |
| `ga4` | `ga4.csv` | date | 每日 web / iOS / Android 各自的 active / new users（App = iOS + Android） |
| `ig` | `ig.csv` | date | 帳號每日 reach / profile_views（+ 最新一天 followers/media 快照） |
| `ig_posts` | `ig_posts.csv` | media_id | 逐則貼文：reach、likes、comments、saved、shares、total_interactions，Reels 另含 plays、avg_watch_time |

`ig_posts` 以 media_id 累積，每次重抓最近 30 天的貼文以刷新會隨時間變動的
insights；較舊的貼文保留既有紀錄。

## 前置條件

完整一次性設定（service account、IG token、API 啟用、踩雷排解）見
**`docs/init/metrics-setup.md`**。摘要：

- **Google（GSC + GA4）**：用 **service account**（非 ADC，ADC 會被 Google
  擋），`backend/.env` 設 `GOOGLE_APPLICATION_CREDENTIALS` +
  `GA4_PROPERTY_ID_WEB` + `GSC_SITE_URL`。
- **IG（含逐則貼文）**：`backend/.env` 的 `META_PAGE_ACCESS_TOKEN` 須帶
  `instagram_manage_insights` 權限（用 `scripts/meta_token_helper.py` 產），
  並設 `IG_USER_ID`。逐則貼文用同一組憑證。
- **App Store / Play**：使用者已在 Chrome 登入 App Store Connect 與 Play
  Console，見 `references/stores-browser.md`。

## 步驟

1. 跟使用者確認要更新哪些來源（預設全部）。一般不必指定日期，工具會自動補到
   昨天；如要手動補特定區間用 `--start/--end`，調整首次回溯天數 / 貼文刷新
   視窗用 `--days N`。

2. **先 dry-run** 檢查設定與待補進度（不抓資料、不連網）：

       cd backend && uv run python -m scripts.metrics.report --check

   每個來源會顯示 ready / 缺設定，以及「最後紀錄日、待補幾天 → 昨天」
   （`ig_posts` 顯示要刷新的貼文區間）。缺設定的先補。

3. 抓 API 來源並累積：

       cd backend && uv run python -m scripts.metrics.report

   只抓單一來源時用 `--only`，例如 `--only ig_posts` 或 `--only gsc,ga4`。
   完成後把 stdout 的每來源結果（`+N row(s) for <區間>` / `up to date` /
   `skipped`）念給使用者，必要時讀出對應 `docs/metrics/daily/<來源>.csv`
   的近期幾列。

4. **App Store / Play（瀏覽器）**：依使用者要求，按
   `references/stores-browser.md` 用 Chrome 抓下載數與評分，存到
   `docs/metrics/daily/`（截圖 + 數字），需要時附一段文字摘要給使用者。

## 注意

- 全程本機、唯讀，不寫 Supabase、不碰 server 排程。
- 某來源缺憑證或失敗時，該來源標 `skipped: <原因>`，其他來源照常累積，
  不需整批重跑；之後補設定再跑會自動補上缺口。
- IG 帳號歷史 followers/media 無法回溯，只在最新一天填快照；逐日 reach /
  profile_views 用單日 `total_value` 查詢，數字對應該日曆日。
