import 'package:context_app/features/explore/data/services/hive_places_cache_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 使用 Decorator 模式包裝 PlacesRepository，添加快取功能
///
/// 此類別透過快取機制減少 API 呼叫次數：
/// - 若快取未過期且使用者位置未大幅移動，直接回傳快取資料
/// - 否則呼叫底層 Repository 取得新資料並更新快取
class CachingPlacesRepository implements PlacesRepository {
  final PlacesRepository _delegate;
  final HivePlacesCacheService _cacheService;

  CachingPlacesRepository(this._delegate, this._cacheService);

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    // 檢查是否需要重新搜尋（快取過期或移動超過門檻距離）
    final shouldRefresh = await _cacheService.shouldRefresh(location);

    if (!shouldRefresh) {
      // 使用快取資料
      final cachedPlaces = await _cacheService.getCachedPlaces();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        return cachedPlaces;
      }
    }

    // 呼叫底層 Repository 取得新資料
    final places = await _delegate.getNearbyPlaces(
      location,
      language: language,
      radius: radius,
    );

    // 儲存到快取
    await _cacheService.cachePlaces(places);
    await _cacheService.saveLastSearchLocation(location);

    return places;
  }

  @override
  Future<List<Place>> searchPlaces(String query, {required Language language}) {
    // 關鍵字搜尋不使用快取，直接委派給底層 Repository
    return _delegate.searchPlaces(query, language: language);
  }

  @override
  Future<Place?> getPlaceById(
    String placeId, {
    required Language language,
  }) {
    // 單一地點查詢不使用快取
    return _delegate.getPlaceById(placeId, language: language);
  }
}
