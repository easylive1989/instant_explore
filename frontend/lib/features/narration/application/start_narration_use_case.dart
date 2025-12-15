import 'dart:async';
import 'dart:io';

import 'package:context_app/core/services/gemini_service.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/application/narration_generation_exception.dart';
import 'package:context_app/features/narration/models/narration.dart';
import 'package:context_app/features/narration/models/narration_content.dart';
import 'package:context_app/features/narration/models/narration_error_type.dart';
import 'package:context_app/features/narration/models/narration_style.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

/// 開始導覽用例
///
/// 負責生成導覽內容並初始化播放器
/// 遵循 Clean Architecture Use Case 模式
class StartNarrationUseCase {
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
    try {
      // 1. 建立初始的 Narration 聚合（loading 狀態）
      final narration = Narration.create(
        id: _uuid.v4(),
        place: place,
        style: style,
      );

      // 2. 使用 GeminiService 生成導覽內容
      final generatedText = await _geminiService.generateNarration(
        place: place,
        style: style,
        language: language,
      );

      if (generatedText.isEmpty) {
        throw NarrationGenerationException.contentFailed(
          rawMessage: 'Generated narration text is empty',
        );
      }

      // 3. 建立 NarrationContent 值對象
      final content = NarrationContent.fromText(
        generatedText,
        language: language,
      );

      // 4. 初始化 TtsService
      await _ttsService.initialize();

      // 設定 TTS 語言
      await _ttsService.setLanguage(language);

      // 5. 更新 Narration 為 ready 狀態
      final readyNarration = narration.ready(content);

      return readyNarration;
    } on NarrationGenerationException {
      // 已經是我們的異常，直接重新拋出
      rethrow;
    } on InvalidApiKey catch (e) {
      throw NarrationGenerationException.configuration(
        rawMessage: 'Invalid API key: ${e.toString()}',
      );
    } on UnsupportedUserLocation catch (e) {
      throw NarrationGenerationException.unsupportedLocation(
        rawMessage: 'Unsupported location: ${e.toString()}',
      );
    } on ServerException catch (e) {
      // 檢查是否為配額超限錯誤
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('resource_exhausted') ||
          errorString.contains('429') ||
          errorString.contains('quota exceeded') ||
          errorString.contains('rate limit')) {
        throw NarrationGenerationException.quotaExceeded(
          rawMessage: e.toString(),
          retryAfterSeconds: 900, // 15 分鐘
        );
      }
      throw NarrationGenerationException.server(rawMessage: e.toString());
    } on SocketException catch (e) {
      throw NarrationGenerationException.network(rawMessage: e.toString());
    } on TimeoutException catch (e) {
      throw NarrationGenerationException.network(rawMessage: e.toString());
    } catch (e) {
      throw NarrationGenerationException(
        type: NarrationErrorType.unknown,
        rawMessage: e.toString(),
      );
    }
  }
}
