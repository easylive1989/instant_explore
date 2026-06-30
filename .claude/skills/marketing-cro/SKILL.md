---
name: marketing-cro
description: Lorescape 轉換率優化稽核 — 對「lorescape.app 落地頁 → App Store / Google Play 商品頁 → 安裝 → 訂閱（RevenueCat）」完整漏斗執行 5 層 CRO 分析，資料來源 GA4（GA4_PROPERTY_ID_WEB / GA4_PROPERTY_ID_APP）。產出優先修復清單與 A/B 測試建議。Use when "CRO audit", "conversion audit", "轉換率", "漏斗優化", "landing page not converting", "optimize funnel", "訂閱轉換", "安裝轉換", "improve conversion rate", or any request to diagnose and improve lorescape.app → subscription conversion.
---

對 Lorescape 下載 + 訂閱漏斗執行 CRO 稽核。產出優先修復清單。

## Phase 0: 載入產品脈絡

讀 **`MARKETING.md`**（專案根目錄）— 取得 ICP、Revenue Model（RevenueCat 訂閱方案）、Brand Voice、競爭定位。

**漏斗固定為：**
```
lorescape.app 落地頁
    → App Store（id6751904060）/ Google Play（com.paulchwu.instantexplore）商品頁
        → 安裝（首次開啟）
            → 訂閱轉換（RevenueCat：$rc_weekly / $rc_monthly / $rc_annual）
```

**訂閱方案（RevenueCat）：**
- Free：基本探索功能
- Premium Weekly（`$rc_weekly`）
- Premium Monthly（`$rc_monthly`）
- Premium Yearly（`$rc_annual`）

---

## Phase 1: 漏斗輸入確認

從 `MARKETING.md` 讀取。只詢問以下未涵蓋項目：

1. **目標層段** — 全漏斗或特定環節（落地頁、商品頁、訂閱頁）？
2. **現有轉換率** — 若已知（落地頁 → 點擊下載 CTA、安裝 → 訂閱）？
3. **流量來源** — Organic 搜尋、Instagram、付費廣告、口碑？
4. **已知痛點** — 使用者或開發者已發現的摩擦點？
5. **GA4 資料範圍** — 過去 7 天 / 30 天 / 自訂？

## Phase 2: GA4 資料取得

使用 `scripts/.env` 中的環境變數：
- **`GA4_PROPERTY_ID_WEB`** — lorescape.app 網站流量
- **`GA4_PROPERTY_ID_APP`** — iOS + Android App 流量

透過 **lorescape-metrics** skill 取得當前 GA4 資料（`ga4` 分頁）：
- Web：每日 active users / new users（進入落地頁）
- App：每日 active users / new users（安裝後進入 App）
- 漏斗轉換率推算：web new users → app new users（大致代表安裝率）

若 GA4 資料尚未同步，先呼叫 lorescape-metrics 補抓缺口。

每筆資料附來源後設資料：

```yaml
source_tier: connected | public_observed | user_provided | missing_data
source_name: ga4 | app_store_connect | play_console | lorescape-metrics
retrieved_at: ""
confidence: high | medium | low
```

缺少的資料（heatmaps、錄影、A/B 歷史）標記為 `missing_data`，不得估算轉換率或收益影響。

## Phase 3: 競品漏斗比對

在提出商品頁、定價、訂閱相關建議前：

1. 找出直接競品（Google Maps 語音導覽、Rick Steves、景點附設語音導覽）與間接競品（旅遊 podcast、Wikipedia）的 App Store / Play 商品頁。
2. 記錄各競品的：訂閱方案、試用期（trial）、截圖品質、評分策略、App 描述首段（前 3 行）。
3. 建立 **Offer/Pricing Matrix**：競品名稱、方案路徑、計費週期、trial 機制、留存鉤子、風險反轉。
4. 從 mechanics 中萃取 A/B 測試建議，不混入視覺偏好。

若無法取得競品資料，標記為 `missing_data` 列入資料缺口。

## Phase 4: 5 層 CRO 稽核（由下往上）

### Layer 1: 技術效能（先修）

lorescape.app（Next.js）：
- 頁面載入時間（目標 < 2 秒）
- 行動裝置響應（ICP 主要以手機訪問）
- JS 錯誤、broken elements
- App Store / Google Play 連結是否正確且可追蹤（UTM / SKAdNetwork）

