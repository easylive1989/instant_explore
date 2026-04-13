import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:context_app/features/usage/domain/errors/usage_error.dart';

/// 建立導覽用例
///
/// 負責生成導覽內容並組成 NarrationContent
/// 遵循 Clean Architecture Use Case 模式
///
/// 職責：
/// - 檢查每日使用額度
/// - 呼叫 NarrationService 取得導覽文本
/// - 使用 NarrationContent.create 組成內容
/// - 消耗使用額度
///
/// 錯誤處理：
/// - AppError(UsageError.dailyQuotaExceeded): 每日額度已用完
/// - AppError(NarrationError.*): AI 服務相關錯誤（透傳自 Service）
/// - AppError(NarrationError.contentGenerationFailed): 內容驗證失敗
class CreateNarrationUseCase {
  final NarrationService _narrationService;
  final UsageRepository _usageRepository;

  CreateNarrationUseCase(this._narrationService, this._usageRepository);

  /// 執行用例：生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspects] 導覽介紹面向（支援多選）
  /// [language] 語言
  /// 返回生成的 NarrationContent
  ///
  /// 可能拋出 AppError：
  /// - UsageError.dailyQuotaExceeded: 每日額度已用完
  /// - NarrationError.*: AI 服務相關錯誤（透傳）
  /// - NarrationError.contentGenerationFailed: 內容驗證失敗
  Future<NarrationContent> execute({
    required Place place,
    required Set<NarrationAspect> aspects,
    required Language language,
  }) async {
    // 1. 檢查每日使用額度
    final usageStatus = await _usageRepository.getUsageStatus();
    if (!usageStatus.canUseNarration) {
      throw const AppError(type: UsageError.dailyQuotaExceeded);
    }

    // 2. 呼叫 NarrationService 取得導覽文本
    // AppError 會直接透傳給上層
    final text = await _narrationService.generateNarration(
      place: place,
      aspects: aspects,
      language: language,
    );

    // 3. 使用 NarrationContent.create 組成並驗證內容
    final content = NarrationContent.create(text, language: language);

    // 4. 消耗一次使用額度
    await _usageRepository.consumeUsage();

    return content;
  }
}
