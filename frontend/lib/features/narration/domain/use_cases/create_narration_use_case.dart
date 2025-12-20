import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

/// 建立導覽用例
///
/// 負責生成導覽內容並組成 NarrationContent
/// 遵循 Clean Architecture Use Case 模式
///
/// 職責：
/// - 呼叫 NarrationService 取得導覽文本
/// - 使用 NarrationContent.create 組成內容
///
/// 錯誤處理：
/// - NarrationServiceException: AI 服務相關錯誤（透傳）
/// - NarrationContentException: 內容驗證失敗（由 NarrationContent.create 拋出）
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
  /// - NarrationContentException: 內容驗證失敗
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

    // 使用 NarrationContent.create 組成並驗證內容
    // NarrationContentException 會在驗證失敗時拋出
    return NarrationContent.create(text, language: language);
  }
}
