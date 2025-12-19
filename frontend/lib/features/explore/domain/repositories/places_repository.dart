import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';

abstract class PlacesRepository {
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    String? languageCode,
  });
  Future<List<Place>> searchPlaces(String query, {String? languageCode});
}
