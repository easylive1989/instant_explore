import 'package:context_app/features/places/models/place.dart';

abstract class PlacesRepository {
  Future<List<Place>> getNearbyPlaces(PlaceLocation location);
}
