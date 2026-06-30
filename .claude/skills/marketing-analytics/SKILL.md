---
name: marketing-analytics
description: Lorescape 行銷追蹤計畫與歸因設定 — tracking plan、UTM 規範、轉換漏斗設計與歸因模型。Use when "analytics setup", "attribution", "tracking plan", "UTM", "marketing analytics", "dashboard setup", "measurement strategy", "how do I track", "which metrics", "追蹤計畫", "UTM 設定", "歸因", "數據追蹤", or any request to set up or improve marketing measurement and attribution for Lorescape.
---

# marketing-analytics — Lorescape 行銷追蹤計畫與歸因

設計 Lorescape 的完整行銷量測系統：轉換漏斗、tracking plan、UTM 規範、歸因模型，
對齊既有 GA4 property 與 lorescape-metrics 累積在 Google Sheet 的資料。

## Phase 0: 讀取產品背景

1. 讀取專案根目錄的 `MARKETING.md`，取得 ICP、價值主張、渠道清單與訂閱方案。
2. 讀取 `scripts/.env` 確認以下 key 存在（只讀，不修改）：
   - `METRICS_SHEET_ID` — 唯一資料來源（lorescape-metrics 累積 Sheet）
   - `GA4_PROPERTY_ID_APP` — App（iOS + Android）GA4 Property
   - `GA4_PROPERTY_ID_WEB` — Landing page GA4 Property
3. 讀取 `docs/init/metrics-setup.md` 了解各分頁欄位定義（gsc / ga4 / ig / ig_posts）。

---

## Phase 1: 轉換漏斗定義

Lorescape 的核心轉換路徑：

```
IG 貼文 / Reels
  → 官網 landing page（utm_source=instagram utm_medium=social）
    → App Store / Google Play（utm_campaign=<故事系列>）
      → 安裝（install）
        → 首次生成故事（first_story_generated）
          → 訂閱轉換（subscription_started — RevenueCat rc_weekly/rc_monthly/rc_annual）
            → 續訂（subscription_renewed）
```

不採用多通路 B2B 歸因模型（無 CRM、無長銷售週期）。

---

## Phase 2: 量測缺口稽核

### 讀取現有 Sheet 資料
直接讀取 lorescape-metrics Google Sheet（`METRICS_SHEET_ID`）的各分頁，
評估目前追蹤涵蓋率：

| 分頁 | 欄位 | 代表量測能力 |
|------|------|------------|
| `gsc` | clicks / impressions / ctr / position | Organic 搜尋流量 |
| `ga4` | web_active / web_new / ios_active / ios_new / android_active / android_new | Landing + App 流量 |
| `ig` | reach / profile_views / followers / media | IG 帳號觸及 |
| `ig_posts` | reach / likes / comments / saved / plays / avg_watch_time | 逐則貼文效果 |

### 盲點識別

1. 漏斗中段（IG → landing）：確認 UTM 是否存在於 IG 貼文 bio link / 限動連結。
2. 漏斗下段（landing → App Store）：App Store 不直接提供 UTM 資料；記錄此天然盲點。
3. App 內事件：確認 GA4_PROPERTY_ID_APP 是否有 `first_story_generated`、`narration_started`、`subscription_started` 等事件。

### 歸因模型建議

Lorescape 屬短銷售週期 B2C App，採 **Last-touch（最後點擊）**：

| 情境 | 建議 |
|------|------|
| IG → 官網 → 安裝 | last-touch = IG，用 UTM 捕捉 |
| 有機搜尋 → landing → 安裝 | last-touch = GSC 搜尋 |
| 直接 App Store 搜尋 | 無 UTM 可得，記為 organic/direct |

歸因警語（必須隨建議列出）：
- App Store 平台不開放 UTM 傳遞，IG → 安裝的歸因依賴 IP-based 匹配，準確率有限。
- GA4 web 與 GA4 app 是兩個 property，跨裝置旅程無法完整串接。
- 數字應做方向性參考，不作為單一事實依據。

