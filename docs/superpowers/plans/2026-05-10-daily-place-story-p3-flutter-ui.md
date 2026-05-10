# Daily Place Story — P3: Flutter UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking. Per project skill `flutter-widget-tests`: prefer widget tests over controller tests, BDD `given/when/then` naming, use fakes (not mocks), use `pumpScreen`/`pumpRouterApp`, and assert on raw `tr()` keys.

**Goal:** Add a "today's daily story" pinned card on the Explore home screen, plus a detail screen and a history list. Reads from the `daily_stories` Supabase table populated by P2's cron job. Language follows the app's current locale (zh-TW or en).

**Architecture:** New `lib/features/daily_story/` feature module mirroring the project's clean-architecture layout (`domain/`, `data/`, `presentation/`). One Riverpod-injected `DailyStoryRepository` interface with a Supabase implementation in production and an in-memory fake for tests. UI: a card widget on Explore, a detail screen, and a history screen. Routes go through `go_router` with `extra` payloads (matches existing pattern in `RouterConfig`).

**Tech Stack:** Flutter, `flutter_riverpod`, `go_router`, `easy_localization`, `supabase_flutter`, `cached_network_image`. Widget tests with `pumpRouterApp` + in-memory fake repo.

**Source spec:** `docs/superpowers/specs/2026-05-10-daily-place-story-design.md`
**Depends on:** P1 (schema + place list, PR #54 merged) and P2 (cron writes daily rows, PR #55). For development, P3 can use a manually inserted row in Supabase, or the in-memory fake during widget tests.

---

## File Structure

```
frontend/lib/features/daily_story/                           # NEW directory
├── data/
│   └── supabase_daily_story_repository.dart                  # NEW
├── domain/
│   ├── models/
│   │   └── daily_story.dart                                  # NEW
│   └── repositories/
│       └── daily_story_repository.dart                       # NEW (abstract)
├── presentation/
│   ├── controllers/
│   │   └── daily_story_providers.dart                        # NEW (FutureProviders)
│   ├── screens/
│   │   ├── daily_story_detail_screen.dart                    # NEW
│   │   └── daily_story_history_screen.dart                   # NEW
│   └── widgets/
│       └── daily_story_card.dart                             # NEW (Explore-home card)
└── providers.dart                                            # NEW (top-level wiring)

frontend/lib/features/explore/presentation/screens/
└── explore_screen.dart                                       # MODIFY (insert card at top)

frontend/lib/app/config/router_config.dart                    # MODIFY (add 2 routes)

frontend/assets/translations/{en,zh-TW}.json                  # MODIFY (i18n keys)

frontend/test/
├── fakes/
│   └── in_memory_daily_story_repository.dart                 # NEW
└── features/daily_story/
    ├── presentation/
    │   ├── widgets/daily_story_card_test.dart                # NEW
    │   └── screens/
    │       ├── daily_story_detail_screen_test.dart           # NEW
    │       └── daily_story_history_screen_test.dart          # NEW
    └── data/supabase_daily_story_repository_test.dart        # NEW (thin coverage)
```

**檔案分工原則**：
- Repository interface 在 domain，實作在 data — 對齊 `places_repository` / `saved_locations_repository`
- 每個 screen / widget 一個檔案 + 一個 widget test
- Riverpod providers 在 `providers.dart` 與 `presentation/controllers/daily_story_providers.dart`，前者放 repo 與全域注入，後者放 UI consumes 的 `FutureProvider`
- In-memory fake 放 `test/fakes/`，命名跟 `in_memory_saved_locations_repository.dart` 一致

---

## Task 1: Domain model

**Files:**
- Create: `frontend/lib/features/daily_story/domain/models/daily_story.dart`

- [ ] **Step 1: 建立 model**

```dart
import 'package:equatable/equatable.dart';

/// A daily-place story shown to the user once per day in their app language.
///
/// Mirrors a row in Supabase `public.daily_stories`. One day has one
/// `DailyStory` per supported language (zh-TW, en).
class DailyStory extends Equatable {
  /// Date this story was published / shown to users (Asia/Taipei calendar).
  final DateTime publishDate;

  /// Language tag matching the app locale: `zh-TW` or `en`.
  final String language;

  /// Localised place name (e.g. "羅馬競技場" or "Colosseum").
  final String placeName;

  /// Localised location string (e.g. "義大利羅馬" or "Rome, Italy").
  final String placeLocation;

  /// Approximate era of the story (e.g. "公元 70-80 年" or "70-80 CE").
  final String era;

  /// The story body itself (~300-500 chars).
  final String story;

  /// Optional image URL (Wikipedia thumbnail). May be null.
  final String? imageUrl;

  /// Wikipedia article URL in the matching language; falls back to en.
  final String wikipediaUrl;

  const DailyStory({
    required this.publishDate,
    required this.language,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    required this.story,
    required this.imageUrl,
    required this.wikipediaUrl,
  });

  @override
  List<Object?> get props => [
    publishDate,
    language,
    placeName,
    placeLocation,
    era,
    story,
    imageUrl,
    wikipediaUrl,
  ];
}
```

- [ ] **Step 2: Verify analyze passes**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/
```
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```
git add frontend/lib/features/daily_story/domain/models/daily_story.dart
git commit -m "feat(daily-story): add DailyStory domain model"
```

---

## Task 2: Repository interface

**Files:**
- Create: `frontend/lib/features/daily_story/domain/repositories/daily_story_repository.dart`

- [ ] **Step 1: 建立 abstract repository**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

abstract class DailyStoryRepository {
  /// Returns the most recent published story in [language] whose
  /// `publish_date` is on or before today (Asia/Taipei). Returns `null`
  /// if no row exists yet (e.g. the cron job hasn't run for the first time).
  Future<DailyStory?> fetchToday({required String language});

  /// Returns up to [limit] stories in [language] strictly older than
  /// [before], ordered by `publish_date` descending. Used for the history
  /// screen with simple "load more" pagination.
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  });
}
```

- [ ] **Step 2: Analyze**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/
```

- [ ] **Step 3: Commit**

```
git add frontend/lib/features/daily_story/domain/repositories/daily_story_repository.dart
git commit -m "feat(daily-story): add DailyStoryRepository interface"
```

---

## Task 3: Supabase repository implementation

**Files:**
- Create: `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart`

- [ ] **Step 1: 實作 Supabase repo**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDailyStoryRepository implements DailyStoryRepository {
  final SupabaseClient _client;

  SupabaseDailyStoryRepository(this._client);

  static const _table = 'daily_stories';

  @override
  Future<DailyStory?> fetchToday({required String language}) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('language', language)
        .order('publish_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('language', language)
        .lt('publish_date', _isoDate(before))
        .order('publish_date', ascending: false)
        .limit(limit);
    return rows.map(_fromRow).toList();
  }

  static DailyStory _fromRow(Map<String, dynamic> row) {
    return DailyStory(
      publishDate: DateTime.parse(row['publish_date'] as String),
      language: row['language'] as String,
      placeName: row['place_name'] as String,
      placeLocation: row['place_location'] as String,
      era: row['era'] as String,
      story: row['story'] as String,
      imageUrl: row['image_url'] as String?,
      wikipediaUrl: row['wikipedia_url'] as String,
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 2: Analyze**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/
```

- [ ] **Step 3: Commit**

```
git add frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart
git commit -m "feat(daily-story): add Supabase DailyStoryRepository implementation"
```

---

## Task 4: In-memory fake repository (for tests)

**Files:**
- Create: `frontend/test/fakes/in_memory_daily_story_repository.dart`

- [ ] **Step 1: 建立 fake**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';

/// In-memory fake repository for widget/integration tests.
///
/// Stories can be seeded via [seed]. `fetchToday` returns the latest matching
/// row by `publishDate`; `fetchHistory` returns rows strictly older than
/// `before`.
class InMemoryDailyStoryRepository implements DailyStoryRepository {
  final List<DailyStory> _stories = [];

  /// Throw on the next call (for testing error states). Cleared after one use.
  Object? errorOnNextCall;

  void seed(List<DailyStory> stories) {
    _stories
      ..clear()
      ..addAll(stories);
  }

  void clear() {
    _stories.clear();
  }

  @override
  Future<DailyStory?> fetchToday({required String language}) async {
    _maybeThrow();
    final matching = _stories.where((s) => s.language == language).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return matching.isEmpty ? null : matching.first;
  }

  @override
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  }) async {
    _maybeThrow();
    final matching = _stories
        .where(
          (s) => s.language == language && s.publishDate.isBefore(before),
        )
        .toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return matching.take(limit).toList();
  }

  void _maybeThrow() {
    final err = errorOnNextCall;
    if (err != null) {
      errorOnNextCall = null;
      throw err;
    }
  }
}
```

- [ ] **Step 2: Analyze**

```
cd frontend && fvm flutter analyze --fatal-infos test/fakes/in_memory_daily_story_repository.dart
```

- [ ] **Step 3: Commit**

```
git add frontend/test/fakes/in_memory_daily_story_repository.dart
git commit -m "test(daily-story): add in-memory daily story repository fake"
```

---

## Task 5: Providers (repository + today + history)

**Files:**
- Create: `frontend/lib/features/daily_story/providers.dart`

- [ ] **Step 1: 寫 providers**

```dart
import 'package:context_app/features/daily_story/data/supabase_daily_story_repository.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for daily stories. Override in tests with the in-memory fake.
final dailyStoryRepositoryProvider = Provider<DailyStoryRepository>((ref) {
  return SupabaseDailyStoryRepository(Supabase.instance.client);
});

