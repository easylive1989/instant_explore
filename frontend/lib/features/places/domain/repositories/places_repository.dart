import 'package:context_app/features/places/models/place.dart';

abstract class PlacesRepository {
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    String? languageCode,
  });
  Future<List<Place>> searchPlaces(String query, {String? languageCode});
}
