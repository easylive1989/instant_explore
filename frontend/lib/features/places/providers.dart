import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/features/places/infrastructure/geolocator_service.dart';
import 'package:context_app/features/places/infrastructure/services/places_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/places/application/get_current_location_use_case.dart';
import 'package:context_app/features/places/application/get_nearby_places_use_case.dart';
import 'package:context_app/features/places/domain/repositories/places_repository.dart';
import 'package:context_app/features/places/domain/services/location_service.dart';
import 'package:context_app/features/places/infrastructure/repositories/places_repository_impl.dart';
import 'package:context_app/features/places/models/place.dart';

// Infrastructure Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorService();
});

final placesApiServiceProvider = Provider<PlacesApiService>((ref) {
  final apiKey = ref.watch(apiConfigProvider).googleMapsApiKey;
  return PlacesApiService(apiKey);
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final placesApiService = ref.watch(placesApiServiceProvider);
  return PlacesRepositoryImpl(placesApiService);
});

// Use Case Providers
final getCurrentLocationUseCaseProvider = Provider<GetCurrentLocationUseCase>((
  ref,
) {
  final locationService = ref.watch(locationServiceProvider);
  return GetCurrentLocationUseCase(locationService);
});

final getNearbyPlacesUseCaseProvider = Provider<GetNearbyPlacesUseCase>((ref) {
  final repository = ref.watch(placesRepositoryProvider);
  return GetNearbyPlacesUseCase(repository);
});

// UI-facing Providers
final currentLocationProvider = FutureProvider<PlaceLocation>((ref) async {
  final useCase = ref.watch(getCurrentLocationUseCaseProvider);
  return useCase.execute();
});

final nearbyPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  final useCase = ref.watch(getNearbyPlacesUseCaseProvider);
  return useCase.execute(location);
});
