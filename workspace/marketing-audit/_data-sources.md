# Data Sources — Lorescape Marketing Audit

**Audit mode:** `sales_external` (user-provided codebase access)
**Audit date:** 2026-06-25
**Auditor:** Kai CMO Harness

## Sources Used

| Source | Tier | Files / Artifacts | Retrieved |
|--------|------|-------------------|-----------|
| README.md | user_provided | `/README.md` | 2026-06-25 |
| MARKETING.md | user_provided | `/MARKETING.md` | 2026-06-25 |
| Landing page copy (zh/en) | user_provided | `landing/src/i18n/dictionaries.ts` | 2026-06-25 |
| Landing page components | user_provided | `landing/src/components/*.tsx` | 2026-06-25 |
| Next.js config | user_provided | `landing/next.config.mjs` | 2026-06-25 |
| SEO / sitemap / robots | user_provided | `landing/src/app/sitemap.ts`, `robots.ts` | 2026-06-25 |
| Metadata / locale layout | user_provided | `landing/src/app/[locale]/layout.tsx` | 2026-06-25 |
| JSON-LD structured data | user_provided | `landing/src/components/SiteHtml.tsx` | 2026-06-25 |
| GA4 property ID | user_provided | `landing/.env.production` (G-TCYSEZX8T6, property 514854947) | 2026-06-25 |
| Instagram auto-publisher | user_provided | `docs/social_publisher_setup.md`, `backend/src/lorescape_backend/social/` | 2026-06-25 |
| IG launch caption | user_provided | `docs/ig/ig-launch-caption.md` | 2026-06-25 |
| Subscription plans | user_provided | `docs/subscription-add-weekly-yearly-setup.md` | 2026-06-25 |
| Metrics setup | user_provided | `docs/metrics-setup.md` | 2026-06-25 |
| Google Play URL | public_observed | `landing/src/components/DownloadLink.tsx` | 2026-06-25 |
| Support email | user_provided | `landing/src/app/(legal)/support/page.tsx` | 2026-06-25 |

## Not Connected (Data Gaps — see _data-gaps.md)
- GSC data (configured but not queried)
- GA4 data (configured but not queried)
- IG follower count / engagement rate
- App Store / Google Play install counts, ratings
- RevenueCat conversion / churn data
