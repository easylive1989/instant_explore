import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_exception.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

/// 開始導覽用例
///
/// 負責生成導覽內容並組成 NarrationContent
/// 遵循 Clean Architecture Use Case 模式
///
/// 職責：
/// - 呼叫 NarrationService 取得導覽文本
/// - 組成並驗證 NarrationContent
/// - 處理屬於 UseCase 層級的錯誤（如內容驗證失敗）
///
/// 不處理的錯誤（透傳 NarrationServiceException）：
/// - AI 配額超限
/// - 地理位置不支援
/// - 網路錯誤
/// - 伺服器錯誤
/// - API 配置錯誤
class CreateNarrationUseCase {
  final NarrationService _narrationService;

  CreateNarrationUseCase(this._narrationService);

  /// 執行用例：生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言代碼（預設為 'zh-TW'）
  /// 返回生成的 NarrationContent
  ///
  /// 可能拋出：
  /// - NarrationServiceException: AI 服務相關錯誤（透傳）
  /// - NarrationException: UseCase 層級的錯誤（如驗證失敗）
  Future<NarrationContent> execute({
    required Place place,
    required NarrationAspect aspect,
    String language = 'zh-TW',
  }) async {
    // 呼叫 NarrationService 取得導覽文本
    // NarrationServiceException 會直接透傳給上層
    final text = await _narrationService.generateNarration(
      place: place,
      aspect: aspect,
      language: app_lang.Language.fromString(language),
    );

    // 驗證並組成 NarrationContent
    return _createNarrationContent(text, language);
  }

  /// 驗證並組成 NarrationContent
  NarrationContent _createNarrationContent(String text, String language) {
    // 驗證文本不為空
    if (text.trim().isEmpty) {
      throw NarrationException.contentFailed(
        rawMessage: 'Generated narration text is empty',
      );
    }

    // 驗證文本長度（最少需要 10 個字符）
    if (text.trim().length < 10) {
      throw NarrationException.contentFailed(
        rawMessage: 'Generated narration is too short: ${text.length} chars',
      );
    }

    // 組成 NarrationContent
    final content = NarrationContent.fromText(text, language: language);

    // 驗證分段結果
    if (content.segments.isEmpty) {
      throw NarrationException.contentFailed(
        rawMessage: 'Failed to segment narration content',
      );
    }

    return content;
  }
}
