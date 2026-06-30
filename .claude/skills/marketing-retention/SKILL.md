---
name: marketing-retention
description: Lorescape 留存與流失分析 — GA4 留存報表 + RevenueCat 訂閱生命週期、每日故事推播習慣養成、App 推播 win-back 策略。Use when "retention", "reduce churn", "keep customers", "churn analysis", "churn prevention", "win-back", "customer lifetime value", "留存", "流失", "訂閱流失", "用戶留存", "推播策略", "每日故事推播", or any request to analyze or improve Lorescape user retention.
---

# marketing-retention — Lorescape 留存與流失分析

分析 Lorescape 的用戶留存與訂閱流失，設計以 **App 內推播 / 每日故事推播**
為核心的習慣養成策略。不依賴 email 序列（email-system 已移除）。

## Phase 0: 讀取背景

1. 讀取 `MARKETING.md`：ICP（深度知性旅人）、訂閱方案
   （rc_weekly / rc_monthly / rc_annual）、品牌調性、每日故事推播作為
   Differentiator 的定位。
2. 確認 `scripts/.env` 有 `METRICS_SHEET_ID`（lorescape-metrics Sheet）。
3. 讀取 `docs/init/metrics-setup.md` 了解 ga4 分頁欄位（活躍/新用戶）。

---

## Phase 1: 留存資料讀取

### GA4 留存（從 Sheet 讀取）

直接讀取 lorescape-metrics Google Sheet（`METRICS_SHEET_ID`）的 `ga4` 分頁：

| 欄位 | 留存分析用途 |
|------|------------|
| `ios_active` / `android_active` | App 每日活躍用戶趨勢 |
| `ios_new` / `android_new` | 新用戶同期群組起始人數 |

從 Sheet 數據計算：
- **D1 留存率**：安裝次日回訪活躍比例（new 第 0 天 vs active 第 1 天，以週區間估算）
- **D7 留存率**：安裝後第 7 天仍活躍
- **D30 留存率**：安裝後第 30 天仍活躍

若 GA4_PROPERTY_ID_APP 的完整同期群組留存報表可從 GA4 直接導出，
請使用者提供匯出檔案並附於對話中，以提升分析精度。

### RevenueCat 訂閱生命週期

RevenueCat 非 Sheet 資料來源，使用者需手動提供或從 RevenueCat Dashboard 截圖：

```
訂閱生命週期漏斗：
試用（Trial）→ 付費轉換（Trial Converted）
  → 月/週/年訂閱（Active Subscriber）
    → 自動續訂（Renewal）
      → 取消（Cancelled / Not Renewing）
        → 完全流失（Expired / Churned）
```

請使用者提供（或估算）：
- 試用→付費轉換率（Trial Conversion Rate）
- 月度訂閱續訂率（Monthly Renewal Rate）
- 月度訂閱流失率（Monthly Churn Rate）
- 訂閱 LTV（Lifetime Value）

若以上數據暫無，改以 Sheet ga4 的活躍用戶月度趨勢做留存代理指標。

---

## Phase 2: 流失診斷

### 流失類型分類

| 類型 | 定義 | 信號 |
|------|------|------|
| 主動流失 | 用戶主動取消訂閱 | RevenueCat cancelled |
| 被動流失 | 付款失敗 / 卡片過期 | RevenueCat billing issue |
| 沉默流失 | 不取消但停止使用 | GA4 活躍用戶月度下滑 |

### 流失時機分析

| 階段 | 可能原因 |
|------|---------|
| 安裝後 1–3 天（Onboarding 失敗） | 未成功生成第一個故事；地點搜尋不直覺 |
| 安裝後 7–14 天（價值未實現） | 未體驗到每日故事推播；未建立使用習慣 |
| 試用轉換節點 | 功能限制感受強烈；訂閱價格說服力不足 |
| 訂閱首月末 | 內容新鮮感消退；旅行頻率低，感知性價比差 |

### 留存領先指標

| 指標 | 意義 | 從 Sheet/GA4 取得 |
|------|------|-----------------|
| App 每週開啟次數 | 習慣強度 | ga4 分頁 weekly active |
| 每日故事推播開啟率 | Engagement 深度 | GA4 App `daily_story_opened` 事件（如已追蹤） |
| 故事生成次數（first 7 天） | Onboarding 完成 | GA4 App `first_story_generated`（如已追蹤） |
| 語音播放次數 | 核心功能使用 | GA4 App `narration_started`（如已追蹤） |

---

## Phase 3: 留存策略

