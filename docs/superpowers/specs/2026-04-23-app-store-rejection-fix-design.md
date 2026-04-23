# App Store Rejection Fix — Design

- **Date**: 2026-04-23
- **Submission**: e05d912c-09c9-445b-bb42-e57e9f1e61ef (version 20260417.0052.0)
- **Rejection date**: 2026-04-21
- **Apple guidelines cited**: 2.1 (info needed), 3.1.2(c) — subscriptions x2

## Context

Apple rejected the latest submission for three reasons. Two are about the
subscription paywall (`SubscriptionScreen`) and one is a metadata question
about third-party AI. This spec covers the remediation for all three.

### Current state audit

1. **Paywall** — `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`
   renders a title, three benefit rows, a Subscribe button, and a Restore
   button. It displays **no price, no billing period, no Terms of Use link,
   and no Privacy Policy link**. This is the root cause of both 3.1.2(c)
   citations (missing required information + billed amount not prominent
   because it doesn't exist in the UI at all).

2. **AI disclosure** — the app uses `FirebaseAI.vertexAI()` with model
   `gemini-2.5-flash` and Google Search grounding
   (`frontend/lib/features/narration/data/gemini_service.dart`). The prompt
   (`narration_prompt_builder.dart`) transmits public place metadata only
   (name, formatted address, category, types, rating). No account or device
   identifiers are sent.

3. **Legal URLs** — none exist in-app or on the landing page (`landing/src/components/Footer.tsx`
   has `href: "#"` placeholders). The product owner will deploy
   `https://lorescape.app/terms` and `https://lorescape.app/privacy` before
   resubmission.

4. **Subscription products** — RevenueCat is configured with a single
   entitlement `premium`. The paywall uses
   `offerings.current.availablePackages.first`. There is currently one
   monthly subscription product with no free trial and no introductory
   price. A yearly plan is planned for a future release but is out of
   scope for this fix.

5. **Existing design language** — the recent onboarding redesign
   (`onboarding_welcome_screen.dart`, commit d1bd9ee) established a
   "Midnight Kyoto" dark-mode brand moment with a radial electric-blue
   backdrop, stadium FilledButtons, w800 headlines with negative letter
   spacing, and small uppercase serial chips. The paywall must match this
   language so it reads as part of the same product.

## Non-goals

- Yearly plan UI — the design reserves room for multi-plan layout but ships
  single-plan only.
- Switching RevenueCat for `SubscriptionStoreView` (iOS-only SwiftUI) or
  any other store abstraction.
- Reworking the narration AI pipeline or its prompt.
- Unrelated cleanup of unused i18n keys (`subscription.day_pass`,
  `subscription.trip_pass`, etc.).

## Goals

1. Fix Guideline 3.1.2(c) — surface subscription length, billed amount,
   services provided, Terms of Use link, and Privacy Policy link inside
   the paywall.
2. Fix Guideline 3.1.2(c) — make the billed amount the most visually
   prominent pricing element.
3. Answer Guideline 2.1 questions truthfully in a document the team can
   paste into App Store Connect.
4. Match the Midnight Kyoto brand language so the paywall feels premium,
   not utilitarian.
5. Leave the architecture cleanly extensible for a future yearly plan
   without over-engineering for it now.

## Design overview

### Visual concept

The paywall reuses the Midnight Kyoto atmosphere already established on
the onboarding carousel: a radial electric-blue wash fades into
`backgroundDark`, text is w800 with tight tracking, CTAs are stadium
FilledButtons. The paywall's distinguishing element is a **glass-style
plan card** that makes the billed amount the unmistakable focal point.

The screen is locked to the Midnight Kyoto palette regardless of system
theme, mirroring onboarding — subscription is a brand moment.

### Screen layout (top to bottom)

```
┌──────────────────────────────────────────┐
│ [×]                                      │  ← close, top-left
│                                          │
│              ╭──────────╮                │
│              │  icon    │  ← 80×80, primary @ 0.2
│              ╰──────────╯                │     with blurred glow halo
│                                          │     behind (~120×120, primary @ 0.25)
│         PREMIUM · MEMBERSHIP             │  ← chip, 11sp, ls 1.8
│                                          │
│        解鎖無盡旅程                        │  ← headline, 30sp w800
│    每個轉角，都有一位 AI 旅伴               │  ← subheadline, 15sp
│                                          │
│   ┌────────────────────────────────┐     │
│   │ MONTHLY PLAN                    │    │  ← glass card
│   │                                 │    │
│   │ NT$90  / month                  │    │  ← 40sp w900 + 14sp w500
│   │ ───────────────────             │    │
│   │ ✦ Unlimited AI narrations       │    │
│   │ ✦ Ad-free listening             │    │
│   │ ✦ Route planning                │    │
│   │ ───────────────────             │    │
│   │ Auto-renews monthly. Cancel…    │    │  ← 11sp tertiary
│   └────────────────────────────────┘     │
│                                          │
│   ┌────────────────────────────────┐     │
│   │  🔓  Subscribe Now              │    │  ← stadium FilledButton
│   └────────────────────────────────┘     │
│         Restore Purchases                │  ← text button
│                                          │
│     Terms of Service · Privacy Policy    │  ← 12sp tertiary, underlined
└──────────────────────────────────────────┘
```

### Apple compliance mapping

| Apple requirement                                     | UI element                                                                |
|-------------------------------------------------------|---------------------------------------------------------------------------|
| Subscription length                                   | Plan card label `MONTHLY PLAN` + period `/ month` + auto-renew notice     |
| Content/services provided per period                  | Three ✦ bullets inside plan card (unlimited narrations, ad-free, routes)  |
| Price of subscription                                 | `NT$90` in plan card — 40sp w900, highest visual weight on screen         |
| Billed amount is most conspicuous pricing element     | No other prices, promos, trials, or calculations render anywhere on page  |
| Functional Terms of Use link                          | Footer link → `url_launcher` → `https://lorescape.app/terms`              |
| Functional Privacy Policy link                        | Footer link → `url_launcher` → `https://lorescape.app/privacy`            |

Because Approach A was chosen (no free trial, no intro price), there are
no subordinate pricing elements to wrangle — the billed amount is the
only price rendered, which satisfies the "most conspicuous" rule by
construction.

### Plan card specification

- Background: `LinearGradient(surfaceDarkCard → surfaceDark, 135°)`
- Border: 1px `AppColors.glassBorder` (white @ 10%)
- Corner radius: 24
- Padding: 20
- Shadow: `BoxShadow(color: primary @ 0.08, blurRadius: 40, offset: Offset(0, 12))`
- Typography
  - `MONTHLY PLAN`: 11sp, w600, letterSpacing 1.2, `textTertiaryDark`
  - `NT$90`: 40sp, w900, `textPrimaryDark`, baseline-aligned with period
  - `/ month`: 14sp, w500, `textSecondaryDark`
  - Bullets: 14sp `textPrimaryDark`; ✦ glyph in `AppColors.primary`
  - Auto-renew line: 11sp `textTertiaryDark`
- Dividers: 1px `AppColors.glassBorder`, 16 vertical spacing above/below

### Screen states

| State              | Plan card                                                           | Subscribe button      | Restore button |
|--------------------|---------------------------------------------------------------------|-----------------------|----------------|
| Loading offerings  | Skeleton: placeholder bars in price and bullet rows (no shimmer lib — use plain `AppColors.white10` containers) | Disabled, showing label text only | Enabled        |
| Offerings ready    | Rendered with `package.storeProduct.priceString`                    | Enabled               | Enabled        |
| Offerings error    | Error message + Retry text button in place of bullets               | Hidden                | Enabled        |
| Purchasing         | Rendered normally                                                   | Shows `AdaptiveProgressIndicator` inside button | Disabled |

### Micro-motion

- Headline + subheadline + plan card fade in with 16px upward slide,
  staggered 100ms, total ≤ 400ms. Use `AnimatedOpacity` +
  `AnimatedSlide`. No additional package required.

### Routing & navigation

No changes to `router_config.dart`. `SubscriptionScreen` continues to
pop `true` on successful purchase, `false`/no value on dismiss.

## Components and responsibilities

### New files

1. **`frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart`**
   Extract the existing private `_MidnightKyotoBackdrop` from
   `onboarding_welcome_screen.dart` into a shared widget. Both screens
   import from here. Public class: `MidnightKyotoBackdrop({required Widget child})`.

2. **`frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`**
   Public widget (imported by the widget test). Signature:

   ```dart
   class SubscriptionPlanCard extends StatelessWidget {
     const SubscriptionPlanCard({
       super.key,
       required this.state,
       this.onRetry,
     });

     final SubscriptionPlanCardState state;
     final VoidCallback? onRetry;
   }
   ```

   Where `SubscriptionPlanCardState` is a sealed/union-like type with
   three constructors: `.loading()`, `.error(String message)`,
   `.ready({required String priceString, required String periodLabel, required List<String> bullets, required String autoRenewNotice, required String planLabel})`.

3. **`frontend/lib/common/config/legal_urls.dart`**
   ```dart
   class LegalUrls {
     LegalUrls._();
     static const termsOfUse = 'https://lorescape.app/terms';
     static const privacyPolicy = 'https://lorescape.app/privacy';
   }
   ```

4. **`docs/app-review/2026-04-21-ai-disclosure-reply.md`**
   Text to paste into App Store Connect reply (see below).

### Modified files

1. **`frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`** — full refactor.
   State-machine: start in loading, call `Purchases.getOfferings()`, derive
   price string + period label from
   `current.availablePackages.first.storeProduct`. Show success state, or
   error state on failure. Keep existing purchase/restore flow. Add
   footer with Terms/Privacy links that call `url_launcher` with
   `LaunchMode.externalApplication`.

2. **`frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`** —
   replace private `_MidnightKyotoBackdrop` with import from
   `shared/widgets/midnight_kyoto_backdrop.dart`.

3. **`frontend/lib/features/subscription/domain/services/subscription_service.dart`** —
   add one method so the screen never has to import RevenueCat types:

   ```dart
   /// 取得目前可購買的方案資訊（含已本地化的價格字串）
   ///
   /// 若沒有任何 offerings 則回傳 null。
   Future<SubscriptionPlan?> getCurrentPlan();
   ```

4. **`frontend/lib/features/subscription/domain/models/subscription_plan.dart`** (new):

   ```dart
   class SubscriptionPlan {
     final String priceString;       // e.g. "NT$90", already localized by RC
     final SubscriptionPeriod period;
     const SubscriptionPlan({required this.priceString, required this.period});
   }

   enum SubscriptionPeriod { monthly, yearly }
   ```

5. **`frontend/lib/features/subscription/data/revenuecat_subscription_service.dart`** —
   implement `getCurrentPlan`: reads
   `offerings.current.availablePackages.first.storeProduct.priceString`
   and maps `packageType` (`MONTHLY` / `ANNUAL`) to `SubscriptionPeriod`.
   Returns `null` when `offerings.current` or the package list is empty.

6. **`frontend/assets/translations/en.json`** and **`zh-TW.json`** — add
   six new keys under `subscription`:

   | key                           | zh-TW                              | en                                                  |
   |-------------------------------|------------------------------------|-----------------------------------------------------|
   | `category_label`              | 高級 · 會員方案                     | PREMIUM · MEMBERSHIP                                |
   | `headline`                    | 解鎖無盡旅程                        | Unlock unlimited journeys                           |
   | `subheadline`                 | 每個轉角，都有一位 AI 旅伴            | AI guides that never stop at every corner           |
   | `plan_label`                  | 月訂閱                              | MONTHLY PLAN                                        |
   | `plan_period`                 | ／月                                | / month                                             |
   | `auto_renew_notice`           | 每月自動續訂，可隨時取消             | Auto-renews monthly. Cancel anytime.                |

   Existing keys (`subscription.terms`, `subscription.privacy`,
   `subscription.benefit_no_ads`, etc.) are reused.

## Data flow

```
SubscriptionScreen.initState
  └─ ref.read(subscriptionServiceProvider).getCurrentPlan()
       └─ RevenueCatSubscriptionService.getCurrentPlan()
            └─ Purchases.getOfferings()
            └─ offering.availablePackages.first.storeProduct
            └─ SubscriptionPlan(priceString, period)
  └─ setState(plan=…)  or  setState(error=…)

Subscribe tap
  └─ service.purchase()  (unchanged)

Restore tap
  └─ service.restorePurchases()  (unchanged)

Terms/Privacy tap
  └─ url_launcher.launchUrl(Uri.parse(LegalUrls.xxx), mode: externalApplication)
```

## Error handling

- `getCurrentPlan()` throws → screen shows error state with Retry. Retry
  calls the same service method.
- `url_launcher` returns `false` → show snackbar "Could not open link"
  (`common.error_prefix` + localized message). Use existing i18n key
  pattern.
- `purchase()` and `restorePurchases()` error handling: unchanged from
  existing code.

## Testing strategy

Widget tests under `frontend/test/features/subscription/`:

1. `subscription_plan_card_test.dart`
   - Given loading state, renders skeleton placeholders.
   - Given ready state, renders price string with font size strictly
     larger than period label and bullet text (Apple-compliance
     invariant check).
   - Given ready state, renders all provided bullets.
   - Given error state, shows error message and a retry button that
     invokes `onRetry`.

2. `subscription_screen_test.dart`
   - On mount, calls `service.getCurrentPlan` exactly once.
   - When plan loads, displays price string from the fake service.
   - Tapping "Terms of Service" invokes the injected launcher function
     with `LegalUrls.termsOfUse`. The screen takes a
     `Future<bool> Function(Uri)` parameter (defaulting to
     `url_launcher.launchUrl`) so tests can pass a fake launcher.
   - Tapping "Privacy Policy" invokes the injected launcher with
     `LegalUrls.privacyPolicy`.
   - Tapping "Subscribe Now" calls `service.purchase` and pops with
     `true` when result is premium.
   - Tapping "Restore Purchases" calls `service.restorePurchases`.
   - Error state shows retry and invoking it re-calls `getCurrentPlan`.

Adhere to the project's existing Flutter widget test conventions
(`flutter-widget-tests` skill: BDD naming, fake-over-mock, pump
helpers, interaction over static render).

Unit test under `frontend/test/features/subscription/data/`:

3. `revenuecat_subscription_service_test.dart` — add a test for
   `getCurrentPlan` that verifies package-type-to-period mapping. Only
   if the existing test harness already fakes `Purchases`; if not,
   skip this one and rely on widget tests.

## App Store Connect actions (non-code)

These must happen alongside code deployment. Documented in the plan so
the engineer has a checklist.

1. **App Description** (App Store Connect → App Information → App
   Description) — append:
   ```
   Terms of Use (EULA): https://lorescape.app/terms
   ```
2. **Privacy Policy URL** (App Information → Privacy Policy) — verify
   set to `https://lorescape.app/privacy`.
3. **App Review Notes** — paste the AI disclosure reply (below).

## AI disclosure reply (docs/app-review/2026-04-21-ai-disclosure-reply.md)

```markdown
### Guideline 2.1 — AI Disclosure

1. Does your app use any third-party AI for analysis of data?
   Yes.

2. What is the name of the third-party AI provider?
   Google Vertex AI (Gemini 2.5 Flash), accessed through the Firebase
   AI SDK (`firebase_ai` package).

3. List the types of data being transmitted to the third-party AI.
   Per narration request, the app sends:
   - Public place metadata sourced from the Google Places API: the
     place's name, formatted address, category, place types, and
     rating (when available).
   - A localized prompt template (English or Traditional Chinese)
     describing the desired narration style and length.

   The app does NOT transmit:
   - User account identifiers
   - Email addresses or names
   - Device identifiers
   - Photos, audio recordings, or camera input
   - Location coordinates or movement data
```

## Rollout

1. Merge to `master` with the code changes above.
2. Deploy `https://lorescape.app/terms` and `/privacy` pages (product
   owner, independent of code).
3. Update App Store Connect metadata fields listed above.
4. Bump iOS build number, submit a new build, paste the AI disclosure
   reply into App Review Notes.
