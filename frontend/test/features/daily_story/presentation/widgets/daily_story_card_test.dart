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
