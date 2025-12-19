import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_prompt_builder.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/core/domain/models/language.dart';

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
  Future<NarrationContent> generateNarration({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  }) async {
    if (!_apiConfig.isGeminiConfigured) {
      throw Exception('Gemini API key is not configured.');
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

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final generatedText = response.text ?? '';

      if (generatedText.isEmpty) {
        throw Exception('Generated narration is empty');
      }

      debugPrint(
        'Generated narration (${generatedText.length} chars): '
        '${generatedText.substring(0, generatedText.length > 100 ? 100 : generatedText.length)}...',
      );

      return NarrationContent.fromText(generatedText, language: language.code);
    } catch (e) {
      debugPrint('Error generating narration: $e');
      rethrow;
    }
  }
}

final narrationServiceProvider = Provider<NarrationService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return GeminiService(apiConfig);
});
