import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/story_deep_link_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
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
        child: const StoryDeepLinkScreen(locale: 'zh', date: '2026-07-01'),
        overrides: [
          dailyStoryByDateProvider((
            language: 'zh-TW',
            date: DateTime(2026, 7, 1),
          )).overrideWith((ref) async => _story()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('苦難聖母堂'), findsWidgets);
    },
  );
}
