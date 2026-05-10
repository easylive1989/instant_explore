import 'package:context_app/core/utils/geo_utils.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/data/services/geolocator_service.dart';
import 'package:context_app/features/explore/data/services/wikidata_landmark_query_service.dart';
import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:context_app/features/explore/data/services/hive_places_cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/data/repositories/caching_places_repository.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/providers.dart';

// Infrastructure Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorService();
});

final wikipediaPlacesServiceProvider = Provider<WikipediaPlacesService>((ref) {
  return WikipediaPlacesService();
});

final wikidataLandmarkQueryServiceProvider =
    Provider<WikidataLandmarkQueryService>((ref) {
      return WikidataLandmarkQueryService();
    });

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final service = ref.watch(wikipediaPlacesServiceProvider);
  final landmarkService = ref.watch(wikidataLandmarkQueryServiceProvider);
  final cacheService = ref.watch(placesCacheServiceProvider);
  final apiRepository = PlacesRepositoryImpl(
    service,
    landmarkService: landmarkService,
  );
  return CachingPlacesRepository(apiRepository, cacheService);
});

final placesCacheServiceProvider = Provider<HivePlacesCacheService>((ref) {
  return HivePlacesCacheService();
});

// Filter Providers

/// 使用者目前位置，由 [PlacesController] 在載入附近地點時更新
final userLocationProvider = StateProvider<PlaceLocation?>((ref) => null);

/// 探索頁面預設的距離過濾上限（公尺）。
const double kDefaultMaxDistanceMeters = 10000.0;

/// 距離過濾上限（公尺），預設 [kDefaultMaxDistanceMeters]
final maxDistanceProvider = StateProvider<double>(
  (ref) => kDefaultMaxDistanceMeters,
);

/// 目前的搜尋關鍵字；空字串表示顯示附近地點模式
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 根據最大距離過濾後的地點列表
///
/// 監聽 [placesControllerProvider]、[maxDistanceProvider] 與
/// [userLocationProvider]，當任一改變時自動重新過濾。
/// 在搜尋模式（[searchQueryProvider] 非空）下跳過距離過濾。
final filteredPlacesProvider = Provider<AsyncValue<List<Place>>>((ref) {
  final placesAsync = ref.watch(placesControllerProvider);
  final maxDistance = ref.watch(maxDistanceProvider);
  final userLocation = ref.watch(userLocationProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return placesAsync.whenData((places) {
    if (searchQuery.isNotEmpty) return places;
    if (userLocation == null) return places;
    return places.where((p) {
      final distance = calculateHaversineDistance(userLocation, p.location);
      return distance <= maxDistance;
    }).toList();
  });
});

// Use Case Providers
final searchNearbyPlacesUseCaseProvider = Provider<SearchNearbyPlacesUseCase>((
  ref,
) {
  final locationService = ref.watch(locationServiceProvider);
  final repository = ref.watch(placesRepositoryProvider);
  return SearchNearbyPlacesUseCase(locationService, repository);
});

// UI-facing Providers
final placesControllerProvider =
    AsyncNotifierProvider<PlacesController, List<Place>>(() {
      return PlacesController();
    });

class PlacesController extends AsyncNotifier<List<Place>> {
  @override
  Future<List<Place>> build() async {
    final language = ref.watch(currentLanguageProvider);
    final radius = ref.read(maxDistanceProvider);
    final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
    final result = await useCase.execute(language: language, radius: radius);
    ref.read(userLocationProvider.notifier).state = result.userLocation;
    return result.places;
  }

  Future<List<Place>> _loadNearbyPlaces({double? radius}) async {
    final language = ref.read(currentLanguageProvider);
    final double effectiveRadius = radius ?? ref.read(maxDistanceProvider);
    final useCase = ref.read(searchNearbyPlacesUseCaseProvider);
    final result = await useCase.execute(
      language: language,
      radius: effectiveRadius,
    );
    ref.read(userLocationProvider.notifier).state = result.userLocation;
    return result.places;
  }

  Future<void> search(String query) async {
    final language = ref.read(currentLanguageProvider);

    if (query.isEmpty) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadNearbyPlaces());
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(placesRepositoryProvider);
      return repository.searchPlaces(query, language: language);
    });
  }

  /// 強制重新整理（忽略快取），可傳入新的搜尋半徑
  Future<void> refresh({double? radius}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadNearbyPlaces(radius: radius));
  }
}