/// Today's daily story for the current app language. `null` if no story
/// has been published yet (e.g. brand-new install + cron hasn't run).
final todayDailyStoryProvider = FutureProvider<DailyStory?>((ref) async {
  final language = ref.watch(currentLanguageProvider).code;
  final repo = ref.watch(dailyStoryRepositoryProvider);
  return repo.fetchToday(language: language);
});

/// History list — last 30 days strictly before today.
final dailyStoryHistoryProvider = FutureProvider<List<DailyStory>>((ref) async {
  final language = ref.watch(currentLanguageProvider).code;
  final repo = ref.watch(dailyStoryRepositoryProvider);
  // Use start-of-tomorrow so today's story is included via fetchToday only.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return repo.fetchHistory(language: language, before: today, limit: 30);
});
```

If `currentLanguageProvider` exposes a `Language` object, the `.code` accessor must produce strings like `zh-TW` and `en` (matches what the cron writes). Verify by checking
`lib/features/settings/presentation/controllers/language_provider.dart`.

- [ ] **Step 2: Analyze**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/
```

- [ ] **Step 3: Commit**

```
git add frontend/lib/features/daily_story/providers.dart
git commit -m "feat(daily-story): add Riverpod providers for today + history"
```

---

## Task 6: i18n keys

**Files:**
- Modify: `frontend/assets/translations/en.json`
- Modify: `frontend/assets/translations/zh-TW.json`

