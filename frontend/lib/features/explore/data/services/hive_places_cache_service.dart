import 'dart:convert';
import 'dart:math';

import 'package:context_app/features/explore/data/dto/google_place_dto.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/places_cache_service.dart';
import 'package:hive/hive.dart';

/// Hive 實作的地點快取服務
///
/// 使用 Hive 儲存地點資料，支援 TTL 和距離判斷
/// 內部使用 DTO 進行序列化，對外使用 Domain Model
class HivePlacesCacheService implements PlacesCacheService {
  final String _apiKey;

  static const String _boxName = 'places_cache';
  static const String _placesKey = 'cached_places';
  static const String _timestampKey = 'cache_timestamp';
  static const String _locationKey = 'last_search_location';

  /// 快取有效期限（24 小時）
  static const Duration _cacheTtl = Duration(hours: 24);

  /// 重新搜尋的距離門檻（1 公里）
  static const double _refreshDistanceThreshold = 1000.0;

  Box? _box;

  HivePlacesCacheService(this._apiKey);

  /// 取得或開啟 Hive Box
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<List<Place>?> getCachedPlaces() async {
    try {
      final box = await _getBox();
      final placesJson = box.get(_placesKey) as String?;

      if (placesJson == null) return null;

      final List<dynamic> placesList = jsonDecode(placesJson);
      // 使用 DTO 反序列化，然後轉換為 Domain Model
      // apiKey 從建構函式注入，不需要快取
      return placesList
          .map((json) => GooglePlaceDto.fromJson(json as Map<String, dynamic>))
          .map((dto) => dto.toDomain(apiKey: _apiKey))
          .toList();
    } catch (e) {
      // 解析失敗時返回 null，讓呼叫端重新取得資料
      return null;
    }
  }

  @override
  Future<void> cachePlaces(List<Place> places) async {
    final box = await _getBox();

    // 將 Domain Model 轉換為可序列化的格式
    final placesData = places.map((p) => _placeToJson(p)).toList();
    final placesJson = jsonEncode(placesData);

    await box.put(_placesKey, placesJson);
    await box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 將 Place 轉換為可序列化的 JSON 格式
  Map<String, dynamic> _placeToJson(Place place) {
    return {
      'id': place.id,
      'displayName': {'text': place.name},
      'formattedAddress': place.formattedAddress,
      'location': {
        'latitude': place.location.latitude,
        'longitude': place.location.longitude,
      },
      'rating': place.rating,
      'types': place.types,
      'photos': place.photos
          .map(
            (photo) => {
              'name': _extractPhotoNameFromUrl(photo.url),
              'widthPx': photo.widthPx,
              'heightPx': photo.heightPx,
              'authorAttributions': photo.authorAttributions,
            },
          )
          .toList(),
    };
  }

  /// 從照片 URL 中提取 photo name
  String _extractPhotoNameFromUrl(String url) {
    // URL 格式: https://places.googleapis.com/v1/{name}/media?...
    final uri = Uri.parse(url);
    final path = uri.path;
    // 移除 /media 後綴
    if (path.endsWith('/media')) {
      return path.substring(1, path.length - 6);
    }
    return path;
  }

  @override
  Future<PlaceLocation?> getLastSearchLocation() async {
    try {
      final box = await _getBox();
      final locationJson = box.get(_locationKey) as String?;

      if (locationJson == null) return null;

      final Map<String, dynamic> locationMap = jsonDecode(locationJson);
      return PlaceLocation.fromJson(locationMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLastSearchLocation(PlaceLocation location) async {
    final box = await _getBox();
    final locationJson = jsonEncode(location.toJson());
    await box.put(_locationKey, locationJson);
  }

  @override
  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(_placesKey);
    await box.delete(_timestampKey);
    await box.delete(_locationKey);
  }

  @override
  Future<bool> shouldRefresh(PlaceLocation currentLocation) async {
    // 檢查快取是否過期
    if (await _isCacheExpired()) {
      return true;
    }

    // 檢查距離是否超過門檻
    final lastLocation = await getLastSearchLocation();
    if (lastLocation == null) {
      return true;
    }

    final distance = _calculateDistance(lastLocation, currentLocation);
    return distance > _refreshDistanceThreshold;
  }

  /// 檢查快取是否已過期
  Future<bool> _isCacheExpired() async {
    final box = await _getBox();
    final timestamp = box.get(_timestampKey) as int?;

    if (timestamp == null) return true;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cachedTime) > _cacheTtl;
  }

  /// 計算兩點之間的距離（Haversine 公式）
  /// 返回距離（公尺）
  double _calculateDistance(PlaceLocation from, PlaceLocation to) {
    const earthRadiusMeters = 6371000.0;

    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final deltaLat = (to.latitude - from.latitude) * pi / 180;
    final deltaLon = (to.longitude - from.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }
}
