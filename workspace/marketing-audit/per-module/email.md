# Email Marketing — Lorescape
**Score: 5/100 (F)**
**Source tier:** user_provided (codebase analysis)

Email is the highest-ROI retention channel for a subscription app. Currently not set up.

## Passing ✅

| Check | Evidence | Source |
|-------|---------|--------|
| Support contact exists | `/support` page with email link | user_provided |

## Issues ⚠️

| Check | Finding | Priority |
|-------|---------|---------|
| No email capture on landing page | No form, no lead magnet, no newsletter CTA. Visitors who don't download are permanently lost. | P0 |
| No email platform | No Loops, Mailchimp, SendGrid, Klaviyo, or any ESP found in codebase. | P0 |
| No onboarding email sequence | New subscribers get zero email nurturing. No "your first story" moment, no tips, no feature reveal. | P0 |
| No trial → paid conversion email | No email nudge when premium trial ends. Losing easy conversions. | P0 |
| No win-back / churn prevention | No re-engagement sequence for lapsed users. | P1 |
| No transactional emails | Subscription confirmation, receipt, and expiry emails not found. | P1 |
| Support email is personal Gmail | `easylive1989@gmail.com` is exposed publicly. Switch to `support@lorescape.app` or `hello@lorescape.app`. | P1 |
| No weekly/monthly newsletter | The daily story engine could power a weekly digest email ("5 stories from this week") — not utilized. | P2 |

## Recommendation

Run `/kai-email-system` to generate the full lifecycle email suite:
- Welcome sequence (3 emails)
- Feature reveal cadence
- Trial → premium nudge
- Win-back sequence
- Weekly story digest
