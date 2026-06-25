# Lorescape 數據抓取（lorescape-metrics）設定指南

`lorescape-metrics` skill 在本機手動抓取產品數據，輸出報告到
`docs/metrics/<結束日>/`（`summary.md` + 各來源 `.csv`）。

- 程式位置：`backend/scripts/metrics/`
- 執行：`cd backend && uv run python -m scripts.metrics.report`
- 驗證設定（不抓資料）：`... report --check`
- 實際抓取：`... report --days 7`（或 `--start/--end`、`--only gsc,ga4,ig`）

四個來源：GSC、GA4（web+app）、IG 走官方 API；App Store / Play 用瀏覽器抓
（見 skill 的 `references/stores-browser.md`，本文件不涵蓋）。

本專案實際使用的識別碼（方便對照）：

| 項目 | 值 |
| --- | --- |
| GA4 資源 ID（單一資源，含 web+iOS+Android） | `514854947` |
| GCP 專案編號（service account 所屬 / API 配額） | `946345911984`（Firebase 專案 `instant-explore-7b442`） |
| Search Console 資源 | `sc-domain:lorescape.app`（網域類型，Cloudflare DNS 驗證） |
| Facebook 粉專 ID | `1135790239616504` |
| IG Business Account ID（`IG_USER_ID`） | `17841402312650550` |

對應的 `backend/.env`：

```
GA4_PROPERTY_ID_WEB=514854947
GA4_PROPERTY_ID_APP=                       # 留空，web/app 同一資源，填了會重複計算
GSC_SITE_URL=sc-domain:lorescape.app
GOOGLE_APPLICATION_CREDENTIALS=/Users/paulwu/.config/lorescape/metrics-sa.json
IG_USER_ID=17841402312650550
META_PAGE_ACCESS_TOKEN=<帶 instagram_manage_insights 的永久粉專 token>
```

---

## A. Google（GSC + GA4）— 用 Service Account

> ⚠️ 不要用 `gcloud auth application-default login`。`analytics.readonly` /
> `webmasters.readonly` 是 Google 認定的「敏感 scope」，gcloud 的共用 OAuth
> client 沒過審，會被擋「系統已封鎖這個應用程式」。**一律用 service account。**
> 程式用 `google.auth.default()`，會自動讀 `GOOGLE_APPLICATION_CREDENTIALS`，
> 不需改任何程式碼。

### A1. 建 service account + 金鑰
1. GCP Console → IAM 與管理 → 服務帳戶 → 建立（如 `lorescape-metrics`），
   專案層級**不用**給任何角色。
2. 該服務帳戶 → 金鑰 → 新增金鑰 → JSON → 下載。
3. 存到 **repo 外**（如 `~/.config/lorescape/metrics-sa.json`），**勿** commit。
4. `backend/.env` 加：`GOOGLE_APPLICATION_CREDENTIALS=<金鑰絕對路徑>`。

### A2. 啟用兩個 API（在 service account 所屬的 GCP 專案）
API 配額算在 service account 的專案（本專案是 `946345911984`），要先啟用：

```
gcloud services enable searchconsole.googleapis.com analyticsdata.googleapis.com --project=946345911984
```

（沒啟用會回 `accessNotConfigured` / `SERVICE_DISABLED` 403。）

### A3. 授權 service account 讀取
用金鑰裡的 `...iam.gserviceaccount.com` email：
- **GA4**：後台 → 管理 → 資源設定 → 資源 →「**資源存取權管理**」→ 新增 →
  貼 email → 角色「**檢視者**」→ 取消「通知新使用者」→ 新增。
- **GSC**：見 A5 驗證資源後，設定 ⚙ → 使用者和權限 → 新增使用者 → 貼 email →
  權限「完整」（或「受限」）。

### A4. GA4 property ID
- GA4 後台 → 管理 → 資源設定 → 資源 → 右上「資源 ID」（純數字，如 `514854947`）。
  注意：資料串流畫面上的大數字是**串流 ID**，不是資源 ID。
- 本專案 web + iOS + Android 三個串流**共用同一資源** → 只填
  `GA4_PROPERTY_ID_WEB`、`GA4_PROPERTY_ID_APP` 留空。單次查詢回傳三平台合計
  （報告標籤雖寫 `web`）。若要拆平台，需在 `ga4.py` 加 `platform` 維度。

### A5. 建立 + 驗證 Search Console 資源
新帳號可能完全沒有資源（開到「歡迎使用」新增頁）。建議**網域類型**：
1. 歡迎頁「網域」框輸入 `lorescape.app` → 繼續。
2. DNS 在 Cloudflare → 對話框可選 **Cloudflare 自動驗證**：按「開始驗證」→
   授權 Google 存取你的 Cloudflare DNS → 它自動加 `google-site-verification`
   TXT 並完成驗證（不用手動編 DNS）。
