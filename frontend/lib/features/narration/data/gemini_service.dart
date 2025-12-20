import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/data/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/services/narration_service_exception.dart';
import 'package:context_app/features/narration/domain/services/narration_service_error_type.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

class GeminiService implements NarrationService {
  final ApiConfig _apiConfig;

  GeminiService(this._apiConfig);

  /// 生成地點導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  /// 返回適合語音播放的導覽文本
  @override
  Future<String> generateNarration({
    required Place place,
    required NarrationAspect aspect,
    required app_lang.Language language,
  }) async {
    try {
      if (!_apiConfig.isGeminiConfigured) {
        throw NarrationServiceException.configuration(
          rawMessage: 'Gemini API key is not configured.',
        );
      }

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiConfig.geminiApiKey,
      );

      // 使用 NarrationPromptBuilder 建立提示詞
      final promptBuilder = NarrationPromptBuilder(
        place: place,
        aspect: aspect,
        language: language.code,
      );
      final prompt = promptBuilder.build();

      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? '';

      debugPrint(
        'Generated narration (${generatedText.length} chars): '
        '${generatedText.substring(0, generatedText.length > 100 ? 100 : generatedText.length)}...',
      );

      return generatedText;
    } on NarrationServiceException {
      // 已經是我們的異常，直接重新拋出
      rethrow;
    } on InvalidApiKey catch (e) {
      throw NarrationServiceException.configuration(
        rawMessage: 'Invalid API key: ${e.toString()}',
      );
    } on UnsupportedUserLocation catch (e) {
      throw NarrationServiceException.unsupportedLocation(
        rawMessage: 'Unsupported location: ${e.toString()}',
      );
    } on ServerException catch (e) {
      // 檢查是否為配額超限錯誤
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('resource_exhausted') ||
          errorString.contains('429') ||
          errorString.contains('quota exceeded') ||
          errorString.contains('rate limit')) {
        throw NarrationServiceException.quotaExceeded(
          rawMessage: e.toString(),
          retryAfterSeconds: 900, // 15 分鐘
        );
      }
      throw NarrationServiceException.server(rawMessage: e.toString());
    } on SocketException catch (e) {
      throw NarrationServiceException.network(rawMessage: e.toString());
    } on TimeoutException catch (e) {
      throw NarrationServiceException.network(rawMessage: e.toString());
    } catch (e) {
      debugPrint('Error generating narration: $e');
      throw NarrationServiceException(
        type: NarrationServiceErrorType.unknown,
        rawMessage: e.toString(),
      );
    }
  }
}

final narrationServiceProvider = Provider<NarrationService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return GeminiService(apiConfig);
});
