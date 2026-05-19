import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

const _hook = StoryHook(
  id: 'hook-1',
  title: 'The fire of 1908',
  teaser: 'A spark in the kitchen almost took this place down...',
);

void main() {
  group('JourneyEntry.create', () {
    test('creates entry with correct data when place has no photos', () {
      const place = Place(
        id: 'place-1',
        name: 'Test Place',
        address: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        tags: [],
        photos: [],
        category: PlaceCategory.historicalCultural,
      );

      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        id: 'test-id',
        place: place,
        content: content,
        hook: _hook,
        language: Language.traditionalChinese,
      );

      expect(
        entry.place,
        equals(
          const SavedPlace(
            id: 'place-1',
            name: 'Test Place',
            address: 'Test Address',
          ),
        ),
      );
      expect(entry.narrationContent, equals(content));
      expect(entry.storyHook, equals(_hook));
      expect(entry.language, equals(Language.traditionalChinese));
      expect(entry.id, isNotEmpty);
    });

    test(
      'creates entry with imageUrl from primaryPhoto when place has photos',
      () {
        const placePhoto = PlacePhoto(
          url: 'https://example.com/photo.jpg',
          width: 800,
          height: 600,
          attributions: ['Author Name'],
        );

        const place = Place(
          id: 'place-2',
          name: 'Place With Photo',
          address: 'Address 2',
          location: PlaceLocation(latitude: 25.0, longitude: 121.0),
          tags: [],
          photos: [placePhoto],
          category: PlaceCategory.naturalLandscape,
        );

        final content = NarrationContent.create(
          'Story narration',
          language: Language.traditionalChinese,
        );

        final entry = JourneyEntry.create(
          id: 'test-id-2',
          place: place,
          content: content,
          hook: _hook,
          language: Language.traditionalChinese,
        );

        expect(
          entry.place,
          equals(
            const SavedPlace(
              id: 'place-2',
              name: 'Place With Photo',
              address: 'Address 2',
              imageUrl: 'https://example.com/photo.jpg',
            ),
          ),
        );
        expect(entry.narrationContent, equals(content));
        expect(entry.storyHook, equals(_hook));
        expect(entry.language, equals(Language.traditionalChinese));
      },
    );

    test('preserves distinct IDs passed by caller', () {
      const place = Place(
        id: 'place-1',
        name: 'Place With Photo',
        address: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        tags: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );

      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry1 = JourneyEntry.create(
        id: 'id-1',
        place: place,
        content: content,
        language: Language.traditionalChinese,
      );

      final entry2 = JourneyEntry.create(
        id: 'id-2',
        place: place,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry1.id, equals('id-1'));
      expect(entry2.id, equals('id-2'));
      expect(entry1.id, isNot(equals(entry2.id)));
    });

    test('defaults tripId to null when omitted', () {
      const place = Place(
        id: 'p1',
        name: 'Test',
        address: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        tags: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'Some narration text for testing.',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        id: 'no-trip-id',
        place: place,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry.tripId, isNull);
    });

    test('attaches tripId when provided', () {
      const place = Place(
        id: 'p1',
        name: 'Test',
        address: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        tags: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'Some narration text for testing.',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        id: 'with-trip-id',
        place: place,
        content: content,
        language: Language.traditionalChinese,
        tripId: 'trip-123',
      );

      expect(entry.tripId, 'trip-123');
    });
  });

  group('JourneyEntry.fromJson legacy handling', () {
    test('restores null hook when the entry pre-dates story_hook', () {
      const place = Place(
        id: 'p-legacy',
        name: 'Legacy',
        address: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        tags: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'legacy text',
        language: Language.traditionalChinese,
      );
      final entry = JourneyEntry.create(
        id: 'legacy-id',
        place: place,
        content: content,
        language: Language.traditionalChinese,
      );

      final json = entry.toJson();
      // Simulate a legacy row that still has the old `narration_styles` list
      // but no story_hook key.
      json['narration_styles'] = ['historical_background'];

      final restored = JourneyEntry.fromJson(json);

      expect(restored.storyHook, isNull);
    });

    test('treats missing trip_id as null', () {
      const place = Place(
        id: 'p1',
        name: 'Test',
        address: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        tags: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'Some narration text for testing.',
        language: Language.traditionalChinese,
      );
      final entry = JourneyEntry.create(
        id: 'legacy-id',
        place: place,
        content: content,
        language: Language.traditionalChinese,
        tripId: 'will-be-removed',
      );
      final legacyJson = entry.toJson()..remove('trip_id');

      final restored = JourneyEntry.fromJson(legacyJson);

      expect(restored.tripId, isNull);
    });
  });
}
