import 'package:context_app/core/errors/app_error_type.dart';

/// 儲存功能錯誤類型
enum StorageError implements AppErrorType {
  /// 上傳失敗
  uploadFailed,

  /// 下載失敗
  downloadFailed,

  /// 刪除失敗
  deleteFailed,

  /// 檔案未找到
  fileNotFound,

  /// 權限不足
  permissionDenied,

  /// 儲存空間不足
  insufficientStorage,

  /// 網路連線錯誤
  networkError,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'STORAGE_${name.toUpperCase()}';
}
