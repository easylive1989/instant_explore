import 'package:context_app/features/daily_story/data/supabase_daily_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// `rowToStory` is a public static helper used by the repository to convert
// joined Supabase rows into DailyStory objects. Testing it directly proves
// that the row parser handles all the field shapes correctly (full / sparse
// card fields, partial place join, etc.) without spinning up a real client.

void main() {
  group('SupabaseDailyStoryRepository.rowToStory', () {
    test(
      'given a row with all card fields and joined place fields, '
      'when parsed, '
      'then DailyStory carries every value',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'zh-TW',
          'place_name': '羅馬競技場',
          'place_location': '義大利羅馬',
          'era': '公元 70-80 年',
          'story': 'p1\n\np2\n\np3',
          'image_url': null,
          'wikipedia_url': 'https://zh.wikipedia.org/wiki/Colosseum',
          'card_title': '血腥的盛宴',
          'card_title_sub': '從石灰岩堆砌的命運舞台',
          'card_paragraphs': ['p1', 'p2', 'p3'],
          'card_pull_quote': '「他們將死之人向您致敬」',
          'card_pull_quote_attrib': '── 蘇埃托尼烏斯，西元 121 年',
          'card_anno_roman': 'LXXX',
          'daily_story_places': {
            'card_location_en': 'COLOSSEUM',
            'card_city_ch': '羅馬',
            'card_city_en': 'Rome',
          },
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardTitle, '血腥的盛宴');
        expect(story.cardParagraphs, ['p1', 'p2', 'p3']);
        expect(story.cardLocationEn, 'COLOSSEUM');
        expect(story.cardCityCh, '羅馬');
        expect(story.cardCityEn, 'Rome');
      },
    );

    test(
      'given a row missing card fields and place join, '
      'when parsed, '
      'then card_* fields are null',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'en',
          'place_name': 'Colosseum',
          'place_location': 'Rome, Italy',
          'era': '70-80 CE',
          'story': 'A plain text story.',
          'image_url': 'https://example.com/img.jpg',
          'wikipedia_url': 'https://en.wikipedia.org/wiki/Colosseum',
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardTitle, isNull);
        expect(story.cardParagraphs, isNull);
        expect(story.cardLocationEn, isNull);
      },
    );

    test(
      'given a place join with some null city fields, '
      'when parsed, '
      'then nulls propagate without crashing',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'zh-TW',
          'place_name': '羅馬競技場',
          'place_location': '義大利羅馬',
          'era': '公元 70-80 年',
          'story': 'x',
          'image_url': null,
          'wikipedia_url': 'https://zh.wikipedia.org/wiki/Colosseum',
          'daily_story_places': {
            'card_location_en': null,
            'card_city_ch': '羅馬',
            'card_city_en': null,
          },
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.cardLocationEn, isNull);
        expect(story.cardCityCh, '羅馬');
        expect(story.cardCityEn, isNull);
      },
    );
  });
}
