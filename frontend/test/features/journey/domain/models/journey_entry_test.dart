import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JourneyEntry.create', () {
    test('creates entry with correct data when place has no photos', () {
      const place = Place(
        id: 'place-1',
        name: 'Test Place',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.historicalCultural,
      );

      const aspects = {NarrationAspect.historicalBackground};
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        id: 'test-id',
        place: place,
        aspects: aspects,
        content: content,
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
      expect(entry.narrationAspects, equals(aspects));
      expect(entry.language, equals(Language.traditionalChinese));
      expect(entry.id, isNotEmpty);
    });

    test(
      'creates entry with imageUrl from primaryPhoto when place has photos',
      () {
        const placePhoto = PlacePhoto(
          url: 'https://example.com/photo.jpg',
          widthPx: 800,
          heightPx: 600,
          authorAttributions: ['Author Name'],
        );

        const place = Place(
          id: 'place-2',
          name: 'Place With Photo',
          formattedAddress: 'Address 2',
          location: PlaceLocation(latitude: 25.0, longitude: 121.0),
          types: [],
          photos: [placePhoto],
          category: PlaceCategory.naturalLandscape,
        );

        const aspects = {NarrationAspect.geology};
        final content = NarrationContent.create(
          'Geology narration',
          language: Language.traditionalChinese,
        );

        final entry = JourneyEntry.create(
          id: 'test-id-2',
          place: place,
          aspects: aspects,
          content: content,
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
        expect(entry.narrationAspects, equals(aspects));
        expect(entry.language, equals(Language.traditionalChinese));
      },
    );

    test('preserves distinct IDs passed by caller', () {
      const place = Place(
        id: 'place-1',
        name: 'Place With Photo',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );

      const aspects = {NarrationAspect.historicalBackground};
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry1 = JourneyEntry.create(
        id: 'id-1',
        place: place,
        aspects: aspects,
        content: content,
        language: Language.traditionalChinese,
      );

      final entry2 = JourneyEntry.create(
        id: 'id-2',
        place: place,
        aspects: aspects,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry1.id, equals('id-1'));
      expect(entry2.id, equals('id-2'));
      expect(entry1.id, isNot(equals(entry2.id)));
    });
  });

  group('JourneyEntry JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      const place = Place(
        id: 'place-rt',
        name: 'Round Trip Place',
        formattedAddress: 'RT Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.historicalCultural,
      );

      const aspects = {NarrationAspect.historicalBackground};
      final content = NarrationContent.create(
        'Round trip text',
        language: Language.traditionalChinese,
      );

      final original = JourneyEntry.create(
        id: 'round-trip-id',
        place: place,
        aspects: aspects,
        content: content,
        language: Language.traditionalChinese,
      );

      final restored = JourneyEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.place.id, original.place.id);
      expect(restored.place.name, original.place.name);
      expect(restored.place.address, original.place.address);
      expect(restored.narrationContent.text, original.narrationContent.text);
      expect(restored.narrationAspects, original.narrationAspects);
      expect(restored.language, original.language);
    });

    test('fromJson uses language.code (not toString)', () {
      const place = Place(
        id: 'p1',
        name: 'Test',
        formattedAddress: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'Some narration text for testing.',
        language: Language.english,
      );
      final entry = JourneyEntry.create(
        id: 'lang-test-id',
        place: place,
        aspects: {NarrationAspect.historicalBackground},
        content: content,
        language: Language.english,
      );
      final json = entry.toJson();
      // language.code returns 'en-US', not 'Instance of Language'
      expect(json['language'], equals(Language.english.code));
    });
  });
}
