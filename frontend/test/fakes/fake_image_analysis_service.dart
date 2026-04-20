import 'dart:typed_data';

import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/camera/domain/services/image_analysis_service.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

/// Fake [ImageAnalysisService] used by widget tests.
class FakeImageAnalysisService implements ImageAnalysisService {
  final ImageAnalysisResult result;
  final Exception? error;

  Uint8List? lastImageBytes;
  String? lastMimeType;
  String? lastLanguage;

  FakeImageAnalysisService({
    ImageAnalysisResult? result,
    this.error,
  }) : result = result ??
            const ImageAnalysisResult(
              name: 'Fake Landmark',
              description: 'A fake landmark used for widget tests.',
              category: PlaceCategory.modernUrban,
            );

  @override
  Future<ImageAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    lastImageBytes = imageBytes;
    lastMimeType = mimeType;
    lastLanguage = language;
    if (error != null) throw error!;
    return result;
  }
}
