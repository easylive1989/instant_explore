# On-Page SEO — Lorescape
**Score: 58/100 (F)**
**Source tier:** user_provided (codebase analysis)

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| Title tags (zh+en) | "Lorescape — 讓每一處風景，開口說它的故事" / "Let every place tell its story" | user_provided |
| Meta descriptions | Distinct, 140–160 char, keyword-rich per locale | user_provided |
| Keywords defined | zh: 7 terms; en: 6 terms — both in metadata | user_provided |
| OG title + description | Set per locale in `generateMetadata` | user_provided |
| JSON-LD schema | SoftwareApplication type, valid | user_provided |
| hreflang | zh-Hant/en/x-default set correctly | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| Zero long-tail keyword pages | No content targeting "AI tour guide app", "travel audio guide", "history of [city]" etc. Only home page is indexed for keywords. | P0 |
| Keyword volume unknown | zh keywords ("AI 導覽", "旅行說書人") — no search volume data. May be too niche with zero monthly searches. | missing_data |
| English keyword set weak | "travel storyteller" has low search volume. Should target "AI audio guide app", "AI travel guide", "history of [landmark]". | P1 |
| No H1 heading visible in code | Heading structure not auditable from static analysis — needs live site check. | P2 |
| No internal linking | Only 6 pages, minimal inter-page link opportunities. | P3 |
| Image alt tags mixed quality | Some images have descriptive alts (e.g., "台中朝聖宮"), others generic (e.g., "Park trail"). | P3 |
| GSC data not available | Can't verify which queries are driving impressions or what CTR looks like | missing_data |
