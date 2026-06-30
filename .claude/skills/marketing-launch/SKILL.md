---
name: marketing-launch
description: Plan and produce a complete App launch marketing package for Lorescape — landing page copy, social posts, ASO update, content calendar, and launch timeline. Orchestrates surviving marketing-* skills into a coordinated launch. Use when "product launch", "launch campaign", "go-to-market", "GTM plan", "launch marketing", "we're launching", "prepare launch materials", "新功能上線", "App 改版發布", "新市場語言", or any request to coordinate marketing for a new feature, App update, or new language market.
---

# marketing-launch — App Launch Orchestration

Orchestrate a complete Lorescape launch — coordinates landing page, social, content calendar, and SEO into a unified campaign with a timeline.

**Launch targets this skill handles:**
- 新功能上線（e.g., 文化足跡日誌、每日故事推播）
- App 改版發布（e.g., 全新 UI、效能提升）
- 新市場語言（e.g., 英語市場、日語版本）

> **Scope:** This skill does NOT produce ad campaigns, press releases, email sequences, or LinkedIn articles — those channels are not active for Lorescape. It orchestrates only the surviving `marketing-*` skills.

## Phase 0: Load Product Context

Read `MARKETING.md` from the **project root**. It has the product name, ICP, value proposition, monetization (RevenueCat), brand voice, active channels, and Competitive Landscape.

Do NOT ask the user to describe the product — all context is in `MARKETING.md`.

---

## Phase 1: Launch Discovery

Read from `MARKETING.md`. Only ask about things not covered there:

1. **What's launching?** (新功能 / App 改版 / 新市場語言 — which one?)
2. **Launch date** — when does it go live on App Store / Google Play?
3. **Hook or offer** — any launch-period promotion, limited-time discount on RevenueCat plans, or early-access angle?
4. **Active assets** — existing landing page (lorescape.app), IG account, App Store listing — what needs updating vs. creating from scratch?
5. **Language target** — zh-TW only, English only, or bilingual?

## Phase 2: Launch Timeline

Generate `workspace/launch/_timeline.md`.

### App Launch Phases

| Phase | Timing | Activities |
|-------|--------|------------|
| **Pre-launch** | T-14 to T-7 | 更新 App Store / Play 截圖與文案（ASO）、IG 預告 Reels（1–2 則）、landing page 預告 section |
| **Warm-up** | T-7 to T-1 | 詳細功能介紹 Reels（1–2 則）、部落格 / SEO 文章（如適用）、KOL briefing（如有合作）|
| **Launch Day** | T-0 | App Store 更新推送、IG 主發佈 Reels、landing page 更新上線 |
| **Post-launch** | T+1 to T+14 | 用戶反應 Reels（UGC 反應 / 回饋截圖）、部落格補充文章、ASO 追蹤與調整 |
| **Sustain** | T+14 to T+30 | 持續 IG 景點故事系列、SEO 長尾文章、留存分析 |

### Asset Checklist

| Asset | Channel | Phase | Skill |
|-------|---------|-------|-------|
| App Store 文案更新（標題、副標、描述） | ASO | Pre-launch | marketing-landing-page |
| Google Play 文案更新 | ASO | Pre-launch | marketing-landing-page |
| Landing page 功能 section 更新 | Web | Pre-launch | marketing-landing-page |
| IG 預告 Reels（1–2 則） | Instagram | Pre-launch | marketing-social |
| IG 主發佈 Reels（1–2 則） | Instagram | Launch Day | marketing-social |
| IG 後續 Reels（用戶反應系列） | Instagram | Post-launch | marketing-social |
| 內容日曆（4 週 IG 計畫） | 跨管道 | Launch Day | marketing-content-calendar |
| SEO 文章（功能 / 景點長尾） | Blog | Warm-up / Post-launch | marketing-seo-audit |

Adapt to the actual launch. Remove assets the user doesn't need.

### Approval Gate

Present the timeline and asset checklist. Confirm before producing assets.

## Phase 3: Batch Production

Produce assets in dependency order:

### Order of Operations

1. **Landing page copy** — defines the core messaging everyone else references
   → Use `marketing-landing-page`
2. **ASO copy** — App Store / Google Play title, subtitle, description updated to reflect launch
   → Derived from landing page copy
3. **IG launch Reels scripts** — extract hero message + visual hooks from above
   → Use `marketing-social`
4. **Content calendar** — schedule pre/launch/post Reels and supporting posts
   → Use `marketing-content-calendar`
5. **SEO article(s)** — if applicable, write blog post targeting launch-related keywords
   → Use `marketing-seo-audit` to identify keywords first

### Messaging Consistency

All assets must use the same:
- **Core value proposition** (from landing page copy, aligned to MARKETING.md)
- **Key feature proof points** (consistent across ASO, IG, landing page)
- **CTA** (same destination: App Store / Google Play download link or lorescape.app)
- **Brand voice** (沉靜、知性、有溫度 — check MARKETING.md Brand Voice)
- **Language** (zh-TW and/or English per launch target)

Extract core messaging from the landing page copy first; use as reference for all subsequent assets.

### Batch Output

```
workspace/launch/
├── _timeline.md
├── _messaging-guide.md          # Core VP, proof points, CTA — extracted from landing page
├── landing-page/
│   └── copy.md                  # Updated landing page + ASO copy
├── social/
│   ├── pre-launch-reels.md      # IG 預告腳本 + caption
│   ├── launch-day-reels.md      # IG 主發佈腳本 + caption
│   └── post-launch-reels.md     # IG 後續系列腳本
├── content-calendar/
│   └── 4-week-plan.md           # 整合 pre/launch/post 的 4 週排程
├── seo/
│   └── launch-article.md        # SEO 部落格文章（如適用）
└── _quality-report.md
```

## Phase 4: Quality Report

執行 marketing-gate 對所有產出文案進行品質檢查。

```markdown
# Launch Campaign Quality Report

## Summary
- Total assets: [N]
- Passed all gates: [N]
- Channels covered: [list]
- Messaging consistency: [PASS/FAIL — same VP across all assets?]
- Brand voice: [PASS/FAIL — 沉靜、知性、有溫度?]

## Per-Asset Results
| Asset | Channel | Four U's | Banned Words | Voice Patterns | Status |
|-------|---------|----------|-------------|---------------|--------|

## Launch Readiness
- [ ] App Store / Google Play 文案更新完成
- [ ] Landing page 功能 section 更新完成
- [ ] IG pre-launch Reels 腳本完成並排程
- [ ] IG launch-day Reels 腳本完成並待發佈
- [ ] Content calendar 建立完成
- [ ] SEO 文章（如適用）完成
```

## Phase 5: Post-Launch Monitoring Plan

Generate `workspace/launch/_monitoring.md`:

- Day 1, 3, 7, 14 check-in schedule
- Metrics to watch:
  - App Store / Google Play 下載數變化
  - IG Reels 觸及率與互動率
  - Landing page 跳出率與 CTA 點擊率
  - RevenueCat 新訂閱數
  - App Store 評分與新評論
- When to adjust:
  - IG Reels 觸及 < 預期 50% → 修改 hook 或發佈時間
  - App Store 評分下滑 → 檢查新版 bug，加速 hotfix
  - 訂閱轉換率無改善 → 重新審視 Paywall 文案與定價頁
- Content to produce based on early results:
  - 用戶好評截圖 → IG 社群證明貼文
  - 常見問題 → FAQ 部落格文章或 App 內 tooltip
