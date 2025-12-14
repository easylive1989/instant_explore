import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/models/narration_style.dart';

class GeminiService {
  final ApiConfig _apiConfig;

  GeminiService(this._apiConfig);

  /// 生成地點導覽內容
  ///
  /// [place] 地點資訊
  /// [style] 導覽風格（brief 或 deepDive）
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  /// 返回適合語音播放的導覽文本
  Future<String> generateNarration({
    required Place place,
    required NarrationStyle style,
    required String language,
  }) async {
    if (!_apiConfig.isGeminiConfigured) {
      throw Exception('Gemini API key is not configured.');
    }

    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiConfig.geminiApiKey,
    );

    // 根據語言設定提示詞語言
    final languageName = language.startsWith('zh') ? '繁體中文' : 'English';

    // 根據風格設定字數限制
    final targetLength = style == NarrationStyle.brief ? 150 : 1500;
    final estimatedDuration = style == NarrationStyle.brief ? '30 秒' : '5 分鐘';

    // 建立提示詞
    final prompt =
        '''
You are a professional tour guide creating an engaging audio narration for a location.

Location Information:
- Name: ${place.name}
- Address: ${place.formattedAddress}
- Types: ${place.types.join(', ')}
${place.rating != null ? '- Rating: ${place.rating}/5.0' : ''}

Requirements:
- Language: $languageName
- Style: ${style == NarrationStyle.brief ? 'Brief overview' : 'Deep dive with rich historical and cultural details'}
- Target Length: approximately $targetLength characters
- Estimated Duration: $estimatedDuration when read aloud
- Tone: Engaging, vivid, and informative - as if you're speaking to a tourist standing at the location

Content Guidelines:
${style == NarrationStyle.brief ? '''
For the brief version:
- Start with what the tourist is seeing right now
- Highlight 1-2 most interesting historical facts or cultural significance
- Use vivid, sensory language
- Keep it concise and impactful
''' : '''
For the deep dive version:
- Begin by setting the scene - what the tourist sees and feels
- Explore the historical background in detail
- Share fascinating stories, legends, or anecdotes
- Explain cultural significance and context
- Include architectural or artistic details if relevant
- Connect the past to the present
- Use storytelling techniques to keep it engaging
'''}

Format:
- Write in a conversational tone suitable for audio playback
- Use natural pauses (sentence breaks) for better listening experience
- Avoid bullet points or lists
- Write in flowing paragraphs with clear sentence endings (。！？or . ! ?)

Please generate the narration now:''';

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

      return generatedText;
    } catch (e) {
      debugPrint('Error generating narration: $e');
      rethrow;
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return GeminiService(apiConfig);
});
