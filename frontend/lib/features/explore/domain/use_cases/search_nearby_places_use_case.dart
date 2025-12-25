import 'dart:math';

import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/domain/services/places_cache_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class SearchNearbyPlacesUseCase {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;
  final PlacesCacheService _cacheService;

  /// 評分權重 (70%)
  static const double _ratingWeight = 0.7;

  /// 距離權重 (30%)
  static const double _distanceWeight = 0.3;

  /// 距離容許範圍（公尺）- 在此範圍內主要看評分
  static const double _distanceToleranceMeters = 200.0;

  // 最大搜尋半徑
  static const _maxDistance = 1000.0;

  SearchNearbyPlacesUseCase(
    this._locationService,
    this._placesRepository,
    this._cacheService,
  );

  Future<List<Place>> execute({required Language language}) async {
    final userLocation = await _locationService.getCurrentLocation();

    // 檢查是否需要重新搜尋（快取過期或移動超過 1km）
    final shouldRefresh = await _cacheService.shouldRefresh(userLocation);

    if (!shouldRefresh) {
      // 使用快取資料
      final cachedPlaces = await _cacheService.getCachedPlaces();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        return _sortByWeightedScore(cachedPlaces, userLocation);
      }
    }

    // 呼叫 API 取得新資料
    final places = await _placesRepository.getNearbyPlaces(
      userLocation,
      language: language,
      radius: _maxDistance,
    );

    // 儲存到快取
    await _cacheService.cachePlaces(places);
    await _cacheService.saveLastSearchLocation(userLocation);

    // 使用權重計分法排序
    return _sortByWeightedScore(places, userLocation);
  }

  /// 強制重新整理（忽略快取）
  Future<List<Place>> forceRefresh({required Language language}) async {
    final userLocation = await _locationService.getCurrentLocation();

    // 清除快取
    await _cacheService.clearCache();

    // 呼叫 API 取得新資料
    final places = await _placesRepository.getNearbyPlaces(
      userLocation,
      language: language,
      radius: _maxDistance,
    );

    // 儲存到快取
    await _cacheService.cachePlaces(places);
    await _cacheService.saveLastSearchLocation(userLocation);

    return _sortByWeightedScore(places, userLocation);
  }

  /// 使用權重計分法排序地點
  ///
  /// 排序邏輯：
  /// 1. 如果兩地點距離差異在 200 公尺內，優先看評分
  /// 2. 否則使用綜合分數排序（評分 70% + 距離 30%）
  List<Place> _sortByWeightedScore(
    List<Place> places,
    PlaceLocation userLocation,
  ) {
    // 計算每個地點與使用者的距離
    final placesWithDistance = places.map((place) {
      final distance = _calculateDistance(userLocation, place.location);
      return _PlaceWithDistance(place: place, distance: distance);
    }).toList();

    // 排序
    placesWithDistance.sort((a, b) {
      final distanceDiff = (a.distance - b.distance).abs();

      // 如果距離差異在容許範圍內，優先看評分
      if (distanceDiff < _distanceToleranceMeters) {
        final ratingA = a.place.rating ?? 0.0;
        final ratingB = b.place.rating ?? 0.0;
        return ratingB.compareTo(ratingA); // 高分在前
      }

      // 否則使用綜合分數排序
      final scoreA = _calculateScore(a.place, a.distance);
      final scoreB = _calculateScore(b.place, b.distance);
      return scoreB.compareTo(scoreA); // 高分在前
    });

    return placesWithDistance.map((p) => p.place).toList();
  }

  /// 計算綜合分數
  ///
  /// Score = (Rating / 5.0) * 0.7 + distanceScore * 0.3
  /// 其中 distanceScore = 1 - (distance / maxDistance) (越近越高)
  double _calculateScore(Place place, double distanceMeters) {
    final rating = place.rating ?? 0.0;

    // 評分分數 (0~1)
    final ratingScore = rating / 5.0;

    // 距離分數 (越近越高，0~1)
    // 0m = 1.0, 1000m = 0.0
    final distanceScore = (1.0 - (distanceMeters / _maxDistance)).clamp(
      0.0,
      1.0,
    );

    return (ratingScore * _ratingWeight) + (distanceScore * _distanceWeight);
  }

  /// 計算兩點之間的距離（Haversine 公式）
  ///
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

/// 帶距離資訊的地點
class _PlaceWithDistance {
  final Place place;
  final double distance;

  _PlaceWithDistance({required this.place, required this.distance});
}
