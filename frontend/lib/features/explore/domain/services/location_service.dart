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
}
