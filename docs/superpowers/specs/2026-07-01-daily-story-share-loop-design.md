# Daily Story Share Loop — Design

Date: 2026-07-01
Status: Approved (design), pending implementation plan

## Goal

Build a **content growth loop** for Lorescape: a user shares a daily story as a
designed image with a Lorescape watermark + a link; a friend (who does not yet
have the app) sees it, opens the link, reads a teaser on the web, and downloads
the app. That new user then shares again — a self-reinforcing acquisition loop
that costs nothing per new user.

This is the P0 "share loop" item from the growth plan. It is the only channel
that keeps acquiring users without ongoing content production or ad spend.

## Scope decisions (locked)

1. **Surface: daily story only** (not live narration). Daily-story card material
   (cover image, `cardTitle`, hook, pull quote) is the most stable and easiest
   to render into a beautiful, consistent share image. Validate here first;
   extend to narration later if it works.
2. **Link type: Universal Link (deep link).** Same URL opens the app to that
   story if installed, otherwise opens a real web page. Chosen over a plain
   store link for the best conversion and a seamless installed-user experience.
3. **Web page depth: teaser + first section.** Cover + place + era + `cardTitle`
   + hook + first 1–2 paragraphs + pull quote, then download CTA. Preserves the
   download incentive while giving Google indexable content (doubles as the seed
   of the planned SEO loop / blog).

## Core architectural insight (drives phase ordering)

The loop acquires **people who do not have the app yet**. Therefore:

- **Phase 1 (app share) + Phase 2 (web landing) already make the loop fully
  functional.** A friend without the app taps the link → lands on a real web
  page with a teaser + download buttons.
- **Phase 3 (Universal Link into the app) only benefits the installed
  minority** who tap a friend's link. It is an enhancement, not a prerequisite
  for the loop to work.

So even if Phase 3 is never built, the acquisition loop works after Phase 2.
This keeps risk low and lets us validate cheaply.

## Reuse (important — de-risks the app work)

The "render a designed widget off-screen → capture to PNG → open the system
share sheet" pattern **already exists** in the codebase:

- `lib/features/journey/domain/services/journey_sharing_service.dart`
  (`JourneySharingService` — captures a card via `RepaintBoundary`, writes a
  temp PNG, calls `Share.shareXFiles`).
- `lib/features/journey/presentation/widgets/journey_sharing_card.dart`
  (`JourneySharingCard` — a 380px-wide off-screen card with hardcoded colors so
  the captured image looks identical across platforms/themes).

`share_plus: ^10.1.4` and `url_launcher: ^6.3.1` are already dependencies.
The daily-story share card mirrors this pattern (new widget + service, or a
generalized shared service). Note: the existing card uses the old Midnight Kyoto
dark palette; the daily-story share card should instead match the warm paper /
literary-serif / terracotta aesthetic of the daily-story reader.

## Data model

`lib/features/daily_story/domain/models/daily_story.dart` — `DailyStory` already
carries everything the card and web page need: `publishDate`, `language`,
`placeName`, `placeLocation`, `era`, `cardTitle`, `cardTitleSub`,
`cardParagraphs`, `cardPullQuote`, `cardPullQuoteAttrib`, `imageUrl`,
`imageAttribution`, `wikidataId`, `wikipediaUrl`.

Story identity = `(publish_date, language)`. One date = one place = one story per
language.

## URL scheme

`https://lorescape.app/<locale>/story/<publish_date>`
e.g. `https://lorescape.app/zh/story/2026-07-01`,
`https://lorescape.app/en/story/2026-07-01`.

The `<locale>` segment supplies the language; `<publish_date>` is the story key.
Share links carry UTM params, e.g. `?utm_source=story_share&utm_medium=app`.

Both apps use identifier `com.paulchwu.instantexplore` (iOS bundle id and
Android applicationId).

---

## Phase 1 — App: share the daily story as an image

**What ships:** a share button on the daily story detail screen that produces a
designed PNG (watermark + link) and opens the system share sheet.

- New `DailyStorySharingCard` widget — daily-story warm aesthetic; content from
  `DailyStory`: cover `imageUrl`, `placeName`/`placeLocation`, `cardTitle`, one
  hook line (`cardTitleSub` or `cardPullQuote`), **Lorescape logo watermark**,
  and the story URL (optionally as small text and/or QR).
