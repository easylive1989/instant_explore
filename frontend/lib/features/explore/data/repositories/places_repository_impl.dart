import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesApiService _apiService;

  PlacesRepositoryImpl(this._apiService);

  static const List<String> _includedTypes = [
    'tourist_attraction',
    'historical_landmark',
    'art_gallery',
    'museum',
    'park',
    'national_park',
    'city_hall',
    'library',
    'aquarium',
    'zoo',
  ];

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    String? languageCode,
  }) async {
    return _apiService.searchNearby(
      location,
      includedTypes: _includedTypes,
      languageCode: languageCode,
    );
  }

  @override
  Future<List<Place>> searchPlaces(String query, {String? languageCode}) async {
    return _apiService.searchByText(query, languageCode: languageCode);
  }
}
