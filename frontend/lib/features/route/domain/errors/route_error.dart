import 'package:context_app/core/errors/app_error_type.dart';

/// 路線規劃相關錯誤類型
enum RouteError implements AppErrorType {
  /// 附近景點數量不足（需至少 3 個）
  insufficientPlaces,

  /// AI 回傳的 JSON 無法解析
  aiParsingFailed,

  /// AI 回傳的 placeId 不在候選清單中
  invalidPlaceId,

  /// 網路錯誤
  networkError,

  /// 每日額度已用完
  quotaExceeded,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'ROUTE_${name.toUpperCase()}';
}