- [ ] **Step 1: 加 keys**

Append (preserving JSON structure — use a top-level `daily_story` object). For both files, add the key `"daily_story"` with the same shape; only the values differ.

`en.json` keys to add:
```json
"daily_story": {
  "card_label": "Today's Story",
  "card_cta": "Read",
  "card_loading": "Loading today's story…",
  "card_empty_title": "Today's story is being prepared",
  "card_empty_cta": "See past stories",
  "detail_title": "Today's Story",
  "detail_era_label": "Era",
  "detail_location_label": "Location",
  "detail_read_more_wikipedia": "Read more on Wikipedia",
  "detail_history_button": "Past stories",
  "history_title": "Past stories",
  "history_empty": "No past stories yet"
}
```

`zh-TW.json` values:
```json
"daily_story": {
  "card_label": "今日故事",
  "card_cta": "閱讀",
  "card_loading": "今日故事準備中…",
  "card_empty_title": "今日故事準備中",
  "card_empty_cta": "看過去的故事",
  "detail_title": "今日故事",
  "detail_era_label": "年代",
  "detail_location_label": "地點",
  "detail_read_more_wikipedia": "在 Wikipedia 閱讀更多",
  "detail_history_button": "歷史故事",
  "history_title": "歷史故事",
  "history_empty": "尚無歷史故事"
}
```

When adding, place the `daily_story` block alphabetically (most translation files in this project order keys alphabetically — check before placing).

- [ ] **Step 2: Verify JSON validity**

```
cd frontend && python3 -c "import json; json.load(open('assets/translations/en.json')); json.load(open('assets/translations/zh-TW.json')); print('valid')"
```
Expected: `valid`.

- [ ] **Step 3: Commit**

