import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Fake [PlacesRepository] that returns seeded results.
class FakePlacesRepository implements PlacesRepository {
  List<Place> nearbyPlaces;
  List<Place> searchResults;

  FakePlacesRepository({
    this.nearbyPlaces = const [],
    this.searchResults = const [],
  });

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    return nearbyPlaces;
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    return searchResults;
  }

  @override
  Future<Place?> getPlaceById(
    String placeId, {
    required Language language,
  }) async {
    for (final place in [...nearbyPlaces, ...searchResults]) {
      if (place.id == placeId) return place;
    }
    return null;
  }
}