---

## Phase 3: 建立追蹤計畫

### 核心事件清單

對齊既有 GA4 property，僅列 Lorescape 實際需要的事件：

| 事件名稱 | 觸發時機 | 屬性 | Property |
|----------|----------|------|----------|
| `page_view` | 每次頁面載入 | url、referrer、utm_source、utm_medium、utm_campaign | GA4_PROPERTY_ID_WEB |
| `cta_click` | 點擊 App Store / Google Play 按鈕 | button_id、utm_* | GA4_PROPERTY_ID_WEB |
| `first_open` | App 首次開啟 | platform（ios/android）、source | GA4_PROPERTY_ID_APP |
| `first_story_generated` | 用戶首次生成故事 | place_id、story_aspect | GA4_PROPERTY_ID_APP |
| `narration_started` | 開始播放語音 | story_id、place_name | GA4_PROPERTY_ID_APP |
| `subscription_started` | 訂閱成功 | plan（rc_weekly/rc_monthly/rc_annual）、revenue | GA4_PROPERTY_ID_APP |
| `subscription_renewed` | 自動續訂 | plan、cycle | GA4_PROPERTY_ID_APP |
| `subscription_cancelled` | 取消訂閱 | plan、days_active | GA4_PROPERTY_ID_APP |
| `daily_story_opened` | 開啟每日故事推播 | place_name、story_date | GA4_PROPERTY_ID_APP |

### UTM 規範

所有 IG 貼文 / Reels 連結統一命名規則：

| 參數 | 規範 | 範例 |
|------|------|------|
| `utm_source` | 平台小寫 | `instagram` |
| `utm_medium` | 流量類型 | `social`、`reel`、`story` |
| `utm_campaign` | 系列名稱 + 年月 | `temple-stories-2026-06` |
| `utm_content` | 內容識別符 | `post-001`、`reel-kyoto` |

不使用 `utm_term`（無付費搜尋）。

### UTM Builder 範本

```
https://lorescape.app/?utm_source=instagram&utm_medium=social&utm_campaign=<系列>-<YYYY-MM>&utm_content=<post-id>
```

---

## Phase 4: Dashboard 規格

### 每週一瞥（讀 Sheet）

從 lorescape-metrics Google Sheet 各分頁直接讀取，不重新抓 API：

| 指標 | 來源分頁 | 欄位 |
|------|----------|------|
| IG 觸及 | `ig` | reach（7 日加總） |
| IG 粉絲成長 | `ig` | followers（最新 vs 7 日前） |
| Landing 新用戶 | `ga4` | web_new（7 日加總） |
| App 活躍用戶 | `ga4` | ios_active + android_active（7 日加總） |
| 搜尋點擊 | `gsc` | clicks（7 日加總） |
| 搜尋曝光 | `gsc` | impressions（7 日加總） |

### 轉換漏斗（需手動補充）

App Store / Play 下載數與評分由使用者定期執行 `lorescape-metrics` skill
的 App Store / Play 瀏覽器步驟後更新至 Sheet；RevenueCat 訂閱數須手動記錄。

---

## Phase 5: 輸出

1. 轉換漏斗圖（文字版）
2. 核心事件清單表格
3. UTM 規範文件
4. Dashboard 指標定義（含資料來源分頁）
5. 實施優先清單

完成後，對任何要公開的行銷文字執行 **marketing-gate** 品質關卡。

---

## 限制

- 所有數據讀自 lorescape-metrics Google Sheet；不重新串接 GA4 / GSC / IG API。
- 不採用 B2B 多通路歸因（no CRM join、no LinkedIn、no email drip attribution）。
- UTM 命名全部小寫、無空格、無特殊字元。
- 事件名稱使用 snake_case。
- 歸因模型必須附免責聲明（跨 property 無法完整串接）。