3. 驗證成功 → `GSC_SITE_URL=sc-domain:lorescape.app`。
4. 回 A3 把 service account 加成使用者。

> 新資源驗證後，Search Console 要 **2~3 天**才開始累積搜尋數據，且不回溯
> 驗證前的資料。剛設好跑出 0 點擊 0 曝光是正常的。

---

## B. Instagram — 取得帶 insights 權限的永久粉專 token

發 Reels 的舊 token 只有發文權限，讀 insights 會回
`(#10) Application does not have permission`。要補
`instagram_manage_insights` 並重新產 token。

### B1. 在 App 開啟 insights 權限
Meta for Developers → 你的 App。先確認權限是否可用：
- 若用「使用案例」架構：使用案例 → 「管理 Instagram 的訊息和內容」→ 自訂 →
  在權限清單把 **`instagram_manage_insights`** 加入（狀態顯示「可供測試」即可，
  開發模式不用送 App Review）。

### B2. 在 Graph API Explorer 產短期 user token
工具 → Graph API 測試工具：
1. 選你的 App，**用戶權杖**。
2. 權限勾齊：`instagram_basic`、`instagram_content_publish`、`pages_show_list`、
   `pages_read_engagement`、`pages_manage_posts`、**`instagram_manage_insights`**。
3. Generate Access Token → 授權；過程中若要選粉專資產，**勾選 Lorescape 粉專**。
4. 可先驗證權限：查詢欄跑 `<IG_USER_ID>/insights?metric=reach&period=day`，
   有回傳 `data` 就代表 insights 權限通了。

### B3. 用 meta_token_helper.py 換永久粉專 token
```
cd backend && uv run python ../scripts/meta_token_helper.py --platform instagram
```
依序輸入 App ID、App Secret（隱藏輸入）、B2 的短期 user token。

> ⚠️ **`/me/accounts` 會是空的**：Lorescape 是「新版粉專體驗 / 商業管理平台」
> 粉專，就算有 `pages_show_list` 也不會出現在 `/me/accounts`。helper 已改成
> 偵測到空清單時**改問你 Facebook Page ID**，輸入 `1135790239616504`，它就用
> 長期 user token 直接抓**永久**粉專 token（commit 8ec2df5）。

helper 最後印出：
```
IG_USER_ID=17841402312650550
META_PAGE_ACCESS_TOKEN=<永久粉專 token>
```
覆蓋 `backend/.env` 同名兩行。

> 手動備援：在 Explorer 用 user token 跑
> `1135790239616504?fields=name,access_token,instagram_business_account`
> 也能直接拿到粉專 token（但短期 user token 衍生的會過期，正式用請走 helper）。

### B4. profile_views 的 API 變更
Graph API v21+ 的帳號 insights，`profile_views` 必須帶
`metric_type=total_value`，否則回 `(#100) ... should be specified with
parameter metric_type=total_value`。`ig.py` 已處理（commit d917abd）：呼叫帶
`metric_type=total_value`，並同時解析 `total_value` 與舊版 `values[]` 兩種回傳。

---

## C. 驗證

```
cd backend
uv run python -m scripts.metrics.report --check     # 三個來源都應顯示 ready
uv run python -m scripts.metrics.report --days 7    # 實際抓取
```
報告在 `docs/metrics/<結束日>/summary.md`。

---

## 疑難排解對照

| 症狀 | 原因 | 解法 |
| --- | --- | --- |
| gcloud ADC「系統已封鎖這個應用程式」 | 敏感 scope，gcloud client 沒過審 | 改用 service account（§A） |
| 403 `accessNotConfigured` / `SERVICE_DISABLED` | GCP 專案沒啟用該 API | `gcloud services enable ...`（§A2） |
| GA4 403「default credentials not found」 | 沒設 `GOOGLE_APPLICATION_CREDENTIALS` 或金鑰無效 | 設 .env 指向 JSON 金鑰（§A1） |
| GA4 / GSC 回 403 權限不足 | service account 沒被加進該資源 | §A3 加 email |
| GSC 0 點擊 0 曝光 | 資源剛驗證 | 等 2~3 天累積，正常 |
| IG `(#10) does not have permission` | token 沒帶 `instagram_manage_insights` | §B 補權限重產 token |
| IG `(#100) profile_views ... metric_type=total_value` | API 改版 | 已於 `ig.py` 修正（§B4） |
| meta_token_helper `No Facebook Pages found` | 新版/商業粉專不出現在 /me/accounts | helper 已改問 Page ID（§B3） |

## 相關檔案
- `backend/scripts/metrics/`（`report.py` 總管、`gsc.py`/`ga4.py`/`ig.py` 來源）
- `.claude/skills/lorescape-metrics/`（SKILL.md + references）
- `scripts/meta_token_helper.py`（換長期 Meta token）
- `docs/superpowers/specs|plans/2026-06-24-lorescape-metrics*`（設計與計畫）
