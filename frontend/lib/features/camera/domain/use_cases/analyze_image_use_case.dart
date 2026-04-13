import 'dart:typed_data';

import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/camera/domain/services/image_analysis_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';

/// 分析圖片用例
///
/// 負責執行圖片分析並將結果轉換為 Place 物件。
/// [idGenerator] 由呼叫端注入，domain 層不負責 ID 生成策略。
class AnalyzeImageUseCase {
  final ImageAnalysisService _analysisService;
  final String Function() _idGenerator;

  AnalyzeImageUseCase(this._analysisService, this._idGenerator);

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
    final id = 'camera_${_idGenerator()}';

    return Place(
      id: id,
      name: result.name,
      formattedAddress: result.address ?? '由相機拍攝',
      location: const PlaceLocation(latitude: 0, longitude: 0),
      types: result.types,
      photos: const <PlacePhoto>[],
      category: result.category,
    );
  }
}
