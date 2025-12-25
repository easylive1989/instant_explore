import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';

/// 地點快取服務介面
///
/// 用於快取 Places API 回傳的地點資料，降低 API 呼叫次數
abstract class PlacesCacheService {
  /// 取得快取的地點列表
  Future<List<Place>?> getCachedPlaces();

  /// 儲存地點列表到快取
  Future<void> cachePlaces(List<Place> places);

  /// 取得上次搜尋位置
  Future<PlaceLocation?> getLastSearchLocation();

  /// 儲存搜尋位置
  Future<void> saveLastSearchLocation(PlaceLocation location);

  /// 清除快取
  Future<void> clearCache();

  /// 檢查是否需要重新搜尋
  /// 條件: 距離上次搜尋位置 > 1km 或快取已過期
  Future<bool> shouldRefresh(PlaceLocation currentLocation);
}
