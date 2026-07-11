---
name: lorescape-metrics
description: Use when the user wants to update Lorescape's accumulating daily metrics — Google Search Console search traffic, GA4 landing + app traffic, Instagram account reach/followers, per-post IG/Reels insights, RevenueCat subscription/revenue snapshot, or App Store / Play downloads & ratings. Triggers on 「產品數據報告」「這週/這月數據」「抓 GSC / 搜尋流量」「GA4 / landing / App 流量」「IG 數據 / 觸及」「每則貼文 / 貼文成效」「訂閱 / 營收 / MRR / RevenueCat」「App 下載 / 評分」. API-first (GSC/GA4/IG/RevenueCat); App Store / Play captured via the Chrome browser. Accumulates into a Google Sheet (METRICS_SHEET_ID), one tab per source. Local, read-only, does not touch the server.
---

# Lorescape 數據抓取報告

把 Lorescape 各來源的產品數據**累積**到一張 **Google Sheet**
（`scripts/.env` 的 `METRICS_SHEET_ID`），每來源一個分頁、逐日一列、
跨次累積。試算表是唯一資料來源，補抓缺口時直接讀回試算表判斷。
API 為主（GSC / GA4 / IG / IG 逐則貼文 / RevenueCat），App Store / Play 用瀏覽器抓。

預設抓**昨天**；執行時自動偵測「最後紀錄日 → 昨天」的缺口並逐日補抓，
分頁首次（或空）時回溯 30 天建立基線。重跑同一天會覆蓋、不重複。

## 來源與分頁

| 來源 | 分頁 | key | 內容 |
| --- | --- | --- | --- |
| `gsc` | `gsc` | date | 站台每日 clicks / impressions / ctr / position |
| `ga4` | `ga4` | date | 每日 web / iOS / Android 各自的 active / new users（App = iOS + Android） |
| `ig` | `ig` | date | 帳號每日 reach / profile_views（= 個人檔案/bio 瀏覽數）（+ 最新一天 followers/media 快照） |
| `ig_posts` | `ig_posts` | (media_id, obs_date) | 每則貼文**逐日**追蹤：obs_date、posted_date、reach、likes、comments、saved、shares、total_interactions，Reels 另含 views、avg_watch_time |
| `revenuecat` | `revenuecat` | date | 訂閱/營收每日快照：mrr、active_subscriptions、active_trials、active_users_28d、new_customers_28d、revenue_28d |

`ig_posts` 是**每則貼文的逐日時間序列**：每次跑會為「發布在近 7 天內的每則
貼文」各記一列當天觀察（key = `media_id` + `obs_date`），所以每篇貼文最多
累積約 7 列後就離開追蹤窗、不再更新（追蹤天數 = `ig_posts.py` 的
`_TRACK_DAYS`）。`obs_date` 是觀察當天（= 昨天），`posted_date` 是發布日。
貼文 insights 只能讀「當下累計值」，跟 `revenuecat` 一樣**漏掉的天無法回補**
——要逐日連續就得**每天跑一次**。重跑同一天會覆蓋該貼文當天那列。分頁固定
依 **發布日 → 貼文 → 觀察日** 排序，所以同一則貼文的逐日列會相鄰、照時間排。

想知道「昨天有多少人看過我的 IG bio」直接看 `ig` 分頁昨天那列的
`profile_views`（IG 的 profile/個人檔案瀏覽數，已每天記錄）。

`revenuecat` 是**快照**來源：RevenueCat 公開 API 只給「當下」的 overview
指標，沒有逐日歷史，所以每次只會記昨天一列（重跑同日覆蓋），**漏掉的天無法
回補**。要逐日連續就得每天跑一次。

分析公式請另開分頁**引用**這些頁（如 `=gsc!A2`），不要直接在這些頁加欄位，
否則下次同步會被整頁覆寫。

## 前置條件

完整一次性設定（service account、IG token、API 啟用、踩雷排解）見
**`docs/init/metrics-setup.md`**。摘要：

- **Google（GSC + GA4）**：用 **service account**（非 ADC，ADC 會被 Google
  擋），`scripts/.env` 設 `GOOGLE_APPLICATION_CREDENTIALS` +
  `GA4_PROPERTY_ID_WEB` + `GSC_SITE_URL`。
