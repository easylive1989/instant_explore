import 'dart:typed_data';

import 'package:context_app/features/quick_guide/domain/services/quick_guide_ai_service.dart';

/// Fake [QuickGuideAiService] that returns a seeded description.
class FakeQuickGuideAiService implements QuickGuideAiService {
  final String response;
  final Exception? error;

  /// Captures the last describe request for assertion.
  Uint8List? lastImageBytes;
  String? lastMimeType;
  String? lastLanguage;

  FakeQuickGuideAiService({this.response = 'A friendly description.', this.error});

  @override
  Future<String> describeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    lastImageBytes = imageBytes;
    lastMimeType = mimeType;
    lastLanguage = language;
    if (error != null) throw error!;
    return response;
  }
}
