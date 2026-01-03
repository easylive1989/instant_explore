import 'package:context_app/core/errors/app_error_type.dart';

/// 統一的應用程式錯誤類別
///
/// 所有 Service 和 Repository 層應捕獲原始錯誤並轉換為 AppError
/// 提供完整的錯誤上下文資訊用於除錯
class AppError implements Exception {
  /// 錯誤類型（實作 AppErrorType 的 Enum）
  final AppErrorType type;

  /// 給使用者看的友善訊息（可選）
  /// 如果為 null，UI 層應根據 type 決定顯示的訊息
  final String? message;

  /// 原始異常物件
  /// 保留原始錯誤資訊用於除錯和日誌記錄
  final dynamic originalException;

  /// 原始錯誤堆疊
  /// 用於追蹤錯誤發生的位置
  final StackTrace? stackTrace;

  /// 額外的上下文資訊
  /// 例如：API 請求參數、使用者 ID 等
  final Map<String, dynamic>? context;

  const AppError({
    required this.type,
    this.message,
    this.originalException,
    this.stackTrace,
    this.context,
  });

  /// 錯誤代碼（來自 type）
  String get code => type.code;

  @override
  String toString() {
    final buffer = StringBuffer('AppError(');
    buffer.write('type: ${type.code}');
    if (message != null) buffer.write(', message: $message');
    if (originalException != null) {
      buffer.write(', original: $originalException');
    }
    if (context != null) buffer.write(', context: $context');
    buffer.write(')');
    return buffer.toString();
  }

  /// 建立帶有額外上下文的新錯誤
  AppError copyWith({
    AppErrorType? type,
    String? message,
    dynamic originalException,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: type ?? this.type,
      message: message ?? this.message,
      originalException: originalException ?? this.originalException,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}
