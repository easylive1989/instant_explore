import 'package:context_app/features/places/domain/repositories/places_repository.dart';
import 'package:context_app/features/places/domain/services/location_service.dart';
import 'package:context_app/features/places/models/place.dart';

class SearchNearbyPlacesUseCase {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;

  SearchNearbyPlacesUseCase(this._locationService, this._placesRepository);

  Future<List<Place>> execute() async {
    final location = await _locationService.getCurrentLocation();
    return _placesRepository.getNearbyPlaces(location);
  }
}
