import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/places/models/place.dart';
import '../../features/places/models/place_details.dart';

/// Fake PlacesService for E2E testing
///
/// 模擬地點服務，在 E2E 測試中使用
/// 回傳預設的 mock 餐廳資料，避免真實的 Google Places API 調用
class FakePlacesService {
  static final FakePlacesService _instance = FakePlacesService._internal();
  factory FakePlacesService() => _instance;
  FakePlacesService._internal();

  // 預設測試餐廳資料
  static final List<Map<String, dynamic>> _testRestaurants = [
    {
      'id': 'fake-restaurant-1',
      'displayName': {'text': '測試餐廳'},
      'formattedAddress': '台北市信義區信義路五段7號',
      'location': {'latitude': 25.0340, 'longitude': 121.5645},
      'rating': 4.5,
      'priceLevel': 'PRICE_LEVEL_MODERATE',
      'types': ['restaurant', 'food', 'establishment'],
      'photos': [
        {'name': 'fake-photo-1', 'widthPx': 400, 'heightPx': 300},
      ],
      'currentOpeningHours': {
        'openNow': true,
        'weekdayDescriptions': [
          '星期一: 11:00 – 21:00',
          '星期二: 11:00 – 21:00',
          '星期三: 11:00 – 21:00',
          '星期四: 11:00 – 21:00',
          '星期五: 11:00 – 22:00',
          '星期六: 10:00 – 22:00',
          '星期日: 10:00 – 21:00',
        ],
      },
    },
    {
      'id': 'fake-restaurant-2',
      'displayName': {'text': 'E2E 咖啡廳'},
      'formattedAddress': '台北市信義區松仁路28號',
      'location': {'latitude': 25.0320, 'longitude': 121.5660},
      'rating': 4.2,
      'priceLevel': 'PRICE_LEVEL_INEXPENSIVE',
      'types': ['cafe', 'restaurant', 'food'],
      'photos': [
        {'name': 'fake-photo-2', 'widthPx': 500, 'heightPx': 400},
      ],
      'currentOpeningHours': {
        'openNow': true,
        'weekdayDescriptions': [
          '星期一: 08:00 – 20:00',
          '星期二: 08:00 – 20:00',
          '星期三: 08:00 – 20:00',
          '星期四: 08:00 – 20:00',
          '星期五: 08:00 – 21:00',
          '星期六: 09:00 – 21:00',
          '星期日: 09:00 – 20:00',
        ],
      },
    },
    {
      'id': 'fake-restaurant-3',
      'displayName': {'text': '模擬火鍋店'},
      'formattedAddress': '台北市信義區市府路45號',
      'location': {'latitude': 25.0350, 'longitude': 121.5630},
      'rating': 4.8,
      'priceLevel': 'PRICE_LEVEL_EXPENSIVE',
      'types': ['restaurant', 'food'],
      'photos': [
        {'name': 'fake-photo-3', 'widthPx': 600, 'heightPx': 450},
      ],
      'currentOpeningHours': {
        'openNow': false,
        'weekdayDescriptions': [
          '星期一: 休息',
          '星期二: 17:00 – 23:00',
          '星期三: 17:00 – 23:00',
          '星期四: 17:00 – 23:00',
          '星期五: 17:00 – 24:00',
          '星期六: 12:00 – 24:00',
          '星期日: 12:00 – 23:00',
        ],
      },
    },
  ];

