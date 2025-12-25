import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/domain/use_cases/search_places_use_case.dart';
import 'package:context_app/features/explore/data/services/geolocator_service.dart';
import 'package:context_app/features/explore/data/services/places_api_service.dart';
import 'package:context_app/features/explore/data/services/hive_places_cache_service.dart';
import 'package:context_app/features/explore/domain/services/places_cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/presentation/providers/language_provider.dart';

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

final placesCacheServiceProvider = Provider<PlacesCacheService>((ref) {
  final apiKey = ref.watch(apiConfigProvider).googleMapsApiKey;
  return HivePlacesCacheService(apiKey);
});

// Use Case Providers
final searchNearbyPlacesUseCaseProvider = Provider<SearchNearbyPlacesUseCase>((
  ref,
) {
  final locationService = ref.watch(locationServiceProvider);
  final repository = ref.watch(placesRepositoryProvider);
  final cacheService = ref.watch(placesCacheServiceProvider);
  return SearchNearbyPlacesUseCase(locationService, repository, cacheService);
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
    // 使用 ref.watch 監聽語言變化
    // 當語言改變時，會自動觸發重新載入
    final language = ref.watch(currentLanguageProvider);
    final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
    return useCase.execute(language: language);
  }

  Future<List<Place>> _loadNearbyPlaces() async {
    final language = ref.read(currentLanguageProvider);
    final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
    return useCase.execute(language: language);
  }

  Future<void> search(String query) async {
    final language = ref.read(currentLanguageProvider);

    if (query.isEmpty) {
      // If query is empty, reload nearby places
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadNearbyPlaces());
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(searchPlacesUseCaseProvider);
      return useCase.execute(query, language: language);
    });
  }

  /// 強制重新整理（忽略快取）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final language = ref.read(currentLanguageProvider);
      final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
      return useCase.forceRefresh(language: language);
    });
  }
}
