import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/data/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

class GeminiService implements NarrationService {
  GeminiService();

  /// 生成地點導覽內容
  ///
  /// [place] 地點資訊
  /// [aspects] 導覽介紹面向（支援多選）
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  /// 返回適合語音播放的導覽文本
  @override
  Future<String> generateNarration({
    required Place place,
    required Set<NarrationAspect> aspects,
    required app_lang.Language language,
  }) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
      );

      // 使用 NarrationPromptBuilder 建立提示詞
      final promptBuilder = NarrationPromptBuilder(
        place: place,
        aspects: aspects,
        language: language.code,
      );
      final prompt = promptBuilder.build();

      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? '';

      return generatedText;
    } on FirebaseException catch (e, stackTrace) {
      throw AppError(
        type: NarrationError.serverError,
        message: 'Firebase 伺服器錯誤',
        originalException: e,
        stackTrace: stackTrace,
        context: {'firebase_code': e.code, 'firebase_message': e.message},
      );
    } on SocketException catch (e, stackTrace) {
      throw AppError(
        type: NarrationError.networkError,
        message: '網路連線失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (e, stackTrace) {
      throw AppError(
        type: NarrationError.networkError,
        message: '連線逾時',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AppError(
        type: NarrationError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
