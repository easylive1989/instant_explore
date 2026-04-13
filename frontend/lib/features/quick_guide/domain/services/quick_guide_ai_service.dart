import 'dart:typed_data';

/// AI 圖片描述服務介面
///
/// 定義圖片描述生成的抽象契約，具體實作由 data 層提供。
abstract class QuickGuideAiService {
  /// 分析 [imageBytes] 並回傳自然語言描述
  ///
  /// [mimeType] 必須為有效的圖片 MIME 類型（如 `image/jpeg`）。
  /// [language] 為 BCP-47 語言標籤，如 `zh-TW` 或 `en-US`。
  Future<String> describeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  });
}

/// [QuickGuideAiService] 實作可能拋出的錯誤類型
enum QuickGuideAiErrorType { network, quotaExceeded, unknown }

/// [QuickGuideAiService] 實作拋出的異常
class QuickGuideAiException implements Exception {
  final QuickGuideAiErrorType type;
  final String message;

  const QuickGuideAiException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'QuickGuideAiException($type): $message';
}
