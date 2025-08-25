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

  // 單一測試餐廳資料
  static final Map<String, dynamic> _testRestaurant = {
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
  };

  /// 搜尋附近的餐廳 (回傳預設測試資料)
  Future<List<Place>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 2000,
    int maxResults = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [Place.fromJson(_testRestaurant)];
  }

  /// 取得地點詳細資訊 (回傳預設測試資料)
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final detailsData = Map<String, dynamic>.from(_testRestaurant);
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

    return PlaceDetails.fromJson(detailsData);
  }

  /// 隨機推薦附近餐廳 (從測試資料中隨機選擇)
  Future<Place?> getRandomNearbyRestaurant({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return Place.fromJson(_testRestaurant);
  }

  /// 計算兩個座標點之間的距離（模擬實作）
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return 500.0; // 固定回傳 500 公尺
  }

  /// 格式化距離文字（測試實作）
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
}
