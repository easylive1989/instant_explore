# Daily Story Share Loop — Phase 3 (Universal Link) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the shared URL `https://lorescape.app/<locale>/story/<date>` open the Lorescape app directly to that story when the app is installed (Universal Links on iOS, App Links on Android); non-installed users still get the Phase 2 web page.

**Architecture:** Host Apple App Site Association (AASA) and Android `assetlinks.json` on lorescape.app (Firebase Hosting, via the landing's `public/.well-known/`). Declare the association natively (iOS Associated Domains entitlement + `FlutterDeepLinkingEnabled`; Android `autoVerify` intent-filter). In Flutter, add a `/:locale/story/:date` go_router route whose loader fetches the story by date and shows `DailyStoryDetailScreen` (falling back to home when absent). Requires a new repository `fetchByDate`.

**Tech Stack:** Flutter/Dart (`go_router`, `flutter_riverpod`, `fvm`), Next.js static export (`landing/public`), Firebase Hosting (`firebase.json`), iOS entitlements/Info.plist, AndroidManifest.

## Global Constraints

- Both platforms' identifier: `com.paulchwu.instantexplore`. Apple Team ID: `T9UXT366P9` → AASA appID `T9UXT366P9.com.paulchwu.instantexplore`.
- Associated domain / host: `lorescape.app`. Deep-link path shape (matches Phase 1 share URL + Phase 2 web route): `/<locale>/story/<date>`, locale ∈ {`zh`,`en`}, date `yyyy-MM-dd`.
- Locale→DB language: `zh`→`zh-TW`, `en`→`en` (mirror `dbLanguageOf` in `frontend/lib/features/daily_story/providers.dart`).
- Flutter: run `fvm flutter analyze --fatal-infos` after each change; lines ≤ 80; follow feature-first layering.
- Web: `.well-known` files are served from `landing/public/.well-known/` (Next copies `public/` → `out/`). `firebase.json` currently has `ignore: ["**/.*"]` which EXCLUDES `.well-known` from deploy — this MUST be fixed or App Links break.
- The AASA file (`apple-app-site-association`, no extension) must be served with `Content-Type: application/json` and over HTTPS with no redirect.
- The loop already works after Phase 2; Phase 3 is an enhancement for installed users. Never break the web fallback.

## Known value (OBTAINED)

- **Android Play App Signing SHA-256** = `61:F0:29:DC:66:95:EC:DD:71:52:97:DA:F4:CB:7E:A1:2D:AB:19:A1:E9:EE:8F:0D:C0:74:95:C6:F0:AF:D5:B1` (read from Play Console → App signing key certificate, the key Google re-signs with — correct for App Links). Baked into `assetlinks.json` in Task 1.

---

### Task 1: Host AASA + assetlinks + fix Firebase deploy

**Files:**
- Create: `landing/public/.well-known/apple-app-site-association`
- Create: `landing/public/.well-known/assetlinks.json`
- Modify: `firebase.json` (repo root)

**Interfaces:**
- Produces: the two association files served at `https://lorescape.app/.well-known/…` after deploy.

- [ ] **Step 1: Create `landing/public/.well-known/apple-app-site-association`** (JSON, no file extension)

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "T9UXT366P9.com.paulchwu.instantexplore",
        "paths": ["/zh/story/*", "/en/story/*"]
      }
    ]
  }
}
```

- [ ] **Step 2: Create `landing/public/.well-known/assetlinks.json`**

Replace the fingerprint placeholder with the real Play App Signing SHA-256 before deploy.

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.paulchwu.instantexplore",
      "sha256_cert_fingerprints": ["61:F0:29:DC:66:95:EC:DD:71:52:97:DA:F4:CB:7E:A1:2D:AB:19:A1:E9:EE:8F:0D:C0:74:95:C6:F0:AF:D5:B1"]
    }
  }
]
```

- [ ] **Step 3: Fix `firebase.json`** so `.well-known` deploys and the AASA has the right content type

Change the `ignore` array to drop `"**/.*"` (which excludes `.well-known`), and add a `Content-Type` header for the extensionless AASA file. The `hosting` block becomes:

```json
{
  "hosting": {
    "public": "landing/out",
    "ignore": [
      "firebase.json",
      "**/node_modules/**"
    ],
    "headers": [
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [
          { "key": "Content-Type", "value": "application/json" }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      },
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|avif|ico)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      },
      {
        "source": "**/*.html",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=300, s-maxage=600" }
        ]
      }
    ],
    "cleanUrls": true,
    "trailingSlash": false
  }
}
```