  /// 搜尋附近的餐廳 (回傳預設測試資料)
  Future<List<Place>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 2000,
    int maxResults = 20,
  }) async {
    try {
      debugPrint('🧪 FakePlacesService: 搜尋附近餐廳 (回傳測試資料)');
      debugPrint('📍 搜尋位置: $latitude, $longitude');
      debugPrint('📏 搜尋半徑: $radius 公尺');

      // 模擬 API 調用延遲
      await Future.delayed(const Duration(milliseconds: 1000));

      // 轉換測試資料為 Place 物件
      final places = _testRestaurants.take(maxResults).map((restaurantData) {
        try {
          return Place.fromJson(restaurantData);
        } catch (e) {
          debugPrint('❌ 解析測試餐廳資料錯誤: $e');
          debugPrint('問題資料: $restaurantData');
          rethrow;
        }
      }).toList();

      debugPrint('✅ FakePlacesService: 回傳 ${places.length} 家測試餐廳');
      return places;
    } catch (e) {
      debugPrint('❌ FakePlacesService: 搜尋餐廳失敗: $e');
      rethrow;
    }
  }

  /// 取得地點詳細資訊 (回傳預設測試資料)
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      debugPrint('🧪 FakePlacesService: 取得地點詳細資訊 (ID: $placeId)');

      // 模擬 API 調用延遲
      await Future.delayed(const Duration(milliseconds: 800));

      // 尋找對應的測試餐廳
      final restaurantData = _testRestaurants.firstWhere(
        (restaurant) => restaurant['id'] == placeId,
        orElse: () => _testRestaurants.first,
      );

      // 擴展詳細資訊
      final detailsData = Map<String, dynamic>.from(restaurantData);
      detailsData.addAll({
        'internationalPhoneNumber': '+886-2-8101-8888',
        'nationalPhoneNumber': '02-8101-8888',
        'websiteUri': 'https://example-restaurant.com',
        'googleMapsUri': 'https://maps.google.com/?cid=fake-restaurant-id',
        'editorialSummary': {'text': '這是一家提供優質餐點的測試餐廳，專為 E2E 測試而設計。'},
        'reviews': [
          {
            'name': 'fake-review-1',
            'relativePublishTimeDescription': '1 個月前',
            'rating': 5,
            'text': {'text': '很棒的測試餐廳！E2E 測試通過。', 'languageCode': 'zh-TW'},
            'originalText': {
              'text': '很棒的測試餐廳！E2E 測試通過。',
              'languageCode': 'zh-TW',
            },
            'authorAttribution': {
              'displayName': '測試用戶',
              'uri': 'https://www.google.com/maps/contrib/fake-user',
              'photoUri': 'https://example.com/test-user-avatar.jpg',
            },
            'publishTime': DateTime.now()
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          },
        ],
      });

      final placeDetails = PlaceDetails.fromJson(detailsData);

      debugPrint('✅ FakePlacesService: 詳細資訊取得成功');
      return placeDetails;
    } catch (e) {
      debugPrint('❌ FakePlacesService: 取得詳細資訊失敗: $e');
      rethrow;
    }
  }

  /// 隨機推薦附近餐廳 (從測試資料中隨機選擇)
  Future<Place?> getRandomNearbyRestaurant({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    try {
      debugPrint('🧪 FakePlacesService: 隨機推薦餐廳 (從測試資料選擇)');

      // 模擬搜尋延遲
      await Future.delayed(const Duration(milliseconds: 1200));

      final restaurants = await searchNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        maxResults: _testRestaurants.length,
      );

      if (restaurants.isEmpty) {
        debugPrint('⚠️ FakePlacesService: 無測試餐廳資料');
        return null;
      }

      // 隨機選擇一家餐廳
      final random = Random();
      final selectedRestaurant =
          restaurants[random.nextInt(restaurants.length)];

      debugPrint('✅ FakePlacesService: 隨機推薦完成');
      debugPrint('🍽️ 推薦餐廳: ${selectedRestaurant.name}');

      return selectedRestaurant;
    } catch (e) {
      debugPrint('❌ FakePlacesService: 隨機推薦失敗: $e');
      rethrow;
    }
  }

  /// 計算兩個座標點之間的距離（模擬實作）
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // 簡化的距離計算，回傳固定值用於測試
    debugPrint('🧪 FakePlacesService: 計算距離 (回傳固定測試值)');
    return 500.0; // 固定回傳 500 公尺
  }

  /// 格式化距離文字（測試實作）
  String formatDistance(double distanceInMeters) {
    debugPrint('🧪 FakePlacesService: 格式化距離 $distanceInMeters 公尺');

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
}
