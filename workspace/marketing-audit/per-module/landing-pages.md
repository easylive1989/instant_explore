# Landing Pages — Lorescape
**Score: 68/100 (C)**
**Source tier:** user_provided (codebase analysis)

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| Strong narrative hero copy | "體驗歷史，而不只是風景" / "Experience history, not just the view" — emotionally resonant, differentiated | user_provided |
| Dual CTA placement | Hero + FinalCTA sections both have App Store / Google Play buttons | user_provided |
| Social proof claim | "加入五萬名探索者" — but see FLAG below | user_provided |
| Bilingual (zh/en) | Full landing in both languages, auto-detected by locale | user_provided |
| Brand manifesto section | "世界本身就是展品" — high emotional impact for target ICP | user_provided |
| 4 features highlighted | LocalStories, ManyAngles, ExploreNearby, JourneyJournal — all with copy | user_provided |
| Footer with legal links | Privacy, Terms, Support linked | user_provided |
| Intro video exists | `public/videos/lorescape-intro.mp4` + poster image exist on disk | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| **⚠️ "50,000 explorers" claim — needs verification** | finalCTA.body claims "加入五萬名探索者". If this is aspirational copy (not real), replace with a verifiable proof point or remove. Legal risk if untrue. | **P0** |
| No pricing on landing page | Visitors can't see subscription cost before downloading. High friction for premium consideration. | P1 |
| No testimonials or reviews | Zero user quotes, star ratings, or case studies. No social proof beyond the 50k claim. | P1 |
| Video not embedded | `lorescape-intro.mp4` exists in `public/videos/` but no `<video>` element appears in landing page components. Wasted asset. | P1 |
| No email capture | No newsletter signup or lead magnet. Visitors who don't download are lost forever. | P1 |
| Support email is personal Gmail | `easylive1989@gmail.com` shown publicly on /support page. Damages trust + professionalism. | P1 |
| No pricing page | No `/pricing` route in sitemap or app router. Conversion gap. | P2 |
| CTA copy is generic | "下載 App" / "Download App" — no urgency, no value framing. Try "開始你的第一段故事" (already in FinalCTA — use there). | P2 |
| No FAQ section | Common objections (Is it free? Which languages? Does it work offline?) not addressed. | P2 |
| No competitor comparison | No "vs. traditional audio guides" positioning on page. | P3 |