- [ ] **Step 4: Verify the files survive the build**

Run: `cd landing && SUPABASE_URL=x SUPABASE_ANON_KEY=x npm run build || true` then `ls -la out/.well-known/`
Expected: build may fail at the Supabase story fetch (no real env) — that's fine; what matters is that `next` copies `public/` early, so confirm `out/.well-known/apple-app-site-association` and `out/.well-known/assetlinks.json` exist. If the build aborts before copying `public/`, instead verify by `cp`-ing conceptually: the files exist under `landing/public/.well-known/` and Next's static export always emits `public/` verbatim into `out/`. Confirm the two files are present under `landing/public/.well-known/`.

- [ ] **Step 5: Commit**

```bash
git add landing/public/.well-known/apple-app-site-association \
        landing/public/.well-known/assetlinks.json firebase.json
git commit -m "feat(landing): host AASA + assetlinks for universal links"
```

---

### Task 2: iOS Associated Domains + deep linking

**Files:**
- Modify: `frontend/ios/Runner/Runner.entitlements`
- Modify: `frontend/ios/Runner/Info.plist`

- [ ] **Step 1: Add the associated-domains entitlement** to `Runner.entitlements` (inside the top-level `<dict>`, alongside the existing keys)

```xml
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:lorescape.app</string>
	</array>
```

- [ ] **Step 2: Enable Flutter deep linking** in `Info.plist` (add inside the top-level `<dict>`)

```xml
	<key>FlutterDeepLinkingEnabled</key>
	<true/>
```

- [ ] **Step 3: Verify plist/entitlements are valid XML**

Run: `plutil -lint frontend/ios/Runner/Runner.entitlements frontend/ios/Runner/Info.plist`
Expected: both `OK`.

- [ ] **Step 4: Commit**

```bash
git add frontend/ios/Runner/Runner.entitlements frontend/ios/Runner/Info.plist
git commit -m "feat(ios): associated domains + deep linking for lorescape.app"
```

---

### Task 3: Android App Links intent-filter

**Files:**
- Modify: `frontend/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add an autoVerify intent-filter** to the main `<activity>` (`.MainActivity`), immediately after the existing `LAUNCHER` intent-filter

```xml
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" android:host="lorescape.app"
                    android:pathPrefix="/zh/story" />
                <data android:scheme="https" android:host="lorescape.app"
                    android:pathPrefix="/en/story" />
            </intent-filter>
```

- [ ] **Step 2: Verify the manifest builds**

Run: `cd frontend && fvm flutter analyze --fatal-infos` (analyze passes; a full `assembleDebug` is optional here)
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add frontend/android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): app links intent-filter for lorescape.app"
```

---

### Task 4: Repository `fetchByDate`

