import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/places/domain/repositories/places_repository.dart';

class GetNearbyPlacesUseCase {
  final PlacesRepository _repository;

  GetNearbyPlacesUseCase(this._repository);

  Future<List<Place>> execute(PlaceLocation location) {
    return _repository.getNearbyPlaces(location);
  }
}
