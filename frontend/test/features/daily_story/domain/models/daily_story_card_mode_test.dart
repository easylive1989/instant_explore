import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story_card_mode.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _baseStory({
  String? cardTitle,
  String? cardTitleSub,
  List<String>? cardParagraphs,
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 25),
    language: 'zh-TW',
    placeName: '羅馬競技場',
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: 'p1\n\np2\n\np3',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
    cardTitle: cardTitle,
    cardTitleSub: cardTitleSub,
    cardParagraphs: cardParagraphs,
  );
}

void main() {
  group('DailyStory.hasCardLayout', () {
    test('returns true when title, sub, and 3 paragraphs are all present', () {
      final story = _baseStory(
        cardTitle: '血腥的盛宴',
        cardTitleSub: '副標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isTrue);
    });

    test('returns false when cardTitle is null', () {
      final story = _baseStory(
        cardTitleSub: '副標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardTitleSub is null', () {
      final story = _baseStory(
        cardTitle: '主標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardParagraphs is null', () {
      final story = _baseStory(cardTitle: '主標', cardTitleSub: '副標');
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardParagraphs has the wrong length', () {
      final story = _baseStory(
        cardTitle: '主標',
        cardTitleSub: '副標',
        cardParagraphs: ['only one'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardTitle is empty string', () {
      final story = _baseStory(
        cardTitle: '',
        cardTitleSub: '副標',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });

    test('returns false when cardTitleSub is empty string', () {
      final story = _baseStory(
        cardTitle: '主標',
        cardTitleSub: '',
        cardParagraphs: ['p1', 'p2', 'p3'],
      );
      expect(story.hasCardLayout, isFalse);
    });
  });
}
