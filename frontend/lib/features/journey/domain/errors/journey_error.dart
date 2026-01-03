import 'package:context_app/core/errors/app_error_type.dart';

/// 旅程功能錯誤類型
enum JourneyError implements AppErrorType {
  /// 網路連線錯誤
  networkError,

  /// 儲存失敗
  saveFailed,

  /// 載入失敗
  loadFailed,

  /// 刪除失敗
  deleteFailed,

  /// 旅程未找到
  notFound,

  /// 權限不足
  permissionDenied,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'JOURNEY_${name.toUpperCase()}';
}
