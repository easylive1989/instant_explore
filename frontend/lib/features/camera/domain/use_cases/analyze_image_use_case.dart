import 'dart:typed_data';

import 'package:context_app/features/camera/data/image_analysis_service.dart';
import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:uuid/uuid.dart';

/// 分析圖片用例
///
/// 負責執行圖片分析並將結果轉換為 Place 物件
class AnalyzeImageUseCase {
  final ImageAnalysisService _analysisService;

  AnalyzeImageUseCase(this._analysisService);

  /// 執行用例：分析圖片並建立 Place 物件
  ///
  /// [imageBytes] 圖片的二進位資料
  /// [mimeType] 圖片的 MIME 類型
  /// [language] 語言代碼
  /// 返回包含分析結果的 Place 物件
  Future<Place> execute({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    final result = await _analysisService.analyzeImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      language: language,
    );

    return _createPlaceFromResult(result);
  }

  Place _createPlaceFromResult(ImageAnalysisResult result) {
    // 產生唯一 ID（以 camera_ 前綴標識為相機拍攝的景點）
    final uuid = const Uuid();
    final id = 'camera_${uuid.v4()}';

    return Place(
      id: id,
      name: result.name,
      formattedAddress: result.address ?? '由相機拍攝',
      location: PlaceLocation(latitude: 0, longitude: 0),
      types: result.types,
      photos: [],
      category: result.category,
    );
  }
}
