import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_keys.dart';
import '../features/places/models/place.dart';
import '../features/places/models/place_details.dart';

/// Places API 異常類別
class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;

  PlacesApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'PlacesApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Google Places API 服務類別
///
/// 負責處理所有與 Google Places API 相關的功能：
/// - 搜尋附近餐廳
/// - 取得地點詳細資訊
/// - 隨機推薦餐廳
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  static const String _baseUrl = 'https://places.googleapis.com/v1';
  final String _apiKey = ApiKeys.googleMapsApiKey;

  /// 搜尋附近的餐廳
  ///
  /// [latitude] 緯度
  /// [longitude] 經度
  /// [radius] 搜尋半徑（公尺），預設 2000 公尺
  /// [maxResults] 最大結果數量，預設 20
  Future<List<Place>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 2000,
    int maxResults = 20,
  }) async {
    if (_apiKey.isEmpty) {
      throw PlacesApiException('Google Places API Key 未設定');
    }

    final url = Uri.parse('$_baseUrl/places:searchNearby');

    final requestBody = {
      'locationRestriction': {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radius,
        },
      },
      'maxResultCount': maxResults,
      'includedTypes': ['restaurant'],
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.types,places.photos,places.currentOpeningHours',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 檢查 API 回應結構
        if (data['places'] == null) {
          throw PlacesApiException('API 回應格式錯誤：缺少 places 欄位');
        }

        final places =
            (data['places'] as List?)?.map((placeData) {
              try {
                return Place.fromJson(placeData);
              } catch (e) {
                // 記錄解析錯誤的資料（僅在 debug 模式）
                debugPrint('解析地點資料錯誤: $e');
                debugPrint('問題資料: $placeData');
                rethrow;
              }
            }).toList() ??
            [];

        return places;
      } else {
        throw PlacesApiException(
          '搜尋附近餐廳失敗: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      throw PlacesApiException('網路錯誤: $e');
    }
  }

  /// 取得地點詳細資訊
  ///
  /// [placeId] 地點 ID
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) {
      throw PlacesApiException('Google Places API Key 未設定');
    }

    final url = Uri.parse('$_baseUrl/places/$placeId');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'id,displayName,formattedAddress,location,rating,priceLevel,types,photos,internationalPhoneNumber,nationalPhoneNumber,websiteUri,googleMapsUri,currentOpeningHours,reviews,editorialSummary',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromJson(data);
      } else {
        throw PlacesApiException(
          '取得地點詳細資訊失敗: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      throw PlacesApiException('網路錯誤: $e');
    }
  }

  /// 隨機推薦附近餐廳
  ///
  /// [latitude] 緯度
  /// [longitude] 經度
  /// [radius] 搜尋半徑（公尺），預設 2000 公尺
  Future<Place?> getRandomNearbyRestaurant({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    try {
      final restaurants = await searchNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        maxResults: 20,
      );

      if (restaurants.isEmpty) {
        return null;
      }

      // 過濾掉沒有評分或評分太低的餐廳（可選）
      final filteredRestaurants = restaurants.where((restaurant) {
        return restaurant.rating == null || restaurant.rating! >= 3.0;
      }).toList();

      final targetList = filteredRestaurants.isNotEmpty
          ? filteredRestaurants
          : restaurants;

      // 隨機選擇一家餐廳
      final random = Random();
      final selectedRestaurant = targetList[random.nextInt(targetList.length)];

      return selectedRestaurant;
    } catch (e) {
      if (e is PlacesApiException) rethrow;
      throw PlacesApiException('隨機推薦餐廳失敗: $e');
    }
  }

  /// 計算兩個座標點之間的距離（公尺）
  ///
  /// 使用 Haversine 公式計算球面距離
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 地球半徑（公尺）

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  /// 將度轉換為弧度
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// 格式化距離文字
  ///
  /// [distanceInMeters] 距離（公尺）
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} 公尺';
    } else {
      final km = distanceInMeters / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)} 公里';
      } else {
        return '${km.round()} 公里';
      }
    }
  }

  /// 取得照片 URL
  ///
  /// [photoName] 照片名稱
  /// [maxWidth] 最大寬度
  /// [maxHeight] 最大高度
  String getPhotoUrl({
    required String photoName,
    int? maxWidth,
    int? maxHeight,
  }) {
    if (_apiKey.isEmpty) {
      throw PlacesApiException('Google Places API Key 未設定');
    }

    final baseUrl = 'https://places.googleapis.com/v1/$photoName/media';
    final params = <String>[];

    if (maxWidth != null) {
      params.add('maxWidthPx=$maxWidth');
    }
    if (maxHeight != null) {
      params.add('maxHeightPx=$maxHeight');
    }
    params.add('key=$_apiKey');

    return '$baseUrl?${params.join('&')}';
  }

  /// 檢查 API 金鑰是否已設定
  bool get isApiKeyConfigured => _apiKey.isNotEmpty;
}
