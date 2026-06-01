import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
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

DailyStory _cardStoryWithWikidata() => DailyStory(
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
  wikidataId: 'Q10285',
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
      'given a legacy story, when the screen loads, '
      'then the AppBar title shows the place name',
      (tester) async {
        final story = _legacyStory();
        await _pumpDetail(tester, story: story);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.title, isA<Text>());
        expect((appBar.title as Text).data, equals(story.placeName));
      },
    );

    testWidgets(
      'given a legacy story, when the screen loads, '
      'then location, era and story body are visible',
      (tester) async {
        final story = _legacyStory();
        await _pumpDetail(tester, story: story);

        expect(find.text(story.placeLocation), findsOneWidget);
        expect(find.text(story.era), findsOneWidget);
        expect(find.textContaining('完整故事內容'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'given the detail screen, when the screen renders, '
      'then no history navigation button is shown',
      (tester) async {
        await _pumpDetail(tester, story: _legacyStory());

        expect(
          find.text('daily_story.detail_history_button'),
          findsNothing,
          reason: 'history button was removed when Story tab became the entry',
        );
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
        expect(find.text('daily_story.detail_location_label'), findsNothing);
      },
    );

    testWidgets(
      'given a story with wikidataId, when the user taps 探索更多故事, '
      'then it navigates to /config with a wikidata-prefixed Place',
      (tester) async {
        Object? configExtra;
        await pumpRouterApp(
          tester,
          initialLocation: '/daily-story/detail',
          initialExtra: _cardStoryWithWikidata(),
          routes: [
            GoRoute(
              path: '/daily-story/detail',
              builder: (_, state) =>
                  DailyStoryDetailScreen(story: state.extra as DailyStory),
            ),
            GoRoute(
              path: '/config',
              builder: (_, state) {
                configExtra = state.extra;
                return const Scaffold(body: Center(child: Text('config-stub')));
              },
            ),
          ],
        );

        final cta = find.text('daily_story.explore_more');
        expect(cta, findsOneWidget);
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.text('config-stub'), findsOneWidget);
        expect(configExtra, isA<Place>());
        expect((configExtra! as Place).id, 'wikidata:Q10285');
      },
    );

    testWidgets(
      'given a story without wikidataId, when the screen renders, '
      'then the 探索更多故事 CTA is hidden',
      (tester) async {
        await _pumpDetail(tester, story: _cardStory());

        expect(find.text('daily_story.explore_more'), findsNothing);
      },
    );
  });
}
