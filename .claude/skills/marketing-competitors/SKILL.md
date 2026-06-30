---
name: marketing-competitors
description: Competitive intelligence teardown for Lorescape — 5-layer analysis (signals, product, marketing, positioning, strategy) plus App 對比卡。Use when "competitor analysis", "competitive teardown", "who are our competitors", "app comparison", "competitive intel", "compare us to X", "what is X doing", "競品分析", "對比卡", "對手調查", or any request to research, analyze, or position against travel-app competitors.
---

# marketing-competitors — Competitive Intelligence Teardown

Run a competitive intelligence teardown for Lorescape using the 5-layer CI framework. Produces analysis + App 對比卡 (App comparison cards, not a B2B sales battlecard).

## Phase 0: Load Product Context

Read `MARKETING.md` from the **project root**. It has the product name, ICP, value proposition, monetization (RevenueCat / App Store / Google Play), brand voice, active channels, and the Competitive Landscape with direct and indirect competitors.

Do NOT ask the user to describe the product — all context is in `MARKETING.md`.

---

## Phase 1: Target Selection

Read from `MARKETING.md`. Use the Competitive Landscape as the default competitor list:

**Direct competitors (from MARKETING.md):**
- Google Maps 語音導覽（功能整合在地圖 App，但故事深度不足）
- Rick Steves Audio Tours（高品質但僅限特定歐洲城市，無 AI 即時生成）
- 景點附設語音導覽（受限景點範圍，無自由探索）

**Indirect competitors (from MARKETING.md):**
- Wikipedia / Google 搜尋（文字為主，無故事化敘事與語音）
- Podcast 旅遊節目（非即時、非定位觸發）

Only ask the user if:
1. They name a specific competitor not in MARKETING.md to add.
2. They want a "quick" scan (top 3) or "deep" full landscape.

## Phase 2: 5-Layer Analysis

For each competitor, analyse:

### Layer 1: Signals (Observable Actions)
- App Store / Google Play rating, review count, last update date
- Recent feature launches — App Store release notes, official blog, social media
- Pricing changes — check their App Store/Play listing
- Company funding or partnerships (Crunchbase, press)

### Layer 2: Product
- Core features vs Lorescape (feature matrix per Phase 3)
- Pricing model: free, freemium, subscription, one-time purchase
- Platform coverage: iOS / Android / web
- Language/region coverage
- Offline support

### Layer 3: Marketing
- App Store / Google Play ASO: title, subtitle, keywords, screenshots
- Social media presence and engagement (IG, YouTube, TikTok)
- Content strategy: blog, YouTube, travel influencer partnerships
- User reviews: common praise and complaint themes

### Layer 4: Positioning
- How they describe themselves in App Store listing and website
- Who they target (ICP from their copy and reviews)
- Recurring messaging themes
- vs Lorescape positioning — overlap and differentiation

### Layer 5: Strategy
- Where are they investing? (infer from updates, platform expansion, content cadence)
- What are they betting on long-term?
- Vulnerabilities — static content library, narrow geography, no AI, no voice
- Threats — could they add AI features, expand region coverage?

## Phase 3: App 比較矩陣

Generate a comparison table (do NOT call this a "sales battlecard" — there is no sales team):

| Dimension | Lorescape | Google Maps 語音導覽 | Rick Steves | 景點附設導覽 | Wikipedia/Google |
|-----------|-----------|---------------------|-------------|-------------|-----------------|
| 核心功能 | | | | | |
| 定價模式 | | | | | |
| 目標用戶 | | | | | |
| 地理覆蓋 | | | | | |
| AI 即時生成 | | | | | |
| Wikipedia 事實驗證 | | | | | |
| 語音朗讀 | | | | | |
| 多故事角度 | | | | | |
| 離線支援 | | | | | |
| 主要弱點 | | | | | |

## Phase 4: App 對比卡

Generate a 1-page App 對比卡 per competitor (format adapted for B2C App context — no "killer questions to ask prospects", no "SDR landmines"):

```markdown
# App 對比卡：Lorescape vs [競品]

## 一句定位
[當用戶比較這兩個 App 時，Lorescape 的核心訴求 — 1 句話]

## 我們贏的場景
- [場景 1：例如，想了解任何冷門景點背後故事的旅人]
- [場景 2：例如，不想被固定路線限制的自由行旅人]
- [場景 3：例如，希望語音解放雙眼、邊走邊聽的旅人]

## 競品的優勢
- [場景 1 — 及 Lorescape 如何補足或取捨]
- [場景 2 — 及 Lorescape 如何補足或取捨]

## 競品常見主張
- "[競品聲稱的優勢 1]" → 我們的回應：[具體反駁，非"我們更好"]
- "[競品聲稱的優勢 2]" → 我們的回應：[具體反駁]

## 對用戶有說服力的問題
- [讓用戶自己發現競品限制的問題，例如："它能在台灣任何一個廟宇前即時生成故事嗎？"]
- [另一個問題]
```

## Phase 5: Output

```
workspace/competitive-intel/
├── _landscape-overview.md       # 全景 5 層分析
├── _competitive-matrix.md       # App 比較矩陣
├── app-comparison-cards/
│   ├── vs-google-maps-audio.md
│   ├── vs-rick-steves.md
│   └── vs-wikipedia-google.md
└── _recommendations.md          # 策略建議
```

執行 marketing-gate 對所有定位陳述與對比卡文案做品質檢查。

## Quality Check

- 每個競品主張必須引用來源（App Store 截圖、官網、評論）或標記為推論
- 對比卡反駁必須具體，不能是「我們更好」
- 矩陣必須誠實 — 競品真正勝出的格子要如實標記
- 禁止使用 SDR、cold email、pipeline、sales call、demo 等 B2B 銷售語言
