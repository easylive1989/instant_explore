import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/models/place.dart';

class SearchNearbyPlacesUseCase {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;

  SearchNearbyPlacesUseCase(this._locationService, this._placesRepository);

  Future<List<Place>> execute({String? languageCode}) async {
    final location = await _locationService.getCurrentLocation();
    return _placesRepository.getNearbyPlaces(
      location,
      languageCode: languageCode,
    );
  }
}
