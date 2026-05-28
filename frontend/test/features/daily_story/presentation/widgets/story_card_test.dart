import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/widgets/story_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _story({
  String placeName = '羅馬競技場',
  String story = '這是故事內容摘要',
  String? imageUrl,
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 11),
    language: 'zh-TW',
    placeName: placeName,
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: story,
    imageUrl: imageUrl,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  );
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('StoryCard', () {
    testWidgets(
      'given a story, when the card renders, '
      'then place name and story snippet are visible',
      (tester) async {
        await pumpScreen(
          tester,
          child: StoryCard(story: _story(), onTap: () {}),
        );

        expect(find.text('羅馬競技場'), findsOneWidget);
        expect(find.text('這是故事內容摘要'), findsOneWidget);
      },
    );

    testWidgets(
      'given a story, when the card renders, '
      'then it does NOT display the "today" label or CTA',
      (tester) async {
        await pumpScreen(
          tester,
          child: StoryCard(story: _story(), onTap: () {}),
        );

        expect(find.text('daily_story.card_label'), findsNothing);
        expect(find.text('daily_story.card_cta'), findsNothing);
      },
    );

    testWidgets(
      'given a story, when the user taps the card, '
      'then onTap is invoked',
      (tester) async {
        var taps = 0;
        await pumpScreen(
          tester,
          child: StoryCard(story: _story(), onTap: () => taps++),
        );

        await tester.tap(find.byType(StoryCard));
        await tester.pumpAndSettle();

        expect(taps, 1);
      },
    );
  });
}
