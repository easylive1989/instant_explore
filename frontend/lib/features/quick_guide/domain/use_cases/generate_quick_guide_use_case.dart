import 'dart:typed_data';

import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/domain/services/quick_guide_ai_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';

/// 快速導覽生成結果
sealed class GenerateQuickGuideResult {}

/// 生成成功
class GenerateQuickGuideSuccess extends GenerateQuickGuideResult {
  final QuickGuideEntry entry;
  GenerateQuickGuideSuccess(this.entry);
}

/// 每日額度已用完
class GenerateQuickGuideQuotaExceeded extends GenerateQuickGuideResult {}

/// 產生快速導覽的用例
///
/// 負責完整的業務流程：
/// 1. 檢查使用額度
/// 2. 呼叫 AI 產生描述
/// 3. 建立 [QuickGuideEntry] 並儲存
/// 4. 消耗使用額度
class GenerateQuickGuideUseCase {
  final QuickGuideAiService _aiService;
  final QuickGuideRepository _repository;
  final UsageRepository _usageRepository;
  final String Function() _idGenerator;
  final String? Function() _currentTripIdGetter;

  GenerateQuickGuideUseCase(
    this._aiService,
    this._repository,
    this._usageRepository,
    this._idGenerator,
    this._currentTripIdGetter,
  );

  /// 執行用例
  ///
  /// 回傳 [GenerateQuickGuideResult] 表示結果
  Future<GenerateQuickGuideResult> execute({
    required Uint8List imageBytes,
    required String mimeType,
    required String language,
  }) async {
    final usageStatus = await _usageRepository.getUsageStatus();
    if (!usageStatus.canUseNarration) {
      return GenerateQuickGuideQuotaExceeded();
    }

    final description = await _aiService.describeImage(
      imageBytes: imageBytes,
      mimeType: mimeType,
      language: language,
    );

    final entry = QuickGuideEntry.create(
      id: _idGenerator(),
      imageBytes: imageBytes,
      aiDescription: description,
      language: Language(language),
      tripId: _currentTripIdGetter(),
    );
    await _repository.save(entry);
    await _usageRepository.consumeUsage();

    return GenerateQuickGuideSuccess(entry);
  }
}
