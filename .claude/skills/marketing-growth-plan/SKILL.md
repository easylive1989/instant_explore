---
name: marketing-growth-plan
description: Generate a stage-appropriate marketing plan for Lorescape based on App 下載數 / MAU / 訂閱數. Tells you exactly what to do (and what NOT to do) at each App growth stage. Use when "what should I do for marketing", "growth plan", "marketing plan", "marketing strategy", "what's the right marketing for my stage", "GTM strategy", "成長計畫", "行銷計畫", "我的 App 下一步", or any request for a stage-appropriate marketing roadmap.
---

# marketing-growth-plan — App Growth Plan

Generate a marketing plan matched to Lorescape's current App stage. The wrong strategy at the wrong stage wastes time and money.

> **Note:** Lorescape is a B2C mobile App (iOS + Android). This plan focuses on organic channels: ASO、IG Reels、SEO、KOL 合作. Paid ads, SDR outreach, and cold-email are explicitly excluded — those capabilities are not available.

## Phase 0: Load Product Context

Read `MARKETING.md` from the **project root**. It has the product name, ICP, value proposition, monetization (RevenueCat freemium + subscription), brand voice, active channels, and Competitive Landscape.

Do NOT ask the user to describe the product — all context is in `MARKETING.md`.

---

## Phase 1: Stage Assessment

Read from `MARKETING.md`. Ask only about what is NOT covered:

1. **App downloads** — total or monthly new installs? (determines stage)
2. **MAU** — monthly active users?
3. **訂閱數** — current paying subscribers? (free-to-paid conversion context)
4. **Retention** — Day 7 / Day 30 retention %? (PMF signal)
5. **Active channels** — what are you already doing? (ASO, IG, SEO, etc.)
6. **Top constraint** — time, content capacity, or knowledge?

## Phase 2: Stage Diagnosis

### App Growth Stage Map

| Stage | Signal | Goal | Marketing Mode |
|-------|--------|------|---------------|
| **Pre-launch** | 0 downloads | 驗證需求 | 建立 App Store 頁面、等候名單、小規模真實用戶測試 |
| **Early** | < 1,000 MAU | 找到 PMF + 第一個成長管道 | 手動、低自動化、學習什麼有效 |
| **Growth** | 1,000–10,000 MAU | 優化 + 擴展管道 | 系統化已驗證的方法，測試新管道 |
| **Scale** | 10,000+ MAU | 擴大覆蓋、提升訂閱轉換 | 複製成功模式、KOL 合作、SEO 長尾 |

**PMF 信號（適用 App）：** Day 30 留存率 > 20% + 訂閱轉換率 > 3% 視為具備基本 PMF。

## Phase 3: Marketing Plan

For each stage, produce:

### What to DO (優先順序)

| Priority | Activity | Why | Skill / Tool | Timeline |
|----------|----------|-----|-------------|----------|
| P0 | [activity] | [reason] | [marketing-* skill 或工具] | Week 1-2 |
| P1 | [activity] | [reason] | [marketing-* skill 或工具] | Week 3-4 |
| P2 | [activity] | [reason] | [marketing-* skill 或工具] | Month 2 |

**Stage-specific focus per channel:**

- **ASO（App Store / Google Play）:** 標題關鍵字、截圖文案、評分回覆 — 適用所有階段，Pre-launch 優先建立
- **IG Reels:** 每週一則景點故事系列 — Early 起執行，Growth 階段頻率加倍
- **SEO / 部落格（lorescape.app/blog）:** 長尾旅遊文章 — Growth 階段開始投資，Scale 階段回報最大
- **KOL 合作（旅遊社群）:** 旅遊 Youtuber / IG 旅人 — Growth 之後，用真實故事換取曝光，無須付費廣告

### What NOT to do（重要）

