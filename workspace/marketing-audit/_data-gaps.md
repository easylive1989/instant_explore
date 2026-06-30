# Data Gaps — Lorescape Marketing Audit

**Audit mode:** `sales_external` — no live API access
**Date:** 2026-06-25

These gaps prevent scoring those dimensions. Connect data sources to unlock full scoring.

## Missing Data

| Metric | Source Needed | Impact |
|--------|--------------|--------|
| GSC clicks / impressions / CTR by keyword | GSC API (`sc-domain:lorescape.app`) | SEO score gap |
| GA4 sessions, bounce rate, time-on-page | GA4 property `514854947` | CRO / funnel score gap |
| App Store install count, rating, reviews | App Store Connect | ASO score gap |
| Google Play install count, rating, reviews | Play Console | ASO score gap |
| IG follower count, reach, engagement rate | Meta API (`IG_USER_ID: 17841402312650550`) | Social score gap |
| RevenueCat trial-to-paid conversion rate | RevenueCat dashboard | Revenue / CRO gap |
| RevenueCat MRR / churn | RevenueCat dashboard | Revenue health gap |
| Core Web Vitals (LCP, CLS, FID) | PageSpeed Insights (live site) | Technical SEO gap |
| Backlink profile / domain rating | Ahrefs / Semrush | Off-page SEO gap |
| Email list size | No email platform connected | Email score = N/A |
| Ad spend / ROAS | No ad platform active | Ads score = N/A |

## Claim Requiring Verification

| Claim | Location | Status |
|-------|---------|--------|
| "加入五萬名探索者" (Join 50,000 explorers) | `dictionaries.ts` — finalCTA.body | **Verify before publishing** — if aspirational, must be updated to reflect real user count or removed to avoid FTC/ASA risk |

## How to Close Gaps

Run the metrics skill to pull live data:
```bash
cd scripts && uv run python -m metrics.report --days 30
```

This pulls GSC + GA4 + IG data using existing service account credentials.
