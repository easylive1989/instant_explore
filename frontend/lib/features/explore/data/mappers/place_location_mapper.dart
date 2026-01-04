import 'package:context_app/features/explore/domain/models/place_location.dart';

/// PlaceLocation 的資料轉換器
///
/// 負責在 JSON 與領域模型之間進行轉換
class PlaceLocationMapper {
  /// 從 JSON 解析為 PlaceLocation
  static PlaceLocation fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  /// 轉換為 JSON
  static Map<String, dynamic> toJson(PlaceLocation location) {
    return {'latitude': location.latitude, 'longitude': location.longitude};
  }
}
