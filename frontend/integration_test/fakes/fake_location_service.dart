import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';

/// 測試用的假位置服務
///
/// 回傳固定位置，避免需要 GPS 權限
class FakeLocationService implements LocationService {
  /// 預設位置（台北 101 附近）
  static const defaultLocation = PlaceLocation(
    latitude: 25.0330,
    longitude: 121.5654,
  );

  /// 可自訂的回傳位置
  PlaceLocation? customLocation;

  /// 是否模擬錯誤
  bool shouldThrowError;

  FakeLocationService({this.customLocation, this.shouldThrowError = false});

  @override
  Future<PlaceLocation> getCurrentLocation() async {
    // 模擬定位時間
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (shouldThrowError) {
      throw Exception('Location permission denied');
    }

    return customLocation ?? defaultLocation;
  }
}
