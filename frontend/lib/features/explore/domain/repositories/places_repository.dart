import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

abstract class PlacesRepository {
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  });

  Future<List<Place>> searchPlaces(String query, {required Language language});

  /// Fetches a single place by its Google Place ID.
  ///
  /// Returns `null` if the place is not found.
  Future<Place?> getPlaceById(String placeId, {required Language language});
}
