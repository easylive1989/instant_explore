import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/data/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:flutter_test/flutter_test.dart';

const _place = Place(
  id: 'p1',
  name: 'Kinkaku-ji',
  address: '京都市北区金閣寺町1',
  location: PlaceLocation(latitude: 35.0, longitude: 135.7),
  tags: ['temple', 'historical'],
  photos: [],
  category: PlaceCategory.historicalCultural,
);

void main() {
  group('NarrationPromptBuilder', () {
    test('includes the hook title and teaser when a hook is provided', () {
      const hook = StoryHook(
        id: 'fire-1908',
        title: 'Fire of 1908',
        teaser: 'A kitchen spark almost burned down the temple...',
      );

      final prompt = NarrationPromptBuilder(
        place: _place,
        hook: hook,
        language: 'en-US',
      ).build();

      expect(prompt, contains('Fire of 1908'));
      expect(prompt, contains('A kitchen spark'));
    });

    test('falls back to "pick a thread" instruction when hook is null', () {
      final prompt = NarrationPromptBuilder(
        place: _place,
        language: 'en-US',
      ).build();

      expect(prompt, contains('No specific story angle'));
    });

    test('selects Traditional Chinese when language starts with zh', () {
      final prompt = NarrationPromptBuilder(
        place: _place,
        language: 'zh-TW',
      ).build();

      expect(prompt, contains('繁體中文'));
    });

    test('selects English for non-zh language codes', () {
      final prompt = NarrationPromptBuilder(
        place: _place,
        language: 'en-US',
      ).build();

      expect(prompt, contains('English'));
    });

    test('embeds place name, address, and tags', () {
      final prompt = NarrationPromptBuilder(
        place: _place,
        language: 'en-US',
      ).build();

      expect(prompt, contains(_place.name));
      expect(prompt, contains(_place.address));
      expect(prompt, contains('temple'));
    });
  });
}
