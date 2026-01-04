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

      const aspect = NarrationAspect.historicalBackground;
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        userId: 'user-1',
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry.userId, equals('user-1'));
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
      expect(entry.narrationAspect, equals(aspect));
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

        const aspect = NarrationAspect.geology;
        final content = NarrationContent.create(
          'Geology narration',
          language: Language.traditionalChinese,
        );

        final entry = JourneyEntry.create(
          userId: 'user-2',
          place: place,
          aspect: aspect,
          content: content,
          language: Language.traditionalChinese,
        );

        expect(entry.userId, equals('user-2'));
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
        expect(entry.narrationAspect, equals(aspect));
        expect(entry.language, equals(Language.traditionalChinese));
      },
    );

    test('generates unique IDs for different entries', () {
      const place = Place(
        id: 'place-1',
        name: 'Place With Photo',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );

      const aspect = NarrationAspect.designConcept;
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry1 = JourneyEntry.create(
        userId: 'user-1',
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      final entry2 = JourneyEntry.create(
        userId: 'user-1',
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry1.id, isNot(equals(entry2.id)));
    });
  });
}
