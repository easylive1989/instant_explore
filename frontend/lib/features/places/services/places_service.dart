import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:travel_diary/core/config/api_config.dart';
import 'package:travel_diary/features/places/models/place.dart';
import 'package:travel_diary/features/places/models/place_details.dart';
import 'package:travel_diary/features/places/models/place_suggestion.dart';
import 'package:travel_diary/features/places/exceptions/places_exceptions.dart';

/// Google Places API 服務類別
///
/// 負責處理所有與 Google Places API 相關的功能：
/// - 搜尋附近餐廳
/// - 取得地點詳細資訊
/// - 隨機推薦餐廳
class PlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  final ApiConfig _apiConfig;
  String get _apiKey => _apiConfig.googleMapsApiKey;

  PlacesService(this._apiConfig);

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
      throw ApiKeyException();
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

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.types,places.photos,places.currentOpeningHours',
    };

    try {
      final response = await http
          .post(url, headers: headers, body: json.encode(requestBody))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 檢查 API 回應結構
        if (data['places'] == null) {
          throw ApiResponseException('API 回應格式錯誤：缺少 places 欄位');
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiKeyException('API 金鑰無效或權限不足');
      } else if (response.statusCode == 429) {
        throw QuotaExceededException();
      } else {
        throw ApiResponseException(
          '搜尋失敗: ${response.body}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw TimeoutException('請求超時');
    } on SocketException {
      throw NetworkException();
    } on PlacesException {
      rethrow;
    } catch (e) {
      throw ApiResponseException('未知錯誤: $e');
    }
  }

  /// 取得地點詳細資訊
  ///
  /// [placeId] 地點 ID

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) {
      throw ApiKeyException();
    }

    final url = Uri.parse('$_baseUrl/places/$placeId');

    final headers = {
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'id,displayName,formattedAddress,location,rating,priceLevel,types,photos,internationalPhoneNumber,nationalPhoneNumber,websiteUri,googleMapsUri,currentOpeningHours,reviews,editorialSummary',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiKeyException('API 金鑰無效或權限不足');
      } else if (response.statusCode == 429) {
        throw QuotaExceededException();
      } else {
        throw ApiResponseException(
          '取得地點詳細資訊失敗: ${response.body}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw TimeoutException('請求超時');
    } on SocketException {
      throw NetworkException();
    } on PlacesException {
      rethrow;
    } catch (e) {
      throw ApiResponseException('未知錯誤: $e');
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
    } on PlacesException {
      rethrow;
    } catch (e) {
      throw ApiResponseException('隨機推薦餐廳失敗: $e');
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
      throw ApiKeyException();
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

  /// 搜尋地點自動完成建議
  ///
  /// [input] 搜尋文字
  /// [latitude] 緯度（選用，用於位置偏好）
  /// [longitude] 經度（選用，用於位置偏好）
  /// [radius] 偏好半徑（公尺），預設 5000 公尺

  Future<List<PlaceSuggestion>> searchPlacesAutocomplete({
    required String input,
    double? latitude,
    double? longitude,
    double radius = 5000,
  }) async {
    if (_apiKey.isEmpty) {
      throw ApiKeyException();
    }

    if (input.trim().isEmpty) {
      return [];
    }

    final url = Uri.parse('$_baseUrl/places:autocomplete');

    final requestBody = <String, dynamic>{
      'input': input,
      'includedPrimaryTypes': ['restaurant'],
    };

    // 如果有提供位置，加入位置偏好
    if (latitude != null && longitude != null) {
      requestBody['locationBias'] = {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radius,
        },
      };
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
    };

    try {
      final response = await http
          .post(url, headers: headers, body: json.encode(requestBody))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['suggestions'] == null) {
          return [];
        }

        final suggestions =
            (data['suggestions'] as List?)
                ?.map((suggestionData) {
                  try {
                    return PlaceSuggestion.fromJson(suggestionData);
                  } catch (e) {
                    debugPrint('解析建議資料錯誤: $e');
                    debugPrint('問題資料: $suggestionData');
                    return null;
                  }
                })
                .whereType<PlaceSuggestion>()
                .toList() ??
            [];

        return suggestions;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiKeyException('API 金鑰無效或權限不足');
      } else if (response.statusCode == 429) {
        throw QuotaExceededException();
      } else {
        throw ApiResponseException(
          '搜尋自動完成失敗: ${response.body}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw TimeoutException('請求超時');
    } on SocketException {
      throw NetworkException();
    } on PlacesException {
      rethrow;
    } catch (e) {
      throw ApiResponseException('未知錯誤: $e');
    }
  }

  /// 檢查 API 金鑰是否已設定

  bool get isApiKeyConfigured => _apiKey.isNotEmpty;
}
