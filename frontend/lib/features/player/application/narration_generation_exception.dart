import 'package:context_app/features/player/models/narration_error_type.dart';

/// 導覽生成異常
///
/// 攜帶錯誤類型和上下文資訊，但不包含 UI 層邏輯
class NarrationGenerationException implements Exception {
  /// 錯誤類型
  final NarrationErrorType type;

  /// 原始錯誤訊息（用於 debug 和日誌記錄）
  final String? rawMessage;

  /// 額外的上下文資訊
  final Map<String, dynamic>? context;

  const NarrationGenerationException({
    required this.type,
    this.rawMessage,
    this.context,
  });

  /// 建立 AI 配額超限異常
  factory NarrationGenerationException.quotaExceeded({
    String? rawMessage,
    int? retryAfterSeconds,
  }) {
    return NarrationGenerationException(
      type: NarrationErrorType.aiQuotaExceeded,
      rawMessage: rawMessage,
      context: retryAfterSeconds != null
          ? {'retryAfterSeconds': retryAfterSeconds}
          : null,
    );
  }

  /// 建立網路錯誤異常
  factory NarrationGenerationException.network({String? rawMessage}) {
    return NarrationGenerationException(
      type: NarrationErrorType.networkError,
      rawMessage: rawMessage,
    );
  }

  /// 建立配置錯誤異常
  factory NarrationGenerationException.configuration({String? rawMessage}) {
    return NarrationGenerationException(
      type: NarrationErrorType.configurationError,
      rawMessage: rawMessage,
    );
  }

  /// 建立伺服器錯誤異常
  factory NarrationGenerationException.server({
    String? rawMessage,
    int? statusCode,
  }) {
    return NarrationGenerationException(
      type: NarrationErrorType.serverError,
      rawMessage: rawMessage,
      context: statusCode != null ? {'statusCode': statusCode} : null,
    );
  }

  /// 建立地理位置不支援異常
  factory NarrationGenerationException.unsupportedLocation({
    String? rawMessage,
  }) {
    return NarrationGenerationException(
      type: NarrationErrorType.unsupportedLocation,
      rawMessage: rawMessage,
    );
  }

  /// 建立內容生成失敗異常
  factory NarrationGenerationException.contentFailed({String? rawMessage}) {
    return NarrationGenerationException(
      type: NarrationErrorType.contentGenerationFailed,
      rawMessage: rawMessage,
    );
  }

  /// 取得重試等待時間（秒）
  int? get retryAfterSeconds {
    if (context != null && context!.containsKey('retryAfterSeconds')) {
      return context!['retryAfterSeconds'] as int?;
    }
    return type.suggestedRetryDelay;
  }

  /// 取得 HTTP 狀態碼（如果有）
  int? get statusCode => context?['statusCode'] as int?;

  @override
  String toString() {
    final buffer = StringBuffer('NarrationGenerationException(type: $type');
    if (rawMessage != null) buffer.write(', rawMessage: $rawMessage');
    if (context != null && context!.isNotEmpty) {
      buffer.write(', context: $context');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
