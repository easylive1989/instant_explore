import 'dart:async';
import 'dart:io';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/core/domain/models/language.dart' as app_lang;
import 'package:google_generative_ai/google_generative_ai.dart';

/// 開始導覽用例
///
/// 負責生成導覽內容
/// 遵循 Clean Architecture Use Case 模式
class StartNarrationUseCase {
  final NarrationService _narrationService;

  StartNarrationUseCase(this._narrationService);

  /// 執行用例：生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回生成的 NarrationContent
  /// 拋出異常如果生成失敗
  Future<NarrationContent> execute({
    required Place place,
    required NarrationAspect aspect,
    String language = 'zh-TW',
  }) async {
    try {
      // 使用 NarrationService 生成並返回導覽內容
      return await _narrationService.generateNarration(
        place: place,
        aspect: aspect,
        language: app_lang.Language.fromString(language),
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
