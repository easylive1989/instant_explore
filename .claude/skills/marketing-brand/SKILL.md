---
name: marketing-brand
description: Brand positioning workshop for Lorescape — define messaging framework, voice/tone, differentiation strategy, and taglines aligned to B2C AI travel-storyteller identity. Use when "brand positioning", "messaging framework", "brand voice", "how should we position ourselves", "differentiation", "tagline", "品牌定位", "品牌語氣", "差異化", or any request to define or refine brand identity and messaging.
---

# marketing-brand — Brand Positioning Workshop

Build a complete brand positioning system for Lorescape: messaging framework, voice/tone guidelines, competitive differentiation, and tagline options.

## Phase 0: Load Product Context

Read `MARKETING.md` from the **project root**. It has the product name, ICP, value proposition, monetization (App Store / Google Play / RevenueCat), brand voice, active channels, and Competitive Landscape.

Do NOT ask the user to describe the product — everything needed is in `MARKETING.md`.

---

## Phase 1 — Discovery

1. Read from `MARKETING.md`. Only ask about things not covered there:
   - Current tagline or positioning copy (if different from what's in MARKETING.md)
   - Any specific launch context, new feature, or new market this session is targeting
   - Tone adjustments requested (e.g., more playful, more academic)
2. If the user provides a URL (landing page, App Store listing), fetch and analyse the current copy.
3. Identify gaps: what competitors claim vs. the white space Lorescape can own.

Use MARKETING.md's **Competitive Landscape** section directly — do not invent competitor lists.

## Phase 2 — Analysis

1. Map the competitive landscape using MARKETING.md's direct/indirect competitors.
2. Identify the **white space** — positions no competitor owns.
   - Google Maps 語音導覽: functional but shallow storytelling
   - Rick Steves: deep but static, geography-limited, no AI
   - 景點附設語音導覽: location-locked, no free exploration
   - Wikipedia / Google 搜尋: text-only, no narrative, no voice
   - Podcast 旅遊節目: non-real-time, not location-triggered
   - **Lorescape's gap**: any location × any time × Wikipedia-grounded AI story × voice
3. Score current messaging against the Four U's framework:
   - **Unique**: Can only Lorescape say this?
   - **Useful**: Does it promise a clear outcome for the traveller?
   - **Ultra-specific**: Are there concrete details (e.g., "Wikipedia-grounded", "2–3 story angles")?
   - **Urgent**: Is there a reason to care now (e.g., "while you're standing there")?
4. Flag banned words or AI slop phrases in existing copy (check against MARKETING.md Brand Voice Don't list).

## Phase 3 — Produce

Build these deliverables:

### Messaging Framework

- **Positioning statement**: For [audience] who [need], Lorescape is the [category] that [key benefit] because [reason to believe].
- **Value propositions**: 3 pillars from MARKETING.md Differentiators, each with a headline + supporting proof point.
- **Elevator pitch**: 30-second version and 10-second version, using the MARKETING.md one-liner as the base.

### Voice & Tone Guidelines

Align to MARKETING.md Brand Voice (沉靜、知性、有溫度):

- 3 voice attributes with Do/Don't examples
- Tone shifts by context:
  - App Store listing copy
  - IG Reels caption
  - Landing page hero section
  - In-app onboarding

### Differentiation Map

Table comparing Lorescape vs direct/indirect competitors from MARKETING.md:

| Dimension | Lorescape | Google Maps 語音導覽 | Rick Steves | 景點附設導覽 | Wikipedia/Google |
|-----------|-----------|---------------------|-------------|-------------|-----------------|
| 覆蓋範圍 | | | | | |
| AI 即時生成 | | | | | |
| Wikipedia 事實驗證 | | | | | |
| 語音朗讀 | | | | | |
| 多故事角度 | | | | | |
| 定位觸發 | | | | | |
| 訂閱訪問 | | | | | |

Circle rows where Lorescape wins. Flag rows where a competitor leads.

### Tagline Options

- Generate 10 tagline candidates in both **zh-TW** and **English**.
- Score each on: memorability (1–4), clarity (1–4), differentiation (1–4).
- Recommend top 3 with rationale.
- Constraints: under 8 words per tagline; must align with "沉靜、知性、有溫度" voice; no superlatives ("最強", "最好").

## Phase 4 — Output

1. Deliver the full messaging framework as a structured document.
2. Run all produced copy through quality gates: 執行 marketing-gate.
3. Present the final package with scores and any flags.

## Constraints

- No banned Tier 1 words: leverage, utilize, synergy, innovative, etc.
- No AI slop phrases.
- No B2B / SaaS / sales-team framing — this is a B2C mobile app.
- Taglines must be under 8 words.
- All claims must be substantiable from MARKETING.md or codebase — no empty superlatives.
- Target Four U's score: 12+/16 on the positioning statement.
- Brand voice: 沉靜、知性、有溫度 — never exaggerated marketing tone.
