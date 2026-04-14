import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:flutter_test/flutter_test.dart';

Place _makePlace({
  String id = 'place-1',
  List<PlacePhoto> photos = const [],
}) {
  return Place(
    id: id,
    name: 'Test Place',
    formattedAddress: 'Test Address',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.5),
    rating: 4.5,
    userRatingCount: 200,
    types: const ['tourist_attraction', 'point_of_interest'],
    photos: photos,
    category: PlaceCategory.historicalCultural,
  );
}

void main() {
  group('SavedLocationEntry.fromPlace', () {
    test('creates entry with correct fields from Place', () {
      final place = _makePlace();
      final entry = SavedLocationEntry.fromPlace(place);

      expect(entry.placeId, 'place-1');
      expect(entry.name, 'Test Place');
      expect(entry.formattedAddress, 'Test Address');
      expect(entry.latitude, 25.0);
      expect(entry.longitude, 121.5);
      expect(entry.rating, 4.5);
      expect(entry.userRatingCount, 200);
      expect(entry.types, ['tourist_attraction', 'point_of_interest']);
      expect(entry.categoryKey, 'historicalCultural');
      expect(entry.savedAt, isNotNull);
    });

    test('preserves photo data', () {
      const photo = PlacePhoto(
        url: 'https://example.com/photo.jpg',
        widthPx: 800,
        heightPx: 600,
        authorAttributions: ['Author'],
      );
      final place = _makePlace(photos: [photo]);
      final entry = SavedLocationEntry.fromPlace(place);

      expect(entry.photosJson.length, 1);
      expect(entry.photosJson.first['url'], 'https://example.com/photo.jpg');
      expect(entry.photosJson.first['width_px'], 800);
      expect(entry.photosJson.first['height_px'], 600);
    });
  });

  group('SavedLocationEntry.toPlace', () {
    test('reconstructs Place from entry', () {
      final place = _makePlace();
      final entry = SavedLocationEntry.fromPlace(place);
      final restored = entry.toPlace();

      expect(restored.id, place.id);
      expect(restored.name, place.name);
      expect(restored.formattedAddress, place.formattedAddress);
      expect(restored.location.latitude, place.location.latitude);
      expect(restored.location.longitude, place.location.longitude);
      expect(restored.rating, place.rating);
      expect(restored.userRatingCount, place.userRatingCount);
      expect(restored.types, place.types);
      expect(restored.category, place.category);
    });

    test('reconstructs photos correctly', () {
      const photo = PlacePhoto(
        url: 'https://example.com/photo.jpg',
        widthPx: 800,
        heightPx: 600,
        authorAttributions: ['Author'],
      );
      final place = _makePlace(photos: [photo]);
      final entry = SavedLocationEntry.fromPlace(place);
      final restored = entry.toPlace();

      expect(restored.photos.length, 1);
      expect(restored.photos.first.url, photo.url);
      expect(restored.photos.first.widthPx, photo.widthPx);
      expect(restored.photos.first.heightPx, photo.heightPx);
      expect(restored.photos.first.authorAttributions, photo.authorAttributions);
    });
  });

  group('JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final place = _makePlace();
      final original = SavedLocationEntry.fromPlace(place);
      final restored = SavedLocationEntry.fromJson(original.toJson());

      expect(restored.placeId, original.placeId);
      expect(restored.name, original.name);
      expect(restored.formattedAddress, original.formattedAddress);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.rating, original.rating);
      expect(restored.userRatingCount, original.userRatingCount);
      expect(restored.types, original.types);
      expect(restored.categoryKey, original.categoryKey);
      expect(restored.savedAt, original.savedAt);
    });

    test('toJson/fromJson preserves photos through round-trip', () {
      const photo = PlacePhoto(
        url: 'https://example.com/photo.jpg',
        widthPx: 800,
        heightPx: 600,
        authorAttributions: ['Author'],
      );
      final place = _makePlace(photos: [photo]);
      final original = SavedLocationEntry.fromPlace(place);
      final restored = SavedLocationEntry.fromJson(original.toJson());

      expect(restored.photosJson.length, 1);
      expect(restored.photosJson.first['url'], 'https://example.com/photo.jpg');
    });

    test('handles null rating', () {
      const place = Place(
        id: 'no-rating',
        name: 'No Rating Place',
        formattedAddress: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final original = SavedLocationEntry.fromPlace(place);
      final restored = SavedLocationEntry.fromJson(original.toJson());

      expect(restored.rating, isNull);
      expect(restored.userRatingCount, isNull);
    });
  });

  group('Equatable', () {
    test('two entries with same placeId are equal', () {
      final place = _makePlace(id: 'same-id');
      final entry1 = SavedLocationEntry.fromPlace(place);
      final entry2 = SavedLocationEntry.fromPlace(place);

      expect(entry1, equals(entry2));
    });

    test('two entries with different placeId are not equal', () {
      final entry1 = SavedLocationEntry.fromPlace(_makePlace(id: 'id-1'));
      final entry2 = SavedLocationEntry.fromPlace(_makePlace(id: 'id-2'));

      expect(entry1, isNot(equals(entry2)));
    });
  });
}