- Share service — reuse the `JourneySharingService` render→PNG→share pattern
  (either a new `DailyStorySharingService` or generalize the existing one into a
  reusable card-capture helper; prefer generalizing if it stays simple).
- Entry point — add a share action to `DailyStoryDetailScreen`
  (`lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`,
  `DailyStoryDetailScreen({required this.story})`) AppBar `actions`.
- Share text includes the story URL with UTM.
- Analytics: `story_share_tapped` and `story_share_completed` (use the
  `share_plus` `ShareResult` to distinguish completed vs dismissed).

**Value:** immediately validates whether users share at all.

**Tests:** widget test that the card renders without overflow and includes the
watermark; manual verification of the share sheet on device.

---

## Phase 2 — Web: `/[locale]/story/[date]` landing page

**What ships:** a real web page for the shared link (teaser + download CTA), so
the loop works for people without the app.

- New Next.js dynamic route under the existing `[locale]` tree:
  `landing/src/app/[locale]/story/[date]/page.tsx`.
- Fetch the story from Supabase `daily_stories` (anonymous read). Landing does
  not currently use Supabase — add a read-only Supabase client (anon key) to
  landing. Confirm which `daily_stories` columns are anon-readable and add
  column-level `GRANT SELECT` where needed (follow the existing
  daily_story_places grant-contract convention).
- Render (teaser + first section): cover image, place, era, `cardTitle`, hook,
  first 1–2 paragraphs, pull quote, then App Store / Google Play buttons with
  UTM. Bilingual via the existing `[locale]` dictionaries.
- **Open Graph tags** (`og:image` = cover, `og:title`, `og:description`) so the
  shared link renders a rich preview card in IG / LINE / Messages — critical for
  click-through.
- Fallback: story not found / Supabase read fails → graceful page with a link to
  the app home and store buttons (never a hard 404 for a plausible date).

**Value:** completes the acquisition path for non-app users; produces
Google-indexable content (seeds the SEO loop). This `/story/<id>` template is the
prototype for the future blog.

**Tests:** page render test; OG tag snapshot; Supabase-read-failure fallback
test.

---

## Phase 3 — Universal Link: same URL opens the app to that story

**What ships:** for installed users, the shared link opens the app directly to
that story instead of the web page.

- iOS: add the Associated Domains entitlement `applinks:lorescape.app`; host
  `/.well-known/apple-app-site-association` (served as `application/json`, no
  file extension) with `appID = <TeamID>.com.paulchwu.instantexplore`.
- Android: add an `autoVerify` intent-filter for `lorescape.app` to the manifest;
  host `/.well-known/assetlinks.json` with package
  `com.paulchwu.instantexplore` and the release signing cert SHA-256 fingerprint.
- Routing: add a `go_router` route `/story/:date` that loads the `DailyStory` for
  that `date` + current locale, then shows `DailyStoryDetailScreen`. This needs a
  "load story by arbitrary date" read path (today's screen assumes the current
  day's story). Existing detail route is `/daily-story/detail`.
- Deep-link plumbing: handle cold-start and warm-start links (via `go_router`
  platform integration and/or the `app_links` package — no deep-link handling
  exists today).
- Fallback: story not found / unresolved → route to home.

**Value:** seamless in-app open for the installed minority.

**Tests:** on-device Universal Link cold/warm start; story-not-found fallback.

---

## Phasing rationale

Effort increases and marginal audience decreases across 1 → 2 → 3. The loop is
functional after Phase 2; Phase 3 is polish. Recommended build order is
1 → 2 → 3, and it is acceptable to pause after Phase 2.

## Known details to resolve during implementation

- Apple Team ID and Android release signing SHA-256 (needed for
  AASA / assetlinks).
- Exact set of anon-readable `daily_stories` columns + any `GRANT SELECT`
  migration for the web read path.
- Whether to generalize `JourneySharingService` or add a sibling service.
- Whether to include a QR code on the share card (nice-to-have, not required).

## Out of scope (YAGNI)

- Sharing live narration stories (future extension).
- A full web blog / story index (only the single `/story/<date>` template now).
- Deferred-deep-link attribution SDKs (e.g. Branch) — plain UTM is enough to
  validate.
