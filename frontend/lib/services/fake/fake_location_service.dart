import 'package:geolocator/geolocator.dart';

/// Fake LocationService for E2E testing
///
/// 模擬位置服務，在 E2E 測試中使用
/// 回傳固定的測試位置，避免真實的位置權限和 GPS 定位
class FakeLocationService {
  static final FakeLocationService _instance = FakeLocationService._internal();
  factory FakeLocationService() => _instance;
  FakeLocationService._internal();

  // 台北101的座標作為測試位置
  static const double _testLatitude = 25.0330;
  static const double _testLongitude = 121.5654;

  /// 檢查位置權限狀態 (測試模式下總是回傳已授權)
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.whileInUse;
  }

  /// 請求位置權限 (測試模式下總是成功)
  Future<LocationPermission> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return LocationPermission.whileInUse;
  }

  /// 檢查位置服務是否已啟用 (測試模式下總是已啟用)
  Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  /// 確保位置權限已取得 (測試模式下總是成功)
  Future<bool> ensureLocationPermission() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  /// 取得使用者當前位置 (回傳固定的測試位置)
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeoutDuration = const Duration(seconds: 15),
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return Position(
      longitude: _testLongitude,
      latitude: _testLatitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 508.0, // 台北101大概高度
      altitudeAccuracy: 3.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// 監聽位置變化 (測試模式下回傳固定位置流)
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));

      yield Position(
        longitude: _testLongitude,
        latitude: _testLatitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 508.0,
        altitudeAccuracy: 3.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  /// 開啟系統位置設定頁面 (測試模式下模擬成功)
  Future<bool> openLocationSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// 開啟應用程式設定頁面 (測試模式下模擬成功)
  Future<bool> openAppSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// 取得位置權限狀態的描述文字
  String getPermissionDescription(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return '位置權限被拒絕';
      case LocationPermission.deniedForever:
        return '位置權限被永久拒絕';
      case LocationPermission.whileInUse:
        return '僅在使用應用程式時允許位置存取';
      case LocationPermission.always:
        return '始終允許位置存取';
      default:
        return '未知的權限狀態';
    }
  }
}
