import 'dart:typed_data';

/// Abstract AI service for generating image descriptions.
abstract class QuickGuideAiService {
  /// Analyses [imageBytes] and returns a natural-language description.
  ///
  /// [mimeType] must be a valid image MIME type (e.g. `image/jpeg`).
  /// [language] is a BCP-47 language tag such as `zh-TW` or `en-US`.
  Future<String> describeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  });
}

/// Error types returned by [QuickGuideAiService] implementations.
enum QuickGuideAiErrorType { network, quotaExceeded, unknown }

/// Exception thrown by [QuickGuideAiService] implementations.
class QuickGuideAiException implements Exception {
  final QuickGuideAiErrorType type;
  final String message;

  const QuickGuideAiException({required this.type, required this.message});

  @override
  String toString() => 'QuickGuideAiException($type): $message';
}
