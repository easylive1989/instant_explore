import 'package:context_app/features/explore/data/mappers/place_json_mapper.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceJsonMapper', () {
    const place = Place(
      id: 'wikidata:Q221716',
      name: '清水寺',
      address: '',
      location: PlaceLocation(latitude: 34.9948, longitude: 135.785),
      tags: ['Q5393308'],
      photos: [
        PlacePhoto(
          url: 'https://img/x.jpg',
          width: 400,
          height: 300,
          attributions: [],
        ),
      ],
      category: PlaceCategory.historicalCultural,
    );

    test('round-trips through JSON', () {
      final json = PlaceJsonMapper.toJson(place);
      final parsed = PlaceJsonMapper.fromJson(json);
      expect(parsed, place);
    });

    test('handles empty photos', () {
      final noPhotos = Place(
        id: place.id,
        name: place.name,
        address: place.address,
        location: place.location,
        tags: place.tags,
        photos: const [],
        category: place.category,
      );
      final json = PlaceJsonMapper.toJson(noPhotos);
      expect(PlaceJsonMapper.fromJson(json).photos, isEmpty);
    });
  });
}
