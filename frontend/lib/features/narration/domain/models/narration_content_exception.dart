/// 導覽內容異常
///
/// 用於 UseCase 層級的內容驗證錯誤
/// 服務層錯誤由 NarrationServiceException 處理
class NarrationContentException implements Exception {
  /// 原始錯誤訊息（用於 debug 和日誌記錄）
  final String? rawMessage;

  const NarrationContentException({this.rawMessage});

  /// 建立內容驗證失敗異常
  factory NarrationContentException.contentFailed({String? rawMessage}) {
    return NarrationContentException(rawMessage: rawMessage);
  }

  @override
  String toString() {
    final buffer = StringBuffer('NarrationContentException');
    if (rawMessage != null) buffer.write('(rawMessage: $rawMessage)');
    return buffer.toString();
  }
}
