# Prioritized Fix List — Lorescape
**Audit date:** 2026-06-25
**Audit mode:** sales_external (user_provided codebase + public_observed)

---

## P0 — Fix This Week (high impact, low effort)

| # | Fix | Module | Why |
|---|-----|--------|-----|
| 1 | **Verify or remove "50,000 explorers" claim** in `finalCTA.body` | Landing Pages / CRO | Legal risk if aspirational. Replace with real number or testimonial. |
| 2 | **Switch support email** from `easylive1989@gmail.com` to `support@lorescape.app` | Landing Pages / Email | Trust signal. Takes 30 min with Cloudflare Email Routing. |
| 3 | **Embed the intro video** (`/videos/lorescape-intro.mp4`) on the landing page | Landing Pages / CRO | File already exists. Missing embed is a free conversion win. |
| 4 | **Run `/kai-email-system`** to design lifecycle emails | Email | Highest ROI gap. No emails = zero retention lever. |

---

## P1 — Fix This Month (high impact, medium effort)

| # | Fix | Module | Why |
|---|-----|--------|-----|
| 5 | **Add email capture** to landing page with lead magnet ("每週一則隱藏景點故事") | Email / CRO | Build an owned audience. Visitors who don't download are permanently lost without it. |
| 6 | **Add pricing section** to landing page | Landing Pages / CRO | Reduces download friction. Users want to know cost before committing. |
| 7 | **Add testimonials / user reviews** to landing page | Landing Pages / CRO | No social proof beyond unverified 50k claim. App store reviews = easiest source. |
| 8 | **Add FAQ section** to landing page | Landing Pages / CRO | Address: free tier? languages? offline? privacy? how AI works? |
| 9 | **Add "Free to download, try for free" CTA** alongside App Store buttons | CRO | Freemium framing increases download intent for subscription apps. |
| 10 | **Publish Reels** (actor content in `docs/ig/reels/actor/`) | Social / Content | Video is #1 reach driver on IG 2026. Assets exist but not published. |
| 11 | **Add link-in-bio strategy** (Linktree or native IG) | Social | Multiple CTAs: App Store + Play + web. Essential for IG traffic conversion. |
| 12 | **Run `/kai-content-calendar`** for IG content mix | Content / Social | Current posts are 1-format (daily story). Need angle variety: BTS, "did you know", story preview, user-facing hooks. |

---

## P2 — Fix This Quarter (medium impact)

| # | Fix | Module | Why |
|---|-----|--------|-----|
| 13 | **Start a blog or content section** at `lorescape.app/stories` or `lorescape.app/blog` | Content / SEO | Zero organic content = zero long-tail discovery. Repurpose daily story output as web content. |
| 14 | **Create YouTube channel** with story sample videos | Content | YouTube is #2 search engine. Travel + history content fits perfectly. |
| 15 | **Add AggregateRating JSON-LD** once app has 10+ reviews | Technical SEO | Star ratings in Google search results = higher CTR. |
| 16 | **Add `apple-itunes-app` meta tag** on landing page | Technical SEO | Enables Smart App Banner on iOS Safari. |
| 17 | **Run `/kai-surround-sound`** | SEO / AI Visibility | Ensure Lorescape appears in ChatGPT/Perplexity answers for "best AI travel app" queries. |
| 18 | **Expand sitemap with content pages** as blog grows | Technical SEO | Only 6 URLs indexed now. Content = indexable surface. |
| 19 | **Research iOS App Store link** and add to codebase | ASO | iOS URL missing from DownloadLink component — verify and add. |
| 20 | **Launch TikTok account** with 30-sec story clips | Social / Content | High-ROI for travel + history niche. Low production cost from existing story content. |

---

## P3 — Backlog (nice to have)

| # | Fix | Module | Why |
|---|-----|--------|-----|
| 21 | Build PR / press kit at `lorescape.app/press` | PR | For travel media outreach when product is more mature. |
| 22 | Consider re-enabling Threads publishing | Social | Threads growing in zh-TW market. Low effort via existing pipeline. |
| 23 | Add Core Web Vitals monitoring | Technical SEO | Google Fonts + CDN = potential LCP issue. Validate with PageSpeed Insights. |
| 24 | Add competitor comparison table on landing | Landing Pages | "Lorescape vs. traditional audio guide vs. Google Maps" — for high-intent visitors. |
| 25 | Run `/kai-growth-plan` for full GTM roadmap | Strategy | When channels are set up, get a structured growth plan. |
