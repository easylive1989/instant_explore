import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/data/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/services/narration_service_exception.dart';
import 'package:context_app/features/narration/domain/services/narration_service_error_type.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

class GeminiService implements NarrationService {
  GeminiService();

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
      // 使用 Google AI (Gemini Developer API)
      final ai = FirebaseAI.googleAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
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
    } on FirebaseException catch (e) {
      // 處理 Firebase 相關異常
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('resource-exhausted') ||
          errorString.contains('quota-exceeded')) {
        throw NarrationServiceException.quotaExceeded(
          rawMessage: e.message ?? e.toString(),
          retryAfterSeconds: 900,
        );
      }
      throw NarrationServiceException.server(
        rawMessage: 'Firebase Error: ${e.message} (${e.code})',
      );
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
  return GeminiService();
});
