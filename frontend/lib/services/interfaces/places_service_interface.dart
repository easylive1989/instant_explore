import '../../features/places/models/place.dart';
import '../../features/places/models/place_details.dart';

/// Places 服務介面
///
/// 定義所有地點相關功能的介面
/// 可以被真實 Places 服務或 Fake Places 服務實作
abstract interface class IPlacesService {
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
  });

  /// 取得地點詳細資訊
  ///
  /// [placeId] 地點 ID
  Future<PlaceDetails> getPlaceDetails(String placeId);

  /// 隨機推薦附近餐廳
  ///
  /// [latitude] 緯度
  /// [longitude] 經度
  /// [radius] 搜尋半徑（公尺），預設 2000 公尺
  Future<Place?> getRandomNearbyRestaurant({
    required double latitude,
    required double longitude,
    double radius = 2000,
  });

  /// 計算兩個座標點之間的距離（公尺）
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);

  /// 格式化距離文字
  ///
  /// [distanceInMeters] 距離（公尺）
  String formatDistance(double distanceInMeters);

  /// 取得照片 URL
  ///
  /// [photoName] 照片名稱
  /// [maxWidth] 最大寬度
  /// [maxHeight] 最大高度
  String getPhotoUrl({
    required String photoName,
    int? maxWidth,
    int? maxHeight,
  });

  /// 檢查 API 金鑰是否已設定
  bool get isApiKeyConfigured;
}
