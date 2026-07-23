import 'package:context_app/features/explore/domain/models/place_location.dart';

/// 位置服務介面
///
/// 定義獲取使用者位置的抽象方法
/// 實作類別需要實作此介面以提供具體的位置獲取邏輯
abstract class LocationService {
  /// 獲取當前使用者位置
  ///
  /// 回傳包含經緯度資訊的 [PlaceLocation] 物件
  /// 如果位置服務未啟用或權限被拒絕，會拋出錯誤
  Future<PlaceLocation> getCurrentLocation();

  /// 請求定位權限；回傳是否已取得（whileInUse / always 視為已授權）。
  Future<bool> requestPermission();

  /// 開啟系統的 App 設定頁（永久拒絕時引導使用者手動開啟）。
  Future<void> openAppSettings();

  /// 開啟系統的定位服務設定頁（定位服務關閉時引導開啟）。
  Future<void> openLocationSettings();
}
