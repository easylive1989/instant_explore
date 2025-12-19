import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';

/// 重播導覽用例
///
/// 負責準備重播導覽內容
class ReplayNarrationUseCase {
  ReplayNarrationUseCase();

  /// 執行用例：準備重播導覽
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [contentText] 導覽內容文字
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回生成的 NarrationContent
  Future<NarrationContent> execute({
    required Place place,
    required NarrationAspect aspect,
    required String contentText,
    String language = 'zh-TW',
  }) async {
    try {
      // 建立並返回 NarrationContent 值對象
      return NarrationContent.fromText(contentText, language: language);
    } catch (e) {
      throw NarrationGenerationException(
        type: NarrationErrorType.unknown,
        rawMessage: e.toString(),
      );
    }
  }
}
