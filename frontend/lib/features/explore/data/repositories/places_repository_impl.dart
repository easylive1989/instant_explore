import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

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
    required Language language,
    required double radius,
  }) async {
    final dtos = await _apiService.searchNearby(
      location,
      includedTypes: _includedTypes,
      languageCode: language.code,
      radius: radius,
    );

    // DTO -> Domain 轉換，同時產生照片 URL
    return dtos.map((dto) => dto.toDomain(apiKey: _apiService.apiKey)).toList();
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    final dtos = await _apiService.searchByText(
      query,
      languageCode: language.code,
    );

    // DTO -> Domain 轉換，同時產生照片 URL
    return dtos.map((dto) => dto.toDomain(apiKey: _apiService.apiKey)).toList();
  }
}