**Files:**
- Modify: `frontend/lib/features/daily_story/domain/repositories/daily_story_repository.dart`
- Modify: `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart`
- Modify: `frontend/lib/features/daily_story/providers.dart`
- Test: `frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart` (add a case, mirroring the existing file's harness)

**Interfaces:**
- Produces:
  - `Future<DailyStory?> fetchByDate({required String language, required DateTime date})` on `DailyStoryRepository` + Supabase impl.
  - `final dailyStoryByDateProvider = FutureProvider.family<DailyStory?, ({String language, DateTime date})>(...)`.

- [ ] **Step 1: Add the abstract method** to `daily_story_repository.dart`

```dart
  /// Returns the story published on [date] in [language], or `null` if none
  /// exists (or the date is future-dated and hidden by RLS). Used by the
  /// `/story/:date` deep link to open a specific day's story.
  Future<DailyStory?> fetchByDate({
    required String language,
    required DateTime date,
  });
```

- [ ] **Step 2: Write the failing test** in `supabase_daily_story_repository_test.dart` (mirror the file's existing setup — it stubs the Supabase client/query builder the same way for `fetchLatest`; replicate that pattern for `fetchByDate`)

```dart
  test('fetchByDate queries language + publish_date and maps the row', () async {
    final row = _sampleRow(publishDate: '2026-07-01', language: 'zh-TW');
    final client = _clientReturning([row]); // reuse the file's helper
    final repo = SupabaseDailyStoryRepository(client);

    final story = await repo.fetchByDate(
      language: 'zh-TW',
      date: DateTime(2026, 7, 1),
    );

    expect(story, isNotNull);
    expect(story!.publishDate, DateTime(2026, 7, 1));
    expect(story.language, 'zh-TW');
  });

  test('fetchByDate returns null when no row matches', () async {
    final client = _clientReturning(<Map<String, dynamic>>[]);
    final repo = SupabaseDailyStoryRepository(client);

    final story = await repo.fetchByDate(
      language: 'en',
      date: DateTime(2026, 1, 1),
    );

    expect(story, isNull);
  });
```

If the existing file exposes its Supabase double under different helper names, use those; the two assertions (maps a matching row; null on empty) are the contract.

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart`
Expected: FAIL — `fetchByDate` not defined.

- [ ] **Step 4: Implement `fetchByDate`** in `supabase_daily_story_repository.dart` (uses the existing `_table`, `_select`, `rowToStory`, `_isoDate`)

```dart
  @override
  Future<DailyStory?> fetchByDate({
    required String language,
    required DateTime date,
  }) async {
    final rows = await _client
        .from(_table)
        .select(_select)
        .eq('language', language)
        .eq('publish_date', _isoDate(date))
        .limit(1);
    if (rows.isEmpty) return null;
    return rowToStory(rows.first);
  }
```

- [ ] **Step 5: Add the provider** to `providers.dart`

```dart
/// The daily story published on a specific [date] in a DB [language]
/// string (e.g. `'zh-TW'`). Backs the `/story/:date` deep link.
final dailyStoryByDateProvider =
    FutureProvider.family<DailyStory?, ({String language, DateTime date})>(
      (ref, key) async {
        final repo = ref.watch(dailyStoryRepositoryProvider);
        return repo.fetchByDate(language: key.language, date: key.date);
      },
    );
```

- [ ] **Step 6: Run the test to verify it passes + analyze**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart && fvm flutter analyze --fatal-infos lib/features/daily_story`
Expected: PASS; no issues. (Add `fetchByDate` to any in-memory fake repository the analyzer flags as no longer implementing the interface — search `implements DailyStoryRepository` under `test/` and add the method there too.)

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/daily_story/domain/repositories/daily_story_repository.dart \
        frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart \
        frontend/lib/features/daily_story/providers.dart \
        frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart
git commit -m "feat(daily-story): fetchByDate for story deep link"
```

---

### Task 5: `/:locale/story/:date` route + deep-link loader screen

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/screens/story_deep_link_screen.dart`
- Modify: `frontend/lib/app/config/router_config.dart`
- Test: `frontend/test/features/daily_story/presentation/screens/story_deep_link_screen_test.dart`

**Interfaces:**
- Consumes: `dailyStoryByDateProvider` (Task 4), `DailyStoryDetailScreen`.
- Produces: `StoryDeepLinkScreen({required String locale, required String date})`; a `GoRoute(path: '/:locale/story/:date', ...)`.

**Behavior:** map `locale` (`zh`/`en`) → DB language; parse `date` (`yyyy-MM-dd`); if locale/date invalid → redirect home. Watch `dailyStoryByDateProvider`. Loading → centered spinner. Error or `null` data → post-frame `context.go('/')` (the web already served content; in-app we just send them home). Data → `DailyStoryDetailScreen(story: story)`.

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/story_deep_link_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _story() => DailyStory(
  publishDate: DateTime(2026, 7, 1),
  language: 'zh-TW',
  placeName: '苦難聖母堂',
  placeLocation: '耶路撒冷',
  era: '1881',
  story: '正文',
  imageUrl: null,
  wikipediaUrl: 'https://x',
);

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets(
    'given a valid deep link with a published story, when loaded, '
    'then the daily story detail is shown',
    (tester) async {
      await pumpScreen(
        tester,
        const StoryDeepLinkScreen(locale: 'zh', date: '2026-07-01'),
        overrides: [
          dailyStoryByDateProvider((language: 'zh-TW', date: DateTime(2026, 7, 1)))
              .overrideWith((ref) async => _story()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('苦難聖母堂'), findsWidgets);
    },
  );
}
```

If `pumpScreen`'s signature differs (check `test/helpers/pump_app.dart`), adapt the override wiring but keep the assertion: a found story renders `DailyStoryDetailScreen` (its AppBar shows `placeName`).

- [ ] **Step 2: Run to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/story_deep_link_screen_test.dart`
Expected: FAIL — `StoryDeepLinkScreen` undefined.

- [ ] **Step 3: Implement `story_deep_link_screen.dart`**

```dart
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Resolves a `/:locale/story/:date` universal link to the matching daily
/// story and shows [DailyStoryDetailScreen]. Falls back to home when the
/// link is malformed or the story does not exist.
class StoryDeepLinkScreen extends ConsumerWidget {
  final String locale;
  final String date;

  const StoryDeepLinkScreen({
    super.key,
    required this.locale,
    required this.date,
  });

  static bool _validLocale(String l) => l == 'zh' || l == 'en';

  static DateTime? _parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedDate = _parseDate(date);
    if (!_validLocale(locale) || parsedDate == null) {
      return _goHome(context);
    }
    final language = locale == 'zh' ? 'zh-TW' : 'en';
    final story = ref.watch(
      dailyStoryByDateProvider((language: language, date: parsedDate)),
    );
    return story.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _goHome(context),
      data: (value) {
        if (value == null) return _goHome(context);
        return DailyStoryDetailScreen(story: value);
      },
    );
  }

  Widget _goHome(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/');
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
```

- [ ] **Step 4: Register the route** in `router_config.dart` — add this `GoRoute` to the top-level `routes` list (after `/daily-story/detail`). Add the import for `StoryDeepLinkScreen`.

```dart
        GoRoute(
          path: '/:locale/story/:date',
          name: 'story_deep_link',
          builder: (context, state) => StoryDeepLinkScreen(
            locale: state.pathParameters['locale']!,
            date: state.pathParameters['date']!,
          ),
        ),
```

- [ ] **Step 5: Run the test to verify it passes + analyze**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/story_deep_link_screen_test.dart && fvm flutter analyze --fatal-infos lib/app/config/router_config.dart lib/features/daily_story/presentation/screens/story_deep_link_screen.dart`
Expected: PASS; no issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/screens/story_deep_link_screen.dart \
        frontend/lib/app/config/router_config.dart \
        frontend/test/features/daily_story/presentation/screens/story_deep_link_screen_test.dart
git commit -m "feat(daily-story): /:locale/story/:date deep link route"
```

---

### Task 6: Verify + manual on-device test

**Files:** none (verification only).

- [ ] **Step 1: Full Flutter gate**

Run: `cd frontend && fvm flutter analyze --fatal-infos && fvm flutter test`
Expected: analyze clean; all tests pass.

- [ ] **Step 2: Manual verification (requires deploy + real devices)** — record results, no commit

Prereqs: deploy the landing (so `https://lorescape.app/.well-known/apple-app-site-association` and `assetlinks.json` are live) and install a build of the app on each device.
- **AASA reachable:** `curl -I https://lorescape.app/.well-known/apple-app-site-association` returns 200, `content-type: application/json`, no redirect. Same for `/.well-known/assetlinks.json`.
- **iOS:** on a device with the app installed, open `https://lorescape.app/zh/story/<a real past date>` from Notes/Messages (not typed in Safari) → the app opens to that story. (Universal Links require a fresh install after the entitlement change.)
- **Android:** `adb shell pm get-app-links com.paulchwu.instantexplore` shows `lorescape.app: verified`; tapping the link opens the app to the story. (Verification can take a few minutes after install.)
- **Fallback:** a device WITHOUT the app opens the same link → the Phase 2 web page (unchanged).

- [ ] **Step 3: No commit** (verification only). Log any follow-ups as new tasks.

---

## Known details / follow-ups

- **Play App Signing SHA-256** must replace the placeholder in `assetlinks.json` before the Android link verifies (USER-PROVIDED, see top).
- The landing must be redeployed for the `.well-known` files to go live; the daily-publish auto-trigger (from the freshness work) will do this on the next publish, or run Deploy Landing manually once now.
- iOS testing requires a build whose provisioning profile includes the Associated Domains capability (the entitlement is declared; ensure the App ID has "Associated Domains" enabled in the Apple Developer portal).

## Self-review notes

- Spec coverage: Phase 3 spec bullets — iOS Associated Domains + AASA (Tasks 1–2), Android App Links + assetlinks (Tasks 1, 3), `go_router` `/story/:date` with load-by-date (Tasks 4–5), cold/warm-start handling (Info.plist FlutterDeepLinkingEnabled + go_router native deep-link support, Task 2 + 5), fallback to home when absent (Task 5) — each maps to a task.
- Type consistency: `fetchByDate({language, date})` and `dailyStoryByDateProvider((language, date))` defined in Task 4 are consumed unchanged in Task 5. AASA/assetlinks path shape (`/<locale>/story/<date>`) matches the route pattern and the Phase 1/2 URL.
- No placeholders except the deliberately USER-PROVIDED Android SHA-256, which is called out explicitly in Global Constraints and Task 1.