### 核心理念

Lorescape 的留存機制是「習慣養成」而非「功能鎖定」。
每日故事推播（MARKETING.md Differentiator）是最強的留存工具——
讓用戶每天打開 App 不是因為有旅行，而是因為想「讀世界」。

### 留存干預 — 以風險等級分層

#### 高風險用戶（活躍頻率驟降 / 訂閱即將到期）

App 內推播策略（非 email）：

| 推播情境 | 文案方向 | 觸發條件 |
|----------|----------|----------|
| 沉默 3 天 | 「今天，有個你從沒聽過的故事在等你」＋每日故事快照 | 3 天未開啟 |
| 沉默 7 天 | 「<地點>的秘密，只有你知道嗎？」 | 7 天未開啟 |
| 試用即將結束 | 「還有 2 天能無限探索世界的故事」 | 試用剩 2 天 |
| 訂閱即將到期 | 「<上次探索地點>的下一個故事，在你的訂閱到期後等著你」 | 到期前 7 天 |

推播內容必須符合 MARKETING.md 品牌調性：沉靜、知性、有溫度，
不使用誇張行銷語氣，不用 emoji 超過 3 個。

#### 中風險用戶（使用頻率減少但未沉默）

每日故事推播習慣強化：

- 確保每日故事推播已開啟（App 設定引導）。
- 故事主題對應用戶最近探索的地點類型（個人化推薦）。
- 「文化足跡日誌」提醒：「你已記錄 <N> 個地點，這是你的知識地圖」。

#### 低風險用戶（高活躍）

擴張與口碑：

- 邀請分享文化足跡（PDF 匯出）到社群，帶動自然傳播。
- 提供早鳥新功能體驗（beta access）。
- 推動訂閱從週訂閱升級至月/年訂閱（更高 LTV）。

### Win-Back（完全流失後）

針對已取消訂閱的用戶，透過 **App 推播**（而非 email）再次觸及：

| 推播時機 | 文案方向 |
|----------|----------|
| 取消後 7 天 | 「你上次探索 <地點> 之後，我們新增了 <N> 個故事角度」 |
| 取消後 30 天 | 「下次旅行前，Lorescape 已為 <你的目的地> 準備好故事」 |

若用戶已解除推播通知，win-back 管道僅限 App Store 搜尋曝光（ASO）與
IG 社群內容重新觸及（非 email）。

---

## Phase 4: 非自願流失（付款失敗）

付款失敗的處理依賴 RevenueCat 的 grace period + retry 機制：

- 確認 RevenueCat 已設定 billing retry 邏輯（通常 iOS 由 Apple 管理，Android 由 Google 管理）。
- RevenueCat 可設定 grace period（建議 3–7 天），避免因一次付款失敗即失去訂閱。
- 在 App 內顯示「付款問題」提示橫幅（非推播），引導用戶前往訂閱設定。

---

## Phase 5: 輸出

1. 留存現況摘要（依 Sheet 數據 + 使用者提供的 RevenueCat 資料）。
2. 流失診斷報告（依流失類型與時機）。
3. 90 天留存行動計畫：

| 時程 | 行動 | 衡量指標 |
|------|------|---------|
| 第 1–30 天 | Onboarding 改善：確保新用戶在 D3 內生成第一個故事 | D3 留存率 |
| 第 1–30 天 | 每日故事推播 open rate 監測 | 每日推播 CTR |
| 第 31–60 天 | 試用→訂閱文案優化：突出每日故事習慣養成 | 試用轉換率 |
| 第 61–90 天 | 高活躍用戶升級推動：週訂→月訂→年訂 | 平均 LTV |

4. 每月追蹤指標清單：
   - GA4 App D1 / D7 / D30 留存率（同期群組）
   - RevenueCat 月度訂閱流失率
   - 每日故事推播開啟率
   - 訂閱生命週期漏斗各段轉換率

完成後，對任何 App 推播文案執行 **marketing-gate** 品質關卡（Four U's + 禁用字 + 語氣 check）。

---

## 限制

- Win-back 策略僅限 App 內推播，**不使用 email 序列**（已移除 email-system）。
- 所有 GA4 數字來自 lorescape-metrics Google Sheet；不重新串 GA4 API。
- RevenueCat 資料非 Sheet 來源，須使用者手動提供。
- 推播文案必須符合 MARKETING.md 品牌調性（沉靜知性，無誇張行銷語氣）。
- 折扣優惠上限 20%（需使用者明確批准才可超過）。
