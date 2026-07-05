# Technical SEO — Lorescape
**Score: 72/100 (C)**
**Source tier:** user_provided (codebase analysis)

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| sitemap.xml configured | `landing/src/app/sitemap.ts` — 6 URLs | user_provided |
| robots.txt configured | `landing/src/app/robots.ts` — allow all, sitemap linked | user_provided |
| HTTPS (implied by Firebase Hosting) | Firebase + Cloudflare stack | user_provided |
| hreflang alternates | `layout.tsx` — `zh-Hant: /zh`, `en: /en`, `x-default: /` | user_provided |
| Canonical URLs | Per-locale canonical set in `generateMetadata` | user_provided |
| OG + Twitter card | Both set in `generateMetadata` per locale | user_provided |
| JSON-LD SoftwareApplication | `SiteHtml.tsx` — valid schema markup | user_provided |
| Static export = fast HTML | `next.config.mjs` — `output: "export"` | user_provided |
| Meta description (zh+en) | `dictionaries.ts` — distinct per locale | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| No content pages indexed | Only 6 URLs in sitemap (home zh/en + legal). No blog, no feature pages, no place pages. Zero long-tail keyword surface. | P1 |
| Static export limits | `output: "export"` prevents ISR, API routes, dynamic OG images, and server-side personalization | P3 |
| Core Web Vitals unknown | No PageSpeed Insights data available. Google Fonts + Material Symbols loaded from CDN = potential LCP risk | missing_data |
| Backlink profile unknown | No DR/backlink data available | missing_data |
| GSC impressions / CTR unknown | Configured but not queried | missing_data |
| No structured data for reviews/ratings | App has no AggregateRating schema | P2 |
| No App meta tags | No `apple-itunes-app` or `google-play-app` meta tags for app deep-linking from web | P2 |
