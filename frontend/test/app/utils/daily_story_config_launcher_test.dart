import 'package:context_app/app/utils/daily_story_config_launcher.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _story({String? wikidataId, String? imageUrl}) => DailyStory(
  publishDate: DateTime(2026, 5, 25),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: 'x',
  imageUrl: imageUrl,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  wikidataId: wikidataId,
);

void main() {
  group('placeFromDailyStory', () {
    test(
      'given a story with wikidataId, '
      'when mapped, '
      'then Place.id is wikidata-prefixed with name/address/category',
      () {
        final place = placeFromDailyStory(_story(wikidataId: 'Q10285'));

        expect(place, isNotNull);
        expect(place!.id, 'wikidata:Q10285');
        expect(place.name, '羅馬競技場');
        expect(place.address, '義大利羅馬');
        expect(place.category, PlaceCategory.historicalCultural);
      },
    );

    test(
      'given a story with an imageUrl, '
      'when mapped, '
      'then the Place has one photo using that url',
      () {
        final place = placeFromDailyStory(
          _story(wikidataId: 'Q10285', imageUrl: 'https://x/y.jpg'),
        );

        expect(place!.photos, hasLength(1));
        expect(place.primaryPhoto?.url, 'https://x/y.jpg');
      },
    );

    test(
      'given a story without imageUrl, '
      'when mapped, '
      'then the Place has no photos',
      () {
        final place = placeFromDailyStory(_story(wikidataId: 'Q10285'));
        expect(place!.photos, isEmpty);
      },
    );

    test(
      'given a story without wikidataId, '
      'when mapped, '
      'then it returns null',
      () {
        expect(placeFromDailyStory(_story()), isNull);
      },
    );
  });
}
