import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 圖片分析服務
///
/// 使用 Firebase AI (Gemini) 分析圖片內容，識別景點或食物
class ImageAnalysisService {
  ImageAnalysisService();

  /// 分析圖片並返回識別結果
  ///
  /// [imageBytes] 圖片的二進位資料
  /// [mimeType] 圖片的 MIME 類型（如 'image/jpeg'）
  /// [language] 語言代碼（'zh-TW' 或 'en-US'）
  Future<ImageAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String language = 'zh-TW',
  }) async {
    try {
      final ai = FirebaseAI.googleAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
      );

      final prompt = _buildPrompt(language);

      final response = await model.generateContent([
        Content.multi([InlineDataPart(mimeType, imageBytes), TextPart(prompt)]),
      ]);

      final generatedText = response.text ?? '';
      debugPrint('Image analysis response: $generatedText');

      return _parseResponse(generatedText);
    } on SocketException catch (e) {
      throw ImageAnalysisException(
        type: ImageAnalysisErrorType.network,
        message: e.toString(),
      );
    } on TimeoutException catch (e) {
      throw ImageAnalysisException(
        type: ImageAnalysisErrorType.network,
        message: e.toString(),
      );
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      throw ImageAnalysisException(
        type: ImageAnalysisErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  String _buildPrompt(String language) {
    final isZhTw = language.startsWith('zh');

    if (isZhTw) {
      return '''
請分析這張圖片，判斷這是什麼景點、建築物、食物或物品。

請以 JSON 格式回覆，包含以下欄位：
- name: 識別出的名稱（如「龍山寺」、「珍珠奶茶」）
- description: 50 字以內的簡短描述
- category: 分類，只能是以下之一：historical_cultural, natural_landscape, modern_urban, museum_art, food_market
- address: 如果是知名景點，提供地址；否則為 null
- types: 相關的類型標籤陣列（如 ["temple", "religious_site"]）

只回覆 JSON，不要有其他文字。
''';
    } else {
      return '''
Please analyze this image and identify what landmark, building, food, or object it shows.

Respond in JSON format with the following fields:
- name: The identified name (e.g., "Eiffel Tower", "Bubble Tea")
- description: A brief description within 50 words
- category: Category, must be one of: historical_cultural, natural_landscape, modern_urban, museum_art, food_market
- address: If it's a famous landmark, provide the address; otherwise null
- types: Array of related type tags (e.g., ["tower", "landmark"])

Only respond with JSON, no other text.
''';
    }
  }

  ImageAnalysisResult _parseResponse(String responseText) {
    try {
      // 嘗試從回應中提取 JSON
      var jsonText = responseText.trim();

      // 移除可能的 markdown 程式碼區塊標記
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      final name = json['name'] as String? ?? '未知';
      final description = json['description'] as String? ?? '';
      final categoryStr = json['category'] as String? ?? 'modern_urban';
      final address = json['address'] as String?;
      final types =
          (json['types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final category =
          PlaceCategory.fromString(categoryStr) ?? PlaceCategory.modernUrban;

      return ImageAnalysisResult(
        name: name,
        description: description,
        category: category,
        address: address,
        types: types,
      );
    } catch (e) {
      debugPrint('Error parsing response: $e');
      // 如果解析失敗，返回預設結果
      return const ImageAnalysisResult(
        name: '未知景點',
        description: '無法識別此圖片內容',
        category: PlaceCategory.modernUrban,
        types: [],
      );
    }
  }
}

/// 圖片分析錯誤類型
enum ImageAnalysisErrorType { network, quotaExceeded, unknown }

/// 圖片分析異常
class ImageAnalysisException implements Exception {
  final ImageAnalysisErrorType type;
  final String message;

  const ImageAnalysisException({required this.type, required this.message});

  @override
  String toString() => 'ImageAnalysisException: $type - $message';
}