| 不要做這件事 | 為何看起來有吸引力 | 為何在此階段是錯的 |
|------------|------------------|------------------|
| 投放付費廣告（Meta / Google Ads）| 快速觸達 | 無廣告預算工具；有機管道未驗證前燒錢無效 |
| SDR / cold email 開發 | B2B 教科書方法 | Lorescape 是 B2C App，無銷售團隊，用戶在 App Store 不在信箱 |
| 同時主攻所有社群平台 | 多管道感覺穩 | 內容產能有限；先做深一個平台（IG）再擴展 |
| 早期過度投入 SEO | 長期有效 | 早期寫文章回報慢；先靠 ASO + IG 拿到前 1,000 MAU |

### Growth Loop Recommendation

基於 Lorescape 的產品特性，建議設計下列成長迴圈：

- **Content loop（景點故事分享）:** 用戶在景點使用 → 截圖 / 分享故事 → 朋友看到 → 下載 App
  - 設計重點：在故事頁加入「分享這個故事」一鍵功能，加上 Lorescape watermark
- **SEO loop（旅遊文章 → 下載）:** 部落格長尾文章排名 → 吸引旅遊搜索流量 → App 下載 CTA → 訂閱
  - 設計重點：每篇文章連結到相關景點在 App 內的體驗

> 使用 `marketing-content-calendar` 規劃 IG 內容系列；使用 `marketing-seo-audit` 評估部落格 SEO 狀況。

### Metrics Dashboard

| Metric | 說明 | Early 目標 | Growth 目標 | Scale 目標 |
|--------|------|-----------|------------|-----------|
| 新增下載數 / 月 | App Store + Google Play 合計 | 100+ | 1,000+ | 5,000+ |
| MAU | 月活躍用戶 | 300+ | 3,000+ | 15,000+ |
| Day 30 留存率 | 下載後 30 天仍使用 | > 15% | > 20% | > 25% |
| 訂閱轉換率 | Free → Paid | > 2% | > 3% | > 5% |
| IG 觸及率 / 貼文 | Reels 觸及人數 | 500+ | 5,000+ | 20,000+ |
| ASO 關鍵字排名 | 核心關鍵字前 10 名 | 3 個 | 10 個 | 30 個 |

### 90-Day Roadmap

| Month | Focus | Key Activities | Expected Outcome |
|-------|-------|---------------|-----------------|
| Month 1 | ASO + IG 基礎 | 優化 App Store 截圖與文案、發佈首批 IG Reels 景點故事系列 | 建立品牌存在感，初步 ASO 排名 |
| Month 2 | IG 成長 + 第一批 KOL 接觸 | 穩定週更 IG、DM 聯繫 3–5 位旅遊 KOL 合作 | IG 粉絲增長，KOL 露出引流 |
| Month 3 | SEO 起手 + 轉換優化 | 撰寫 2–3 篇旅遊 SEO 長文、分析訂閱漏斗並 A/B 測試 Paywall | 長尾搜索流量開始建立，訂閱率提升 |

## Phase 4: Skill Routing

Your 90-day plan maps to these skills:

```
Month 1:
  /marketing-landing-page → 優化 lorescape.app 落地頁 + App CTA
  /marketing-content-calendar → 規劃前 4 週 IG 貼文計畫

Month 2:
  /marketing-social → 產出 IG Reels 腳本與 caption
  /marketing-repurpose → 將景點故事改寫成多格式內容

Month 3:
  /marketing-seo-audit → 評估部落格 SEO 現況並規劃長尾文章
  /marketing-brand → 確認 App Store / KOL briefing 用的品牌訊息一致性
```

> 不建議使用任何廣告、email outreach 或 cold-outreach 工具 — 此計畫僅依賴有機成長管道。

## Phase 5: Output

Save to `workspace/growth-plan/`:

```
workspace/growth-plan/
├── _stage-assessment.md         # 當前階段 + 診斷
├── _90-day-plan.md              # 完整計畫
├── _metrics-dashboard.md        # 追蹤指標
├── _skill-routing.md            # 下一步使用哪些 marketing-* skill
└── _anti-patterns.md            # 此階段不要做的事
```

執行 marketing-gate 對所有對外文案（landing page 摘要、IG bio、ASO 摘要）做品質檢查。
