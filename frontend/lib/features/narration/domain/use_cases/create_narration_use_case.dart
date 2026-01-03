import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:context_app/features/subscription/domain/errors/subscription_error.dart';

/// 建立導覽用例
///
/// 負責生成導覽內容並組成 NarrationContent
/// 遵循 Clean Architecture Use Case 模式
///
/// 職責：
/// - 檢查用戶權益狀態
/// - 呼叫 NarrationService 取得導覽文本
/// - 使用 NarrationContent.create 組成內容
/// - 消耗免費額度（如果適用）
///
/// 錯誤處理：
/// - AppError(SubscriptionError.freeQuotaExceeded): 免費額度已用完
/// - AppError(NarrationError.*): AI 服務相關錯誤（透傳自 Service）
/// - AppError(NarrationError.contentGenerationFailed): 內容驗證失敗
class CreateNarrationUseCase {
  final NarrationService _narrationService;
  final EntitlementRepository _entitlementRepository;

  CreateNarrationUseCase(this._narrationService, this._entitlementRepository);

  /// 執行用例：生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言
  /// 返回生成的 NarrationContent
  ///
  /// 可能拋出 AppError：
  /// - SubscriptionError.freeQuotaExceeded: 免費額度已用完
  /// - NarrationError.*: AI 服務相關錯誤（透傳）
  /// - NarrationError.contentGenerationFailed: 內容驗證失敗
  Future<NarrationContent> execute({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  }) async {
    // 1. 檢查用戶權益
    final entitlement = await _entitlementRepository.getEntitlement();
    if (!entitlement.canUseNarration) {
      throw const AppError(type: SubscriptionError.freeQuotaExceeded);
    }

    // 2. 呼叫 NarrationService 取得導覽文本
    // AppError 會直接透傳給上層
    final text = await _narrationService.generateNarration(
      place: place,
      aspect: aspect,
      language: language,
    );

    // 3. 使用 NarrationContent.create 組成並驗證內容
    try {
      final content = NarrationContent.create(text, language: language);

      // 4. 如果是免費用戶，消耗一次免費額度
      if (!entitlement.isUnlimited) {
        await _entitlementRepository.consumeFreeUsage();
      }

      return content;
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: NarrationError.contentGenerationFailed,
        message: '內容生成失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
