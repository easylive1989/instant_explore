---
name: marketing-monthly-audit
description: Lorescape 每月行銷月報 — 從 lorescape-metrics 累積的 data/metrics CSV 讀取最近 30 天資料、對比前月，輸出策略學習與下月計畫。Use when "monthly audit", "monthly marketing review", "monthly report", "executive marketing review", "month-end audit", "月報", "本月數據", "月度審計", "月度行銷檢查", or any request for a 30-day marketing audit for Lorescape.
---

# marketing-monthly-audit — Lorescape 每月行銷月報

從 lorescape-metrics 累積的 data/metrics/*.csv 讀取最近 30 天資料，
對比前月，輸出月度執行摘要、策略學習與下月計畫。
可彙整當月各週的 marketing-weekly-audit 結果進行月度分析。

## Phase 0: 前置

1. 讀取 `MARKETING.md`：品牌、ICP、渠道、訂閱方案、競爭定位。
2. 確認 `data/metrics/*.csv` 存在（唯一資料來源；由 lorescape-metrics 累積）。
3. 讀取 `docs/init/metrics-setup.md` 確認各分頁欄位定義。
4. 若本月已產出週報（marketing-weekly-audit），讀取作為補充背景。

---

## Phase 1: 讀取 CSV 月度資料

**不重新抓 API**。直接讀取 `data/metrics/*.csv` 各檔的最近 60 天（30 天本月 + 30 天前月）。

若 CSV 資料不足，使用現有天數並標注。
若 CSV 無資料，提示使用者先執行 **lorescape-metrics** skill。

### 各分頁月度彙整

| 分頁 | 月度彙整方式 |
|------|------------|
| `gsc` | clicks 加總、impressions 加總、ctr 平均、position 平均 |
| `ga4` | web_active/new 加總、ios_active/new + android_active/new 加總 |
| `ig` | reach 加總、profile_views 加總、followers（月底快照） |
| `ig_posts` | 本月所有貼文的 reach/likes/plays/avg_watch_time 平均 |

---

## Phase 2: 月度對比

計算本月（最近 30 天）vs 前月（前 30 天）的絕對值差與百分比變化。

| 指標 | 本月 | 前月 | 變化 | 趨勢 |
|------|------|------|------|------|
| GSC 搜尋點擊（加總） | — | — | — | ↑/↓/→ |
| GSC 搜尋曝光（加總） | — | — | — | ↑/↓/→ |
| GSC 平均排名 | — | — | — | ↑/↓/→ |
| Landing 新用戶（加總） | — | — | — | ↑/↓/→ |
| Landing 活躍用戶（加總） | — | — | — | ↑/↓/→ |
| App 活躍用戶（iOS，加總） | — | — | — | ↑/↓/→ |
| App 活躍用戶（Android，加總） | — | — | — | ↑/↓/→ |
| App 新用戶（iOS + Android，加總） | — | — | — | ↑/↓/→ |
| IG 帳號觸及（加總） | — | — | — | ↑/↓/→ |
| IG 個人檔案瀏覽（加總） | — | — | — | ↑/↓/→ |
| IG 粉絲數（月底快照） | — | — | — | ↑/↓/→ |
| 本月發佈貼文數 | — | — | — | ↑/↓/→ |
| 貼文平均觸及 | — | — | — | ↑/↓/→ |
| App Store 下載（若有） | — | — | — | ↑/↓/→ |
| App 評分（若有） | — | — | — | ↑/↓/→ |

---

## Phase 3: 月度執行計分卡

對每個渠道/功能區塊評 🟢 / 🟡 / 🔴 / ⬜：

| 區塊 | 評分 | 趨勢 | 月度結論 |
|------|------|------|---------|
| 搜尋流量（GSC） | — | — | 繼續 / 調整 / 停止 |
| Landing 流量（GA4 Web） | — | — | 繼續 / 調整 / 停止 |
| App 活躍（GA4 App） | — | — | 繼續 / 調整 / 停止 |
| IG 帳號觸及 | — | — | 繼續 / 調整 / 停止 |
| IG 內容效果 | — | — | 繼續 / 調整 / 停止 |
| App 下載 / 評分 | — | — | 繼續 / 調整 / 停止 |
| 訂閱轉換 | — | — | 繼續 / 調整 / 停止 |

「訂閱轉換」欄：若使用者有從 RevenueCat 取得月度訂閱數，填入；否則標「N/A — 需 RevenueCat 數據」。

---

## Phase 4: 月度策略學習

綜合 CSV 數據 + 當月各週報（若有）：

1. **改善了什麼** — 有數字支撐的正面變化。
2. **退步了什麼** — 有數字支撐的負面變化。
3. **反覆出現的問題** — 連續多週出現在行動清單的項目。
4. **令人意外的事** — 意料之外的數字（高或低）。
5. **應該停止的事** — 持續投入但沒有回報的渠道或內容形式。
6. **應該加強的事** — 數據正面但投入不足的方向。
7. **仍無法信任的資料** — 缺口或來源不一致之處。

每一點必須附數字佐證或標注「推斷（尚無數據支撐）」。

---

## Phase 5: 下月計畫

| 優先度 | 行動項目 | 負責方向 | 對應 Skill | 完成期限 |
|--------|----------|---------|-----------|---------|
| P0 | | | | |
| P1 | | | | |
| P2 | | | | |

### Skill 路由

| 發現 | 建議執行的 Skill |
|------|----------------|
| 搜尋流量長期下滑 | `marketing-seo-audit` |
| Landing 轉換率不佳 | `marketing-cro` 或 `marketing-landing-page` |
| IG 觸及/互動持續下滑 | `marketing-social` 或 `marketing-content-calendar` |
| App 活躍留存惡化 | `marketing-retention` |
| 整體成長方向模糊 | `marketing-growth-plan` |
| 追蹤系統需要改善 | `marketing-analytics` |
| 競爭格局有變化 | `marketing-competitors` |

---

## Phase 6: 輸出

月報標題：`Lorescape 行銷月報 <YYYY-MM>`

```
## Lorescape 行銷月報 <YYYY-MM>

### 月度數據摘要
[月度對比表格]

### 執行計分卡
[計分卡表格]

### 月度策略學習
1. 改善了什麼
2. 退步了什麼
3. ...

### 下月計畫
[優先行動表格]

### 資料來源
- data/metrics/*.csv，讀取日期：<今日>
- 資料期間：<本月日期範圍> vs <前月日期範圍>
- 週報彙整（若有）：<引用的週報日期>
```

月報內容如要對外分享或發佈，先執行 **marketing-gate** 品質關卡。

---

## 限制

- 所有數字來自 lorescape-metrics 的 data/metrics CSV；不重新串 GSC / GA4 / IG API。
- RevenueCat 訂閱數非 CSV 來源，須使用者手動提供。
- 不輸出無來源的推斷數字；推斷假設需清楚標注。
- 若 CSV 更新時間落後超過 7 天，提示先執行 lorescape-metrics 補齊資料。
