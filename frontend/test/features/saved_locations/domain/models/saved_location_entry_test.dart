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
    address: 'Test Address',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.5),
    tags: const ['tourist_attraction', 'point_of_interest'],
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
      expect(entry.address, 'Test Address');
      expect(entry.latitude, 25.0);
      expect(entry.longitude, 121.5);
      expect(entry.tags, ['tourist_attraction', 'point_of_interest']);
      expect(entry.categoryKey, 'historicalCultural');
      expect(entry.savedAt, isNotNull);
    });

    test('preserves photo data', () {
      const photo = PlacePhoto(
        url: 'https://example.com/photo.jpg',
        width: 800,
        height: 600,
        attributions: ['Author'],
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
      expect(restored.address, place.address);
      expect(restored.location.latitude, place.location.latitude);
      expect(restored.location.longitude, place.location.longitude);
      expect(restored.tags, place.tags);
      expect(restored.category, place.category);
    });

    test('reconstructs photos correctly', () {
      const photo = PlacePhoto(
        url: 'https://example.com/photo.jpg',
        width: 800,
        height: 600,
        attributions: ['Author'],
      );
      final place = _makePlace(photos: [photo]);
      final entry = SavedLocationEntry.fromPlace(place);
      final restored = entry.toPlace();

      expect(restored.photos.length, 1);
      expect(restored.photos.first.url, photo.url);
      expect(restored.photos.first.width, photo.width);
      expect(restored.photos.first.height, photo.height);
      expect(
        restored.photos.first.attributions,
        photo.attributions,
      );
    });
  });
}
