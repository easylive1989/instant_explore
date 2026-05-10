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