App（Flutter）：
- 首次啟動時間
- Onboarding 流程崩潰率（RevenueCat paywall 渲染）

### Layer 2: 流量與受眾品質

- 訪客是否為目標 ICP（25–45 歲深度旅人）？
- 廣告 / IG 內容 → 落地頁的訊息一致性（scent trail）
- Cold traffic（廣告）vs warm traffic（SEO、IG）的落地頁 awareness level 是否對應？
- GSC 關鍵字意圖 vs 落地頁內容的契合度（透過 lorescape-metrics 的 `gsc` 資料）

### Layer 3: Offer 與定價

- 落地頁 5 秒內是否清楚傳達 Lorescape 的 value prop？
- App Store / Play 商品頁首屏（前 3 行）是否精準吸引 ICP？
- 訂閱方案的 value-to-price 感知（Free → Premium 升級動機）
- 是否有試用期（trial）降低付費門檻？
- 風險反轉機制（退款政策、免費方案保留）
- 各方案（weekly/monthly/annual）的推薦預設是否最大化 LTV？

### Layer 4: 設計與佈局

lorescape.app 落地頁：
- 視覺層次 — 眼睛是否流向 App Store / Google Play CTA？
- CTA 按鈕可見度與對比度（`storeButtons.ios` / `storeButtons.android`）
- 首屏內容 — 是否賣故事體驗，而非只描述功能？
- 社會證明位置（評分、用戶評語、下載數）

App Store / Play 商品頁：
- 前 3 張截圖是否展示核心使用情境（景點 → 生成故事 → 語音播放）？
- Preview 影片（若有）前 3 秒是否吸睛？

### Layer 5: 文案與訊息（最高槓桿）

落地頁（對應 `dictionaries.ts` Dict key）：
- Hero headline — 是否陳述結果而非產品功能？
- 是否具體（提到 Wikipedia grounding、2–3 角度自選、語音高亮）？
- 前 3 大異議是否有回應？（「AI 會不會捏造？」「只有台灣景點嗎？」「免費版夠用嗎？」）
- CTA 文字 — 動作動詞 + 結果（「出發就用」而非「立即下載」）
- 每個主張是否有可驗證的 proof？

App Store / Play 描述：
- 首段是否清楚說明 ICP 的 pain + Lorescape 的解決方式？
- 關鍵字是否自然融入（tour guide、audio guide、travel stories、旅遊導覽）？

## Phase 5: 評分

每層 1–10 分：

| 層次 | 分數 | 主要問題 | 修復方式 |
|------|------|----------|----------|
| 技術效能 | /10 | | |
| 流量品質 | /10 | | |
| Offer / 定價 | /10 | | |
| 設計 / 佈局 | /10 | | |
| 文案 / 訊息 | /10 | | |
| **總分** | **/50** | | |

## Phase 6: 優先修復清單

| 優先 | 修復項目 | 層次 | 漏斗環節 | 預期影響 | 工時 |
|------|----------|------|----------|----------|------|
| P0 | | | | High | Low |
| P1 | | | | High | Medium |
| P2 | | | | Medium | Medium |

## Phase 7: 品質關卡

對落地頁文案建議執行 **marketing-gate**（full pipeline）：
- Four U's、禁用字、AI slop、Voice Pattern、SEO Lint。

## Phase 8: 輸出格式

```markdown
# CRO 稽核報告：Lorescape 下載 + 訂閱漏斗

稽核日期：[YYYY-MM-DD]
GA4 資料範圍：[from – to]（GA4_PROPERTY_ID_WEB + GA4_PROPERTY_ID_APP，via lorescape-metrics）

## 漏斗總覽

lorescape.app → App Store / Play → 安裝 → 訂閱（RevenueCat）

| 環節 | 估算流量/轉換（若有資料）| 資料來源 |
|------|--------------------------|----------|

## 健康分數：[X]/50

## 層次分析
[5 層各別分析]

## 競品 Offer / Pricing Matrix
[競品名稱、方案、trial、retention hook、來源 URL]

## 優先修復清單
[P0–P2 表格]

## A/B 測試建議
[來自競品 mechanics 萃取的具體測試項目]

## 文案 Before/After（前 3 大修復）
[落地頁或 App Store 描述，標注 Dict key（若為落地頁）]

## Quality Gate Results（文案建議）
[marketing-gate 輸出]

## 資料缺口
[heatmaps、錄影、A/B 歷史、RevenueCat 轉換率等缺少資料]
```
