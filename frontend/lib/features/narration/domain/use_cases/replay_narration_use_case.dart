import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';
import 'package:uuid/uuid.dart';

/// 重播導覽用例
///
/// 負責準備重播導覽內容並初始化播放器
class ReplayNarrationUseCase {
  final TtsService _ttsService;
  final _uuid = const Uuid();

  ReplayNarrationUseCase(this._ttsService);

  /// 執行用例：準備重播導覽
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [contentText] 導覽內容文字
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回準備就緒的 Narration 聚合
  Future<Narration> execute({
    required Place place,
    required NarrationAspect aspect,
    required String contentText,
    String language = 'zh-TW',
  }) async {
    try {
      // 1. 建立初始的 Narration 聚合
      final narration = Narration.create(
        id: _uuid.v4(),
        place: place,
        aspect: aspect,
      );

      // 2. 建立 NarrationContent 值對象
      final content = NarrationContent.fromText(
        contentText,
        language: language,
      );

      // 3. 初始化 TtsService
      await _ttsService.initialize();
      await _ttsService.setLanguage(language);

      // 4. 更新 Narration 為 ready 狀態
      final readyNarration = narration.ready(content);

      return readyNarration;
    } catch (e) {
      throw NarrationGenerationException(
        type: NarrationErrorType.unknown,
        rawMessage: e.toString(),
      );
    }
  }
}
