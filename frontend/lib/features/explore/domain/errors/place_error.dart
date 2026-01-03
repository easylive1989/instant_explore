import 'package:context_app/core/errors/app_error_type.dart';

/// 地點功能錯誤類型
enum PlaceError implements AppErrorType {
  /// 網路連線錯誤
  networkError,

  /// API 配置錯誤
  configurationError,

  /// 伺服器錯誤
  serverError,

  /// 地點未找到
  notFound,

  /// 搜尋失敗
  searchFailed,

  /// 快取錯誤
  cacheError,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'PLACE_${name.toUpperCase()}';
}
