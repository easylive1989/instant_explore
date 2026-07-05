# CRO — Lorescape
**Score: 55/100 (F)**
**Source tier:** user_provided (codebase analysis) — GA4 funnel data not available

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| Clear primary CTA | App Store / Google Play buttons in hero | user_provided |
| Dual CTA placement | Buttons in hero AND final CTA section | user_provided |
| Download click events tracked | `sendGAEvent("event", "download_click", {...})` in DownloadLink | user_provided |
| Strong hero copy | Differentiated, emotionally resonant | user_provided |
| Social proof claim exists | "Join 50,000 explorers" in final CTA | user_provided (⚠️ verify) |
| Scroll-based section reveal | 4 features highlighted in sequence before final CTA | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| **⚠️ "50,000 explorers" claim** | If this number is not real, it's a trust liability. Must verify or remove. | **P0** |
| No pricing information | Visitors can't evaluate cost/value before committing to download. Significant friction for consideration stage. | P1 |
| No free trial CTA | "Free" isn't surfaced as a CTA on landing. "Try free" or "Free to download" would increase download intent. | P1 |
| No video demo | `lorescape-intro.mp4` exists but isn't embedded. A 30-second app walkthrough video could double conversions. | P1 |
| No testimonials | No user quotes, star ratings, or press mentions. Social proof is a critical trust signal pre-download. | P1 |
| No FAQ section | Objections (language support, offline use, data privacy, how AI works) are not addressed. | P1 |
| No email capture | Visitors not ready to download are lost. No second chance to convert. | P1 |
| Download buttons conditionally hidden | `showDownloadLinks` flag controls button visibility. Ensure this is always `true` in production. | P2 |
| No urgency / scarcity | No limited-time offer, launch pricing, or early-adopter framing. | P2 |
| Conversion funnel unknown | Without GA4 data: landing → App Store click → install → subscription conversion rates are all unknown. | missing_data |