```
git add frontend/assets/translations/en.json frontend/assets/translations/zh-TW.json
git commit -m "feat(daily-story): add i18n keys for card, detail, history"
```

---

## Task 7: DailyStoryCard widget + tests (TDD)

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart`
- Create: `frontend/test/features/daily_story/presentation/widgets/daily_story_card_test.dart`

- [ ] **Step 1: 寫失敗的 widget test**

```dart
// frontend/test/features/daily_story/presentation/widgets/daily_story_card_test.dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/widgets/daily_story_card.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/in_memory_daily_story_repository.dart';
import '../../../../helpers/pump_app.dart';

DailyStory _story({
  String language = 'zh-TW',
  String placeName = '羅馬競技場',
  String? imageUrl,
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 11),
    language: language,
    placeName: placeName,
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: '這是故事內容...' * 10,
    imageUrl: imageUrl,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required InMemoryDailyStoryRepository repo,
  List<Object?>? extras,
}) async {
  final captured = extras ?? <Object?>[];
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: DailyStoryCard()),
      ),
      GoRoute(
        path: '/daily-story/detail',
        builder: (_, state) {
          captured.add(state.extra);
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
      GoRoute(
        path: '/daily-story/history',
        builder: (_, __) => const Scaffold(body: SizedBox(key: Key('history-stub'))),
      ),
    ],
    overrides: [dailyStoryRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DailyStoryCard', () {
    testWidgets(
      'given today\'s story is available, when the card loads, '
      'then place name, label and CTA are visible',
      (tester) async {
        final repo = InMemoryDailyStoryRepository()..seed([_story()]);
        await _pumpCard(tester, repo: repo);

        expect(find.text('羅馬競技場'), findsOneWidget);
        expect(find.text('daily_story.card_label'), findsOneWidget);
        expect(find.text('daily_story.card_cta'), findsOneWidget);
      },
    );

    testWidgets(
      'given no story exists yet, when the card loads, '
      'then the empty title and "see past stories" CTA are visible',
      (tester) async {
        final repo = InMemoryDailyStoryRepository();
        await _pumpCard(tester, repo: repo);

        expect(find.text('daily_story.card_empty_title'), findsOneWidget);
        expect(find.text('daily_story.card_empty_cta'), findsOneWidget);
      },
    );

    testWidgets(
      'given today\'s story is available, when the user taps the card, '
      'then the detail route is pushed with the story as extra',
      (tester) async {
        final story = _story();
        final repo = InMemoryDailyStoryRepository()..seed([story]);
        final extras = <Object?>[];
        await _pumpCard(tester, repo: repo, extras: extras);

        await tester.tap(find.text('羅馬競技場'));
        await tester.pumpAndSettle();

        expect(extras, [story]);
      },
    );

    testWidgets(
      'given no story exists, when the user taps the empty CTA, '
      'then the history route is pushed',
      (tester) async {
        final repo = InMemoryDailyStoryRepository();
        await _pumpCard(tester, repo: repo);

        await tester.tap(find.text('daily_story.card_empty_cta'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('history-stub')), findsOneWidget);
      },
    );
  });
}
```

- [ ] **Step 2: Run, verify failure (widget doesn't exist yet)**

```
cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_card_test.dart
```
Expected: file errors (widget not yet defined).

- [ ] **Step 3: 實作 widget**

```dart
// frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyStoryCard extends ConsumerWidget {
  const DailyStoryCard({super.key});

  static const _detailRoute = '/daily-story/detail';
  static const _historyRoute = '/daily-story/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStory = ref.watch(todayDailyStoryProvider);
    return asyncStory.when(
      loading: () => _LoadingCard(),
      error: (_, __) => _EmptyCard(onPressed: () => context.push(_historyRoute)),
      data: (story) {
        if (story == null) {
          return _EmptyCard(onPressed: () => context.push(_historyRoute));
        }
        return _StoryCard(
          story: story,
          onTap: () => context.push(_detailRoute, extra: story),
        );
      },
    );
  }
}

