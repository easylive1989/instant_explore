import 'package:geolocator/geolocator.dart';

/// 位置服務介面
///
/// 定義所有位置相關功能的介面
/// 可以被真實位置服務或 Fake 位置服務實作
abstract interface class ILocationService {
  /// 檢查位置權限狀態
  Future<LocationPermission> checkPermission();

  /// 請求位置權限
  Future<LocationPermission> requestPermission();

  /// 檢查位置服務是否已啟用
  Future<bool> isLocationServiceEnabled();

  /// 確保位置權限已取得
  ///
  /// 回傳 true 表示有權限，false 表示無權限
  Future<bool> ensureLocationPermission();

  /// 取得使用者當前位置
  ///
  /// [accuracy] 位置精度設定，預設為高精度
  /// [timeoutDuration] 超時時間，預設為15秒
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeoutDuration = const Duration(seconds: 15),
  });

  /// 監聽位置變化
  ///
  /// [accuracy] 位置精度設定
  /// [distanceFilter] 最小移動距離（公尺）
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  });

  /// 開啟系統位置設定頁面
  Future<bool> openLocationSettings();

  /// 開啟應用程式設定頁面
  Future<bool> openAppSettings();

  /// 取得位置權限狀態的描述文字
  String getPermissionDescription(LocationPermission permission);
}
