import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _legacyStory() => DailyStory(
  publishDate: DateTime(2026, 7, 1),
  language: 'en',
  placeName: 'Colosseum',
  placeLocation: 'Rome, Italy',
  era: '70-80 CE',
  story: 'A great amphitheatre.',
  imageUrl: null,
  wikipediaUrl: 'https://en.wikipedia.org/wiki/Colosseum',
);

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DailyStoryDetailScreen share button', () {
    testWidgets(
      'given a story, when the detail screen renders, then a share '
      'button is present in the app bar',
      (tester) async {
        await pumpScreen(
          tester,
          child: DailyStoryDetailScreen(story: _legacyStory()),
        );

        expect(
          find.byKey(const Key('daily_story_share_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given the share button, when tapped, then no exception is thrown',
      (tester) async {
        await pumpScreen(
          tester,
          child: DailyStoryDetailScreen(story: _legacyStory()),
        );

        await tester.tap(find.byKey(const Key('daily_story_share_button')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
