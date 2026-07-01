import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/services/daily_story_share_url.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _story({required String language, required DateTime publishDate}) {
  return DailyStory(
    publishDate: publishDate,
    language: language,
    placeName: 'Colosseum',
    placeLocation: 'Rome, Italy',
    era: '70-80 CE',
    story: 'body',
    imageUrl: null,
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Colosseum',
  );
}

void main() {
  group('buildDailyStoryShareUrl', () {
    test('given zh-TW story, when built, then uses zh locale segment and '
        'yyyy-MM-dd date with UTM params', () {
      final url = buildDailyStoryShareUrl(
        _story(language: 'zh-TW', publishDate: DateTime(2026, 7, 1)),
      );
      expect(
        url,
        'https://lorescape.app/zh/story/2026-07-01'
        '?utm_source=story_share&utm_medium=app',
      );
    });

    test('given en story with single-digit month/day, when built, then '
        'date is zero-padded and locale segment is en', () {
      final url = buildDailyStoryShareUrl(
        _story(language: 'en', publishDate: DateTime(2026, 3, 5)),
      );
      expect(
        url,
        'https://lorescape.app/en/story/2026-03-05'
        '?utm_source=story_share&utm_medium=app',
      );
    });
  });
}
