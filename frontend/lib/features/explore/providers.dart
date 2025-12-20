import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/domain/use_cases/search_places_use_case.dart';
import 'package:context_app/features/explore/data/services/geolocator_service.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/domain/models/place.dart';

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
final searchNearbyPlacesUseCaseProvider = Provider<SearchNearbyPlacesUseCase>((
  ref,
) {
  final locationService = ref.watch(locationServiceProvider);
  final repository = ref.watch(placesRepositoryProvider);
  return SearchNearbyPlacesUseCase(locationService, repository);
});

final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>((ref) {
  final repository = ref.watch(placesRepositoryProvider);
  return SearchPlacesUseCase(repository);
});

// UI-facing Providers
final placesControllerProvider =
    AsyncNotifierProvider<PlacesController, List<Place>>(() {
      return PlacesController();
    });

class PlacesController extends AsyncNotifier<List<Place>> {
  @override
  Future<List<Place>> build() async {
    return _loadNearbyPlaces();
  }

  Future<List<Place>> _loadNearbyPlaces({String? languageCode}) async {
    final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
    return useCase.execute(languageCode: languageCode);
  }

  Future<void> search(String query, {String? languageCode}) async {
    if (query.isEmpty) {
      // If query is empty, reload nearby places
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(
        () => _loadNearbyPlaces(languageCode: languageCode),
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(searchPlacesUseCaseProvider);
      return useCase.execute(query, languageCode: languageCode);
    });
  }

  Future<void> refresh({String? languageCode}) async {
    state = const AsyncValue.loading();
    // Reset to nearby places on refresh if we want that behavior,
    // or just re-execute the last action.
    // For simplicity, let's reload nearby places as the default "home" state.
    state = await AsyncValue.guard(
      () => _loadNearbyPlaces(languageCode: languageCode),
    );
  }
}
