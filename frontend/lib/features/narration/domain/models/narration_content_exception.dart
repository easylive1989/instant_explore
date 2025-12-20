import 'package:context_app/features/narration/domain/models/narration_error_type.dart';

/// 導覽 UseCase 異常
///
/// 用於 UseCase 層級的錯誤，例如內容驗證失敗
/// 服務層錯誤由 NarrationServiceException 處理
class NarrationContentException implements Exception {
  /// 錯誤類型
  final NarrationErrorType type;

  /// 原始錯誤訊息（用於 debug 和日誌記錄）
  final String? rawMessage;

  const NarrationContentException({required this.type, this.rawMessage});

  /// 建立內容驗證失敗異常
  factory NarrationContentException.contentFailed({String? rawMessage}) {
    return NarrationContentException(
      type: NarrationErrorType.contentGenerationFailed,
      rawMessage: rawMessage,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('NarrationException(type: $type');
    if (rawMessage != null) buffer.write(', rawMessage: $rawMessage');
    buffer.write(')');
    return buffer.toString();
  }
}
