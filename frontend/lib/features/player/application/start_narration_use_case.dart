import 'package:context_app/core/services/gemini_service.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration.dart';
import 'package:context_app/features/player/models/narration_content.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// 開始導覽用例
///
/// 負責生成導覽內容並初始化播放器
/// 遵循 Clean Architecture Use Case 模式
class StartNarrationUseCase {
  final _log = Logger('StartNarrationUseCase');
  final GeminiService _geminiService;
  final TtsService _ttsService;
  final _uuid = const Uuid();

  StartNarrationUseCase(this._geminiService, this._ttsService);

  /// 執行用例：生成並準備導覽
  ///
  /// [place] 地點資訊
  /// [style] 導覽風格
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回準備就緒的 Narration 聚合
  /// 拋出異常如果生成失敗
  Future<Narration> execute({
    required Place place,
    required NarrationStyle style,
    String language = 'zh-TW',
  }) async {
    _log.info('Starting narration for place: ${place.name}, style: $style');

    try {
      // 1. 建立初始的 Narration 聚合（loading 狀態）
      final narration = Narration.create(
        id: _uuid.v4(),
        place: place,
        style: style,
      );

      // 2. 使用 GeminiService 生成導覽內容
      _log.info('Generating narration content...');
      final generatedText = await _geminiService.generateNarration(
        place: place,
        style: style,
        language: language,
      );

      if (generatedText.isEmpty) {
        throw NarrationGenerationException('Generated narration text is empty');
      }

      // 3. 建立 NarrationContent 值對象
      final content = NarrationContent.fromText(generatedText);
      _log.info(
        'Narration content created: ${content.segments.length} segments, '
        '${content.estimatedDuration}s estimated duration',
      );

      // 4. 初始化 TtsService
      _log.info('Initializing TTS service...');
      await _ttsService.initialize();

      // 設定 TTS 語言
      await _ttsService.setLanguage(language);

      // 5. 更新 Narration 為 ready 狀態
      final readyNarration = narration.ready(content);

      _log.info('Narration ready to play: ${readyNarration.id}');
      return readyNarration;
    } on NarrationGenerationException {
      _log.severe('Failed to generate narration content');
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to start narration', e, stackTrace);
      throw NarrationGenerationException(
        'Failed to generate narration: ${e.toString()}',
      );
    }
  }
}

/// 導覽生成異常
///
/// 當導覽內容生成失敗時拋出
class NarrationGenerationException implements Exception {
  final String message;

  NarrationGenerationException(this.message);

  @override
  String toString() => 'NarrationGenerationException: $message';
}
