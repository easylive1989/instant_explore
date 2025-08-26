import 'package:geolocator/geolocator.dart';
import 'interfaces/location_service_interface.dart';

/// 位置服務類別
///
/// 負責處理所有位置相關的功能，包括：
/// - 檢查位置權限
/// - 請求位置權限
/// - 取得使用者當前位置
/// - 監聽位置變化
class LocationService implements ILocationService {
  /// 檢查位置權限狀態
  @override
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// 請求位置權限
  @override
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// 檢查位置服務是否已啟用
  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 確保位置權限已取得
  ///
  /// 回傳 true 表示有權限，false 表示無權限
  @override
  Future<bool> ensureLocationPermission() async {
    // 檢查位置服務是否已啟用
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 檢查目前權限狀態
    LocationPermission permission = await checkPermission();

    // 如果權限被永久拒絕，無法繼續
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // 如果權限被拒絕，請求權限
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    return true;
  }

  /// 取得使用者當前位置
  ///
  /// [accuracy] 位置精度設定，預設為高精度
  /// [timeoutDuration] 超時時間，預設為15秒
  @override
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeoutDuration = const Duration(seconds: 15),
  }) async {
    try {
      // 確保有位置權限
      bool hasPermission = await ensureLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // 取得當前位置
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: 10, // 最小移動距離（公尺）
        ),
      ).timeout(timeoutDuration);

      return position;
    } catch (e) {
      // 處理錯誤（超時、無權限等）
      return null;
    }
  }

  /// 監聽位置變化
  ///
  /// [accuracy] 位置精度設定
  /// [distanceFilter] 最小移動距離（公尺）
  @override
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// 開啟系統位置設定頁面
  @override
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// 開啟應用程式設定頁面
  @override
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// 取得位置權限狀態的描述文字
  @override
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