class _StoryCard extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily_story.card_label'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.placeName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.story,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'daily_story.card_cta'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 120,
        child: Center(child: Text('daily_story.card_loading'.tr())),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmptyCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'daily_story.card_empty_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPressed,
                child: Text('daily_story.card_empty_cta'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, verify pass**

```
cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_card_test.dart
```
Expected: 4 passed.

- [ ] **Step 5: Commit**

```
git add frontend/lib/features/daily_story/presentation/widgets/daily_story_card.dart \
        frontend/test/features/daily_story/presentation/widgets/daily_story_card_test.dart
git commit -m "feat(daily-story): add DailyStoryCard widget"
```

---

## Task 8: DailyStoryDetailScreen + tests (TDD)

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
- Create: `frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`

- [ ] **Step 1: 寫失敗的 widget test**

```dart
// frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _story() => DailyStory(
  publishDate: DateTime(2026, 5, 11),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: '這是完整故事內容。' * 20,
  imageUrl: null,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
);

Future<void> _pumpDetail(
  WidgetTester tester, {
  required DailyStory story,
}) async {
  await pumpRouterApp(
    tester,
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (_, __) => Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/daily-story/detail', extra: story),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/daily-story/detail',
        builder: (_, state) =>
            DailyStoryDetailScreen(story: state.extra as DailyStory),
      ),
      GoRoute(
        path: '/daily-story/history',
        builder: (_, __) => const Scaffold(body: SizedBox(key: Key('hist'))),
      ),
    ],
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DailyStoryDetailScreen', () {
    testWidgets(
      'given a story, when the screen loads, '
      'then place name, location, era, story body and Wikipedia button are visible',
      (tester) async {
        final story = _story();
        await _pumpDetail(tester, story: story);

        expect(find.text(story.placeName), findsOneWidget);
        expect(find.text(story.placeLocation), findsOneWidget);
        expect(find.text(story.era), findsOneWidget);
        // Story is long; check that a substring is present
        expect(find.textContaining('完整故事內容'), findsAtLeastNWidgets(1));
        expect(
          find.text('daily_story.detail_read_more_wikipedia'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given the screen is open, when the user taps the history button, '
      'then the history route is pushed',
      (tester) async {
        await _pumpDetail(tester, story: _story());

        await tester.tap(find.text('daily_story.detail_history_button'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('hist')), findsOneWidget);
      },
    );
  });
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: 實作 screen**

```dart
// frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyStoryDetailScreen extends StatelessWidget {
  final DailyStory story;
  const DailyStoryDetailScreen({super.key, required this.story});

  static const _historyRoute = '/daily-story/history';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('daily_story.detail_title'.tr()),
        actions: [
          TextButton(
            onPressed: () => context.push(_historyRoute),
            child: Text('daily_story.detail_history_button'.tr()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: story.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(story.placeName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            _MetaRow(
              label: 'daily_story.detail_location_label'.tr(),
              value: story.placeLocation,
            ),
            _MetaRow(
              label: 'daily_story.detail_era_label'.tr(),
              value: story.era,
            ),
            const SizedBox(height: 16),
            Text(story.story, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openWikipedia(context),
              icon: const Icon(Icons.open_in_new),
              label: Text('daily_story.detail_read_more_wikipedia'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWikipedia(BuildContext context) async {
    final uri = Uri.parse(story.wikipediaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, verify pass (2 passed)**

- [ ] **Step 5: Commit**

```
git add frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart \
        frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart
git commit -m "feat(daily-story): add DailyStoryDetailScreen"
```

---

## Task 9: DailyStoryHistoryScreen + tests (TDD)

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/screens/daily_story_history_screen.dart`
- Create: `frontend/test/features/daily_story/presentation/screens/daily_story_history_screen_test.dart`

- [ ] **Step 1: 寫失敗的 widget test**

```dart
// frontend/test/features/daily_story/presentation/screens/daily_story_history_screen_test.dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_history_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/in_memory_daily_story_repository.dart';
import '../../../../helpers/pump_app.dart';

DailyStory _story({
  required int dayOffset,
  String placeName = '景點',
}) {
  // Build a date strictly in the past so it qualifies as history.
  final past = DateTime.now().subtract(Duration(days: dayOffset + 1));
  return DailyStory(
    publishDate: DateTime(past.year, past.month, past.day),
    language: 'zh-TW',
    placeName: '$placeName-$dayOffset',
    placeLocation: '地點',
    era: '年代',
    story: '故事',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/X',
  );
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required InMemoryDailyStoryRepository repo,
  List<Object?>? extras,
}) async {
  final captured = extras ?? <Object?>[];
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: DailyStoryHistoryScreen()),
      ),
      GoRoute(
        path: '/daily-story/detail',
        builder: (_, state) {
          captured.add(state.extra);
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    ],
    overrides: [dailyStoryRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DailyStoryHistoryScreen', () {
    testWidgets(
      'given three past stories, when the screen loads, '
      'then each place name is rendered',
      (tester) async {
        final repo = InMemoryDailyStoryRepository()
          ..seed([
            _story(dayOffset: 0, placeName: 'A'),
            _story(dayOffset: 1, placeName: 'B'),
            _story(dayOffset: 2, placeName: 'C'),
          ]);
        await _pumpHistory(tester, repo: repo);

        expect(find.text('A-0'), findsOneWidget);
        expect(find.text('B-1'), findsOneWidget);
        expect(find.text('C-2'), findsOneWidget);
      },
    );

    testWidgets(
      'given no past stories, when the screen loads, '
      'then the empty placeholder is shown',
      (tester) async {
        final repo = InMemoryDailyStoryRepository();
        await _pumpHistory(tester, repo: repo);

        expect(find.text('daily_story.history_empty'), findsOneWidget);
      },
    );

    testWidgets(
      'given a list of stories, when the user taps an item, '
      'then the detail route is pushed with that story as extra',
      (tester) async {
        final story = _story(dayOffset: 0, placeName: 'A');
        final repo = InMemoryDailyStoryRepository()..seed([story]);
        final extras = <Object?>[];
        await _pumpHistory(tester, repo: repo, extras: extras);

        await tester.tap(find.text('A-0'));
        await tester.pumpAndSettle();

        expect(extras, [story]);
      },
    );
  });
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: 實作 screen**

```dart
// frontend/lib/features/daily_story/presentation/screens/daily_story_history_screen.dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DailyStoryHistoryScreen extends ConsumerWidget {
  const DailyStoryHistoryScreen({super.key});

  static const _detailRoute = '/daily-story/detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStories = ref.watch(dailyStoryHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text('daily_story.history_title'.tr())),
      body: asyncStories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text(e.toString())),
        data: (stories) {
          if (stories.isEmpty) {
            return Center(child: Text('daily_story.history_empty'.tr()));
          }
          return ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _HistoryTile(
                story: story,
                onTap: () => context.push(_detailRoute, extra: story),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const _HistoryTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(story.publishDate);
    return ListTile(
      onTap: onTap,
      title: Text(story.placeName),
      subtitle: Text(dateLabel),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
```

- [ ] **Step 4: Run, verify pass (3 passed)**

- [ ] **Step 5: Commit**

```
git add frontend/lib/features/daily_story/presentation/screens/daily_story_history_screen.dart \
        frontend/test/features/daily_story/presentation/screens/daily_story_history_screen_test.dart
git commit -m "feat(daily-story): add DailyStoryHistoryScreen"
```

---

## Task 10: Wire routes in router_config.dart

**Files:**
- Modify: `frontend/lib/app/config/router_config.dart`

- [ ] **Step 1: Add 2 routes**

Add the following two `GoRoute` entries inside the existing `routes:` list of `RouterConfig.createRouter` (place them after `/journey/success` for grouping):

```dart
GoRoute(
  path: '/daily-story/detail',
  name: 'daily_story_detail',
  builder: (context, state) {
    final story = state.extra as DailyStory;
    return DailyStoryDetailScreen(story: story);
  },
),
GoRoute(
  path: '/daily-story/history',
  name: 'daily_story_history',
  builder: (context, state) => const DailyStoryHistoryScreen(),
),
```

Add the matching imports at the top:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_history_screen.dart';
```

- [ ] **Step 2: Analyze + run all tests**

```
cd frontend && fvm flutter analyze --fatal-infos
fvm flutter test
```
Expected: no issues, full suite green (existing 395 + new daily-story tests).

- [ ] **Step 3: Commit**

```
git add frontend/lib/app/config/router_config.dart
git commit -m "feat(daily-story): wire detail + history routes"
```

---

## Task 11: Insert DailyStoryCard into ExploreScreen

**Files:**
- Modify: `frontend/lib/features/explore/presentation/screens/explore_screen.dart`

- [ ] **Step 1: Read the current ExploreScreen build tree**

`fvm flutter analyze` will catch import errors; here you need to find a sensible insertion point. The screen body is a `Column` inside `SafeArea`; the title/search row sits at the top, then comes the list/grid of places. Insert the `DailyStoryCard` between the title row and the place list (so it appears below the title but above the place results).

- [ ] **Step 2: Add import**

At the top of `explore_screen.dart`:

```dart
import 'package:context_app/features/daily_story/presentation/widgets/daily_story_card.dart';
```

- [ ] **Step 3: Insert the card**

Locate the body `Column` whose first child is `Padding(padding: ... fromLTRB(20,20,20,10), child: Column(... title row ...))`. Add `const DailyStoryCard()` as the *next* sibling — i.e., it becomes the second child of the main `Column`.

If there's currently another widget (e.g. category chips or a SizedBox spacer) right after the title block, insert the card immediately after that title block but BEFORE the chip strip / list area. If you cannot decide between two reasonable insertion points, pick the one that puts the card directly under the title row.

- [ ] **Step 4: Verify analyze + test**

```
cd frontend && fvm flutter analyze --fatal-infos
fvm flutter test
```
Expected: no issues. The existing `main_screen_test.dart` may need to override `dailyStoryRepositoryProvider` if it pumps the Explore screen — if it fails, add the override using a fresh `InMemoryDailyStoryRepository()`.

- [ ] **Step 5: Commit**

```
git add frontend/lib/features/explore/presentation/screens/explore_screen.dart frontend/test/features/main_screen_test.dart
git commit -m "feat(daily-story): show DailyStoryCard at top of Explore screen"
```

(If `main_screen_test.dart` didn't need changes, just include the explore screen file.)

---

## Task 12: Final sweep — analyze, test, manual smoke

- [ ] **Step 1: Full static analysis**

```
cd frontend && fvm flutter analyze --fatal-infos
```
Expected: `No issues found!`.

- [ ] **Step 2: Full test suite**

```
fvm flutter test
```
Expected: all tests pass. Compare count to baseline before P3 (≈395) — should now be 395 + ~12 new tests.

- [ ] **Step 3: Manual smoke (no real Supabase needed)**

Run the app pointing at production Supabase (same as you've been running):

```
cd frontend && fvm flutter run
```

Actions to verify visually:
1. Explore home shows the pinned card. If P2 cron has run for today, the card shows the story; otherwise, the empty placeholder shows.
2. Tap the card → detail screen renders with place name, era, location, full story, Wikipedia button.
3. Tap "歷史故事" / "Past stories" in the app bar → history screen.
4. Tap a row in the history → detail of that story.
5. Switch app language (Settings → language) → return to Explore → the card reloads in the new language.

Document any UI tweaks the user requests as separate commits — don't reshape inside this task.

- [ ] **Step 4: Open PR**

```
git push -u origin feat/daily-story-p3-flutter-ui
gh pr create --title "feat(daily-story): P3 Flutter UI" --body "..."
```

PR description:
- Summary: card on Explore + detail screen + history screen, reads `daily_stories` rows written by P2
- Tests: list new widget tests + count
- Manual smoke results

---

## Self-Review Checklist

- [ ] **Spec coverage**:
  - Card on Explore home (B layout) ✓ (Task 7 + 11)
  - Tap card → detail with image, name, location, era, full story, Wikipedia link ✓ (Task 8)
  - History page, infinite-or-paginated list ✓ (Task 9 — 30-row limit, simple to grow later)
  - Language follows app locale ✓ (Task 5 — `currentLanguageProvider`)
  - Anonymous Supabase read ✓ (uses existing `Supabase.instance.client` which already runs with anon key)
- [ ] **No placeholders**: every step has concrete code/commands.
- [ ] **Naming consistency**:
  - `DailyStory` model field names match across model/repo/UI/test
  - Provider names: `dailyStoryRepositoryProvider`, `todayDailyStoryProvider`, `dailyStoryHistoryProvider` — used the same in all referencing files
  - Route paths: `/daily-story/detail` and `/daily-story/history` — used in card, detail, history, router
  - i18n keys: all `daily_story.*` exist in both locale JSON files

## After P3

- Production smoke: confirm a real story renders end-to-end after P2's cron has fired at least once.
- Future enhancements (out of scope): infinite scroll on history, push notifications, per-user favourites, "a year ago today".
