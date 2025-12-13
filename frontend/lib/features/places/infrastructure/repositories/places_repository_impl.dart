import 'package:context_app/features/places/domain/repositories/places_repository.dart';
import 'package:context_app/features/places/infrastructure/services/places_api_service.dart';
import 'package:context_app/features/places/models/place.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesApiService _apiService;

  PlacesRepositoryImpl(this._apiService);

  @override
  Future<List<Place>> getNearbyPlaces(PlaceLocation location) async {
    return _apiService.searchNearby(location);
  }
}
