import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/story_hook_prompt_builder.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/domain/services/story_hook_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

class GeminiStoryHookService implements StoryHookService {
  GeminiStoryHookService();

  @override
  Future<List<StoryHook>> generateHooks({
    required Place place,
    required Language language,
  }) async {
    try {
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        tools: [Tool.googleSearch()],
      );

      final prompt = StoryHookPromptBuilder(
        place: place,
        language: language.code,
      ).build();

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      return _parseHooks(raw);
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
        message: '產生故事鉤子時發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<StoryHook> _parseHooks(String raw) {
    if (raw.trim().isEmpty) return const [];

    final jsonText = _extractJsonArray(raw);
    if (jsonText == null) return const [];

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) return const [];
      final hooks = <StoryHook>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final id = map['id'] as String?;
        final title = (map['title'] as String?)?.trim();
        final teaser = (map['teaser'] as String?)?.trim();
        if (id == null || id.isEmpty) continue;
        if (title == null || title.isEmpty) continue;
        if (teaser == null || teaser.isEmpty) continue;
        hooks.add(StoryHook(id: id, title: title, teaser: teaser));
      }
      return hooks;
    } on FormatException {
      return const [];
    }
  }

  /// 模型有時會在 JSON 外包裹 ```json ``` 圍欄或前言。
  /// 擷取第一個 `[` 到最後一個 `]` 之間的內容。
  String? _extractJsonArray(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }
}
