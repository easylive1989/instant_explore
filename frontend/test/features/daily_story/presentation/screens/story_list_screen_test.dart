import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/story_list_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/in_memory_daily_story_repository.dart';
import '../../../../helpers/pump_app.dart';

DailyStory _story({
  required DateTime publishDate,
  String language = 'zh-TW',
  String placeName = '羅馬競技場',
}) {
  return DailyStory(
    publishDate: publishDate,
    language: language,
    placeName: placeName,
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: '$placeName 的故事內容…',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required InMemoryDailyStoryRepository repo,
  List<Object?>? capturedExtras,
}) async {
  final captured = capturedExtras ?? <Object?>[];
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const StoryListScreen(),
      ),
      GoRoute(
        path: '/daily-story/detail',
        builder: (_, state) {
          captured.add(state.extra);
          return const Scaffold(body: SizedBox(key: Key('detail-stub')));
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

  group('StoryListScreen', () {
    testWidgets(
      'given latest and history stories exist, when the screen loads, '
      'then all stories render with latest first',
      (tester) async {
        final latest = _story(
          publishDate: DateTime(2026, 5, 28),
          placeName: '故事 A',
        );
        final older1 = _story(
          publishDate: DateTime(2026, 5, 27),
          placeName: '故事 B',
        );
        final older2 = _story(
          publishDate: DateTime(2026, 5, 26),
          placeName: '故事 C',
        );
        final repo = InMemoryDailyStoryRepository()
          ..seed([latest, older1, older2]);

        await _pumpScreen(tester, repo: repo);

        expect(find.text('故事 A'), findsOneWidget);
        expect(find.text('故事 B'), findsOneWidget);
        expect(find.text('故事 C'), findsOneWidget);

        // Latest should be at the top: its tile centre is higher than older.
        final latestY = tester.getCenter(find.text('故事 A')).dy;
        final olderY = tester.getCenter(find.text('故事 B')).dy;
        expect(latestY, lessThan(olderY));
      },
    );

    testWidgets(
      'given no stories exist at all, when the screen loads, '
      'then the empty state message is shown',
      (tester) async {
        final repo = InMemoryDailyStoryRepository();

        await _pumpScreen(tester, repo: repo);

        expect(find.text('story.list_empty'), findsOneWidget);
      },
    );

    testWidgets(
      'given a story is in the list, when the user taps it, '
      'then the detail route receives that story as extra',
      (tester) async {
        final story = _story(
          publishDate: DateTime(2026, 5, 28),
          placeName: '羅馬競技場',
        );
        final repo = InMemoryDailyStoryRepository()..seed([story]);
        final extras = <Object?>[];

        await _pumpScreen(tester, repo: repo, capturedExtras: extras);

        await tester.tap(find.text('羅馬競技場'));
        await tester.pumpAndSettle();

        expect(extras, [story]);
      },
    );
  });
}
