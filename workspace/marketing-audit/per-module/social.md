# Social Media — Lorescape
**Score: 48/100 (D)**
**Source tier:** user_provided (codebase analysis) + missing_data (live metrics not available)

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| Instagram account exists | IG Business Account ID `17841402312650550` | user_provided |
| Launch post published | `docs/ig/ig-launch-caption.md` — strong narrative hook, 3-tier hashtag strategy | user_provided |
| Automated publishing pipeline | APScheduler + Meta API + Discord review bot for daily story posts | user_provided |
| Brand assets exist | `docs/ig/lorescape-ig-brand.png/svg` + lockup | user_provided |
| Reels content planned | `docs/ig/reels/actor/` — 5 character images prepared | user_provided |
| Meta API integration | `IG_USER_ID` + `META_PAGE_ACCESS_TOKEN` configured in backend | user_provided |
| IG insights tracking | `instagram_manage_insights` permission in token | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| Follower count unknown | No public IG handle found in codebase to observe. Can't score reach. | missing_data |
| Content mix is 1-dimensional | Daily story posts = one format. No Reels, no BTS, no UGC, no "angle reveal", no polls/questions. | P1 |
| Reels not published yet | Actor images exist but no Reels appear in published pipeline. Video content is the #1 reach driver on IG 2026. | P1 |
| No IG bio / profile link-in-bio strategy | No reference to Linktree, Milkshake, or smart link for multiple CTAs (App Store + Play + web) | P1 |
| Threads publishing removed | Noted in `social_publisher_setup.md` (removed 2026-05-29). Instagram-only = single platform risk. | P2 |
| No TikTok account | Target ICP is present on TikTok. Travel + history content format fits TikTok niche perfectly. | P2 |
| No Twitter/X strategy | Minimal priority, but travel and tech press audiences are still there. | P3 |
| No YouTube channel | Long-form story samples + "places with history" content would perform well on YouTube. | P2 |
| Engagement rate unknown | No data on likes / comments / saves / shares per post | missing_data |
