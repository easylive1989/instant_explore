import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _legacyStory() => DailyStory(
  publishDate: DateTime(2026, 5, 11),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: '這是完整故事內容。' * 20,
  imageUrl: null,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
);

DailyStory _cardStory() => DailyStory(
  publishDate: DateTime(2026, 5, 11),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: 'p1\n\np2\n\np3',
  imageUrl: null,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  cardTitle: '血腥的盛宴',
  cardTitleSub: '從石灰岩堆砌的命運舞台',
  cardParagraphs: const ['p1...', 'p2...', 'p3...'],
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
      'then place name, location, era and story body are visible',
      (tester) async {
        final story = _legacyStory();
        await _pumpDetail(tester, story: story);

        expect(find.text(story.placeName), findsOneWidget);
        expect(find.text(story.placeLocation), findsOneWidget);
        expect(find.text(story.era), findsOneWidget);
        expect(find.textContaining('完整故事內容'), findsAtLeastNWidgets(1));
        // Wikipedia button intentionally removed — story page should focus
        // entirely on the narrative.
        expect(
          find.text('daily_story.detail_read_more_wikipedia'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'given the screen is open, when the user taps the history button, '
      'then the history route is pushed',
      (tester) async {
        await _pumpDetail(tester, story: _legacyStory());

        await tester.tap(find.text('daily_story.detail_history_button'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('hist')), findsOneWidget);
      },
    );

    testWidgets(
      'given a story with full card fields, when the screen loads, '
      'then the card layout title and subtitle are shown',
      (tester) async {
        final story = _cardStory();
        await _pumpDetail(tester, story: story);

        expect(find.text('血腥的盛宴'), findsOneWidget);
        expect(find.text('從石灰岩堆砌的命運舞台'), findsOneWidget);
        // legacy meta rows should NOT appear in card layout
        expect(find.text('daily_story.detail_location_label'), findsNothing);
      },
    );
  });
}
