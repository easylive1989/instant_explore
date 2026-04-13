import 'dart:typed_data';

import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';

/// 圖片分析服務介面
///
/// 定義圖片分析的抽象契約，具體實作由 data 層提供。
abstract class ImageAnalysisService {
  /// 分析圖片並返回識別結果
  ///
  /// [imageBytes] 圖片的二進位資料
  /// [mimeType] 圖片的 MIME 類型（如 'image/jpeg'）
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  Future<ImageAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  });
}

/// 圖片分析錯誤類型
enum ImageAnalysisErrorType { network, quotaExceeded, unknown }

/// 圖片分析異常
class ImageAnalysisException implements Exception {
  final ImageAnalysisErrorType type;
  final String message;

  const ImageAnalysisException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'ImageAnalysisException: $type - $message';
}