- **IG（含逐則貼文）**：`scripts/.env` 的 `META_PAGE_ACCESS_TOKEN` 須帶
  `instagram_manage_insights` 權限（用 `scripts/meta_token_helper.py` 產），
  並設 `IG_USER_ID`。逐則貼文用同一組憑證。
- **Google Sheet 目的地**：`scripts/.env` 設 `METRICS_SHEET_ID`，並把試算表
  分享給 service account（編輯者）、啟用 Sheets API。詳見
  `docs/init/metrics-setup.md` §D。
- **RevenueCat（訂閱/營收）**：`scripts/.env` 設 `REVENUECAT_V2_API_KEY`
  （RevenueCat → Project settings → API keys 建一把 **v2 secret key**，給
  metrics/overview 讀取權限；注意這跟 backend/.env 的 v1 `REVENUECAT_API_KEY`
  是不同的金鑰）與 `REVENUECAT_PROJECT_ID`（Project settings 的 Project ID）。
- **App Store / Play**：使用者已在 Chrome 登入 App Store Connect 與 Play
  Console，見 `references/stores-browser.md`。

## 步驟

> 以下所有相對路徑（`scripts/`、`docs/`、`references/`）都是相對於**專案根目錄
> `instant_explore/`**，不是這個 skill 資料夾。metrics 程式在
> `instant_explore/scripts/metrics/`。指令請在專案根目錄下執行，例如
> `cd /Users/paulwu/Documents/PLRepo/instant_explore/scripts`。

1. 跟使用者確認要更新哪些來源（預設全部）。一般不必指定日期，工具會自動補到
   昨天；如要手動補特定區間用 `--start/--end`，調整首次回溯天數用 `--days N`
   （`ig_posts` 的追蹤窗固定 7 天、不受 `--days` 影響）。

2. **先 dry-run** 檢查設定與待補進度（讀試算表算缺口，不抓 API）：

       cd <instant_explore 專案根>/scripts && uv run python -m metrics.report --check

   每個來源會顯示 ready / 缺設定，以及「最後紀錄日、待補幾天 → 昨天」
   （`ig_posts` 顯示追蹤中的貼文發布區間 + 已存的觀察列數）。缺設定的先補。

3. 抓 API 來源並寫進試算表：

       cd <instant_explore 專案根>/scripts && uv run python -m metrics.report

   只抓單一來源時用 `--only`，例如 `--only ig_posts` 或 `--only gsc,ga4`。
   完成後把 stdout 的每來源結果（`+N row(s) for <區間>` / `up to date` /
   `skipped`）念給使用者，必要時讀出對應分頁的近期幾列確認。

4. **App Store / Play（瀏覽器）**：依使用者要求，按
   `references/stores-browser.md` 用 Chrome 抓下載數與評分，把數字記到
   試算表（截圖可留在 scratchpad），需要時附一段文字摘要給使用者。

5. **選點規劃提示**：若本次更新了 `ig` / `ig_posts` 並向使用者做了
   IG 成效分析，結尾提示可接著用 **lorescape-reels-planner** 依最新
   數據規劃或檢核每日景點 Reel 的選點 calendar（下期排程、配比調整、
   期末檢核到期時尤其該提）。

## 注意

- 全程本機、唯讀，不寫 Supabase、不碰 server 排程；只寫使用者自己的試算表。
- 缺 `METRICS_SHEET_ID`、試算表沒分享給 service account、或 Sheets API 沒啟用
  時會直接報錯，依 `docs/init/metrics-setup.md` §D 補齊。
- 某來源缺憑證或失敗時，該來源標 `skipped: <原因>`，其他來源照常累積，
  不需整批重跑；之後補設定再跑會自動補上缺口。
- IG 帳號歷史 followers/media 無法回溯，只在最新一天填快照；逐日 reach /
  profile_views 用單日 `total_value` 查詢，數字對應該日曆日。
- `ig_posts` 逐日追蹤只能往前累積、漏掉的天無法回補，所以要**每天跑一次**
  才連續；每篇貼文追蹤約 7 天後自動離開。若曾用舊版（每則單列快照）的
  `ig_posts` 分頁，改版第一次跑前需把該分頁清成新 header（欄位結構不同）。
