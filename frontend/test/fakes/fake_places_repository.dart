import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Fake [PlacesRepository] that returns seeded results.
class FakePlacesRepository implements PlacesRepository {
  List<Place> nearbyPlaces;
  List<Place> searchResults;

  /// Number of [getNearbyPlaces] invocations — useful for asserting refresh.
  int nearbyCallCount = 0;

  /// Number of [searchPlaces] invocations and the last query received.
  int searchCallCount = 0;
  String? lastSearchQuery;

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
    nearbyCallCount += 1;
    return nearbyPlaces;
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    searchCallCount += 1;
    lastSearchQuery = query;
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
