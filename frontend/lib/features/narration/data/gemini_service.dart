import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

class GeminiService implements NarrationService {
  GeminiService();

  /// 生成地點導覽內容
  ///
  /// [place] 地點資訊
  /// [hook] 使用者挑選的故事鉤子（可為 null）
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  /// 返回適合語音播放的導覽文本
  @override
  Future<NarrationGenerationResult> generateNarration({
    required Place place,
    required app_lang.Language language,
    StoryHook? hook,
  }) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
      );

      final prompt = NarrationPromptBuilder(
        place: place,
        hook: hook,
        language: language.code,
      ).build();

      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? '';
      final grounding = GroundingInfo.fromCandidate(
        response.candidates.isNotEmpty ? response.candidates.first : null,
      );

      return (text: generatedText, grounding: grounding);
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
