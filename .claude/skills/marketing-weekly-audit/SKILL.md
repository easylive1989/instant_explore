---
name: marketing-weekly-audit
description: Lorescape 每週行銷週報 — 從 lorescape-metrics 累積的 data/metrics CSV 讀取最近 7 天資料、對比前週，輸出健康評分與行動清單。Use when "weekly audit", "weekly marketing review", "weekly check-in", "weekly scorecard", "what changed this week", "Friday marketing review", "每週審計", "本週數據", "週報", "每週行銷檢查", or any request for a recurring 7-day marketing audit for Lorescape.
---

# marketing-weekly-audit — Lorescape 每週行銷週報

從 lorescape-metrics 累積的 data/metrics/*.csv 讀取最近 7 天資料，
對比前一週，輸出健康評分與下週行動清單。

## Phase 0: 前置

1. 讀取 `MARKETING.md`，確認品牌、渠道、ICP、訂閱方案。
2. 確認 `data/metrics/*.csv` 存在（唯一資料來源；由 lorescape-metrics 累積）。
3. 讀取 `docs/init/metrics-setup.md` 確認各分頁欄位定義。

---

## Phase 1: 讀取 CSV 資料

**不重新抓 API**。直接讀取 `data/metrics/*.csv` 各檔的最近 14 天資料（7 天本週 + 7 天前週）。

若 CSV 資料不足 14 天，使用現有天數並標注「資料不足，以現有天數計算」。

若 CSV 完全無資料（`data/metrics/` 不存在或為空），提示使用者先執行
**lorescape-metrics** skill 累積資料，再回來跑週報。

### 各分頁讀取欄位

| 分頁 | 欄位（本週加總/平均） | 代表指標 |
|------|----------------------|----------|
| `gsc` | clicks、impressions、ctr（平均）、position（平均） | 搜尋能見度 |
| `ga4` | web_active、web_new、ios_active、ios_new、android_active、android_new | Landing + App 流量 |
| `ig` | reach（加總）、profile_views（加總）、followers（最新快照） | IG 帳號表現 |
| `ig_posts` | 本週新貼文的 reach、likes、comments、plays、avg_watch_time | 內容效果 |

App Store 下載數 / 評分：若使用者上週有透過 lorescape-metrics 更新，
從 CSV 讀取；否則標注為「待補」。

---

## Phase 2: 週度對比

計算本週（最近 7 天）vs 前週（前 7 天）的絕對值差與百分比變化。

格式：`本週值（前週值，±X%）`

| 指標 | 本週 | 前週 | 變化 |
|------|------|------|------|
| GSC 搜尋點擊 | — | — | — |
| GSC 曝光次數 | — | — | — |
| GSC 平均排名 | — | — | — |
| Landing 新用戶 | — | — | — |
| Landing 活躍用戶 | — | — | — |
| App 活躍（iOS） | — | — | — |
| App 活躍（Android） | — | — | — |
| IG 帳號觸及 | — | — | — |
| IG 個人檔案瀏覽 | — | — | — |
| IG 粉絲數（快照） | — | — | — |
| 本週新發貼文數 | — | — | — |
| 本週貼文總觸及 | — | — | — |

---

## Phase 3: 健康評分

對每個指標區塊評 🟢 / 🟡 / 🔴 / ⬜：

| 顏色 | 意義 |
|------|------|
| 🟢 | 達標或正成長，無需立即行動 |
| 🟡 | 需本週關注，有下滑趨勢 |
| 🔴 | 需立即處理，明顯退步 |
| ⬜ | 資料缺失，無法評分 |

### 評分區塊

| 區塊 | 評分 | 依據 |
|------|------|------|
| 搜尋流量（GSC） | — | 搜尋點擊 WoW |
| Landing 流量（GA4 Web） | — | 新用戶 WoW |
| App 活躍（GA4 App） | — | iOS + Android 活躍 WoW |
| IG 觸及 / 粉絲 | — | 觸及 + 粉絲成長 WoW |
| IG 內容效果 | — | 本週貼文平均觸及 / plays |
| App 下載 / 評分 | — | 下載數（若有）/ 評分 |

---

## Phase 4: 行動清單

依優先序分三組：

### 本週立即處理（P0）

列出 🔴 項目 + 建議行動 + 負責人（若知道）。

### 下週觀察（P1）

列出 🟡 項目 + 觀察方向。

### 資料缺口（待補）

列出 ⬜ 項目 + 補充方式（提示執行哪個 skill 或手動步驟）。

### Skill 路由

| 發現 | 建議執行的 skill / 動作 |
|------|----------------|
| 搜尋排名下滑 | `marketing-seo-audit` |
| Landing 流量下滑 | `marketing-landing-page`（改文案） |
| IG 觸及 / 互動率下滑 | 手動優化 caption / hashtag；題材配比見 `lorescape-reels-planner` |
| App 活躍用戶下滑 | `marketing-retention` |
| 整體策略方向不明 | 手動：重看 `MARKETING.md` 定位 + brainstorming |
| 追蹤資料缺失 | 手動：檢查 UTM / GA4 設定（`docs/init/metrics-setup.md`） |

---

## Phase 5: 輸出

週報標題：`Lorescape 行銷週報 <YYYY-MM-DD>`

輸出格式：

```
## Lorescape 行銷週報 <YYYY-MM-DD>

### 數據摘要
[週度對比表格]

### 健康評分
[評分區塊表格]

### 行動清單
#### 本週立即處理（P0）
- ...
#### 下週觀察（P1）
- ...
#### 資料缺口（待補）
- ...

### 資料來源
- data/metrics/*.csv 各檔，讀取日期：<今日>
- 資料期間：<本週日期範圍> vs <前週日期範圍>
```

週報內容如要對外分享或發佈，先執行 **marketing-gate** 品質關卡。

---

## 限制

- 所有數字來自 lorescape-metrics 的 data/metrics CSV；不重新串 GSC / GA4 / IG API。
- RevenueCat 訂閱數已在 revenuecat.csv（快照）；缺日時標「N/A」。
- 若 CSV 資料更新時間落後超過 3 天，提示使用者先執行 lorescape-metrics。
- 不輸出無來源的推斷數字。
