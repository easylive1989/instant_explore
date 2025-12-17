import 'dart:async';
import 'dart:io';

import 'package:context_app/core/services/gemini_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

/// 開始導覽用例
///
/// 負責生成導覽內容
/// 遵循 Clean Architecture Use Case 模式
class StartNarrationUseCase {
  final GeminiService _geminiService;
  final _uuid = const Uuid();

  StartNarrationUseCase(this._geminiService);

  /// 執行用例：生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回完整的 Narration 聚合
  /// 拋出異常如果生成失敗
  Future<Narration> execute({
    required Place place,
    required NarrationAspect aspect,
    String language = 'zh-TW',
  }) async {
    try {
      // 1. 使用 GeminiService 生成導覽內容
      final generatedText = await _geminiService.generateNarration(
        place: place,
        aspect: aspect,
        language: language,
      );

      if (generatedText.isEmpty) {
        throw NarrationGenerationException.contentFailed(
          rawMessage: 'Generated narration text is empty',
        );
      }

      // 2. 建立 NarrationContent 值對象
      final content = NarrationContent.fromText(
        generatedText,
        language: language,
      );

      // 3. 建立並返回 Narration 聚合
      return Narration(
        id: _uuid.v4(),
        place: place,
        aspect: aspect,
        content: content,
      );
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
