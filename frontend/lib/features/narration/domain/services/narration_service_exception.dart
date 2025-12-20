import 'package:context_app/features/narration/domain/services/narration_service_error_type.dart';

/// 導覽服務異常
///
/// 用於 NarrationService 層，攜帶與 AI 服務呼叫相關的錯誤資訊
/// 這些錯誤不屬於 UseCase 的業務邏輯錯誤
class NarrationServiceException implements Exception {
  /// 錯誤類型
  final NarrationServiceErrorType type;

  /// 原始錯誤訊息（用於 debug 和日誌記錄）
  final String? rawMessage;

  /// 額外的上下文資訊
  final Map<String, dynamic>? context;

  const NarrationServiceException({
    required this.type,
    this.rawMessage,
    this.context,
  });

  /// 建立 AI 配額超限異常
  factory NarrationServiceException.quotaExceeded({
    String? rawMessage,
    int? retryAfterSeconds,
  }) {
    return NarrationServiceException(
      type: NarrationServiceErrorType.aiQuotaExceeded,
      rawMessage: rawMessage,
      context: retryAfterSeconds != null
          ? {'retryAfterSeconds': retryAfterSeconds}
          : null,
    );
  }

  /// 建立網路錯誤異常
  factory NarrationServiceException.network({String? rawMessage}) {
    return NarrationServiceException(
      type: NarrationServiceErrorType.networkError,
      rawMessage: rawMessage,
    );
  }

  /// 建立配置錯誤異常
  factory NarrationServiceException.configuration({String? rawMessage}) {
    return NarrationServiceException(
      type: NarrationServiceErrorType.configurationError,
      rawMessage: rawMessage,
    );
  }

  /// 建立伺服器錯誤異常
  factory NarrationServiceException.server({
    String? rawMessage,
    int? statusCode,
  }) {
    return NarrationServiceException(
      type: NarrationServiceErrorType.serverError,
      rawMessage: rawMessage,
      context: statusCode != null ? {'statusCode': statusCode} : null,
    );
  }

  /// 建立地理位置不支援異常
  factory NarrationServiceException.unsupportedLocation({String? rawMessage}) {
    return NarrationServiceException(
      type: NarrationServiceErrorType.unsupportedLocation,
      rawMessage: rawMessage,
    );
  }

  /// 取得 HTTP 狀態碼（如果有）
  int? get statusCode => context?['statusCode'] as int?;

  @override
  String toString() {
    final buffer = StringBuffer('NarrationServiceException(type: $type');
    if (rawMessage != null) buffer.write(', rawMessage: $rawMessage');
    if (context != null && context!.isNotEmpty) {
      buffer.write(', context: $context');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
