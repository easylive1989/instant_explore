import 'dart:async';
import 'dart:io';

import 'package:context_app/features/quick_guide/data/quick_guide_ai_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Gemini-powered implementation of [QuickGuideAiService].
///
/// Uses Firebase Vertex AI (`gemini-2.5-flash`) with Google Search grounding.
class GeminiQuickGuideAiService implements QuickGuideAiService {
  @override
  Future<String> describeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
      );

      final prompt = _buildPrompt(language);
      final response = await model.generateContent([
        Content.multi([InlineDataPart(mimeType, imageBytes), TextPart(prompt)]),
      ]);

      final text = response.text ?? '';
      debugPrint('QuickGuide AI response: $text');
      return text.trim();
    } on SocketException catch (e) {
      throw QuickGuideAiException(
        type: QuickGuideAiErrorType.network,
        message: e.toString(),
      );
    } on TimeoutException catch (e) {
      throw QuickGuideAiException(
        type: QuickGuideAiErrorType.network,
        message: e.toString(),
      );
    } catch (e) {
      debugPrint('QuickGuide AI error: $e');
      throw QuickGuideAiException(
        type: QuickGuideAiErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  String _buildPrompt(String language) {
    final isZhTw = language.startsWith('zh');
    if (isZhTw) {
      return '請仔細觀察這張照片，用 150-200 字介紹照片中的內容。'
          '如果是景點或建築物，請介紹其歷史文化背景；'
          '如果是食物，請介紹其特色與風味；'
          '如果是其他物品，請提供有趣的相關知識。'
          '請用自然流暢的繁體中文書寫，不需要標題或條列格式。';
    } else {
      return 'Please observe this photo carefully and write a 150-200 word description. '
          'If it shows a landmark or building, include its historical and cultural background. '
          'If it shows food, describe its characteristics and flavors. '
          'For other objects, provide interesting related knowledge. '
          'Write in natural, engaging English prose without headings or bullet points.';
    }
  }
}
