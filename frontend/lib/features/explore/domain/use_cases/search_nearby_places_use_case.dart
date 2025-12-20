import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class SearchNearbyPlacesUseCase {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;

  SearchNearbyPlacesUseCase(this._locationService, this._placesRepository);

  Future<List<Place>> execute({required Language language}) async {
    final location = await _locationService.getCurrentLocation();
    return _placesRepository.getNearbyPlaces(location, language: language);
  }
}
