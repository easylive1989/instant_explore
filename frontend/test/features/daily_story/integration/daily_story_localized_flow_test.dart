// Daily Story is one of the few features that switches its content
// based on the app language: the cron writes 'zh-TW' and 'en' rows
// and the providers pick whichever matches dbLanguageOf(currentLanguage).
// These tests pin the language-aware behaviour and the repository-error
// fallback so the Story tab never silently shows the wrong locale or
// crashes on a transient backend error.

import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/story_list_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/in_memory_daily_story_repository.dart';
import '../../../helpers/pump_app.dart';

DailyStory _story({
  required String language,
  required String placeName,
  DateTime? publishDate,
}) {
  return DailyStory(
    publishDate: publishDate ?? DateTime(2026, 5, 11),
    language: language,
    placeName: placeName,
    placeLocation: 'Test Location',
    era: 'AD 100',
    story: 'A long-enough story body. ' * 10,
    imageUrl: null,
    wikipediaUrl: 'https://example.com',
  );
}

Future<void> _pumpList(
  WidgetTester tester, {
  required InMemoryDailyStoryRepository repo,
  Locale locale = const Locale('zh', 'TW'),
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const StoryListScreen(),
      ),
      GoRoute(
        path: '/daily-story/detail',
        builder: (_, __) =>
            const Scaffold(body: SizedBox(key: Key('detail-stub'))),
      ),
    ],
    overrides: [dailyStoryRepositoryProvider.overrideWithValue(repo)],
    locale: locale,
  );
  for (var i = 0; i < 3; i += 1) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('Daily Story localized content', () {
    testWidgets(
      'given stories exist in both languages, when the locale is zh-TW, '
      'then the zh-TW story is rendered (not the English one)',
      (tester) async {
        final repo = InMemoryDailyStoryRepository()
          ..seed([
            _story(language: 'zh-TW', placeName: '羅馬競技場'),
            _story(language: 'en', placeName: 'Colosseum'),
          ]);

        await _pumpList(tester, repo: repo, locale: const Locale('zh', 'TW'));

        expect(find.text('羅馬競技場'), findsOneWidget);
        expect(find.text('Colosseum'), findsNothing);
      },
    );

    testWidgets(
      'given stories exist in both languages, when the locale is en, '
      'then the English story is rendered (not the zh-TW one)',
      (tester) async {
        final repo = InMemoryDailyStoryRepository()
          ..seed([
            _story(language: 'zh-TW', placeName: '羅馬競技場'),
            _story(language: 'en', placeName: 'Colosseum'),
          ]);

        await _pumpList(tester, repo: repo, locale: const Locale('en'));

        expect(find.text('Colosseum'), findsOneWidget);
        expect(find.text('羅馬競技場'), findsNothing);
      },
    );

    testWidgets(
      'given the repository throws on fetchLatest, when the list loads, '
      'then no crash occurs and the screen stays mounted',
      (tester) async {
        final repo = InMemoryDailyStoryRepository()
          ..errorOnNextCall = Exception('Supabase unreachable');

        await _pumpList(tester, repo: repo);

        expect(
          find.byType(StoryListScreen),
          findsOneWidget,
          reason: 'screen should surface the error without crashing',
        );
      },
    );
  });
}
