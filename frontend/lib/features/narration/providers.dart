import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/services/tts_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/narration/data/gemini_service.dart';
import 'package:context_app/features/narration/data/tts_service.dart'
    as tts_impl;
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/usage/providers.dart';

final narrationServiceProvider = Provider<NarrationService>((ref) {
  return GeminiService();
});

/// 導覽介紹面向選擇 Provider
///
/// 管理用戶選擇的導覽介紹面向（支援多選）
/// 預設為歷史背景（historicalBackground）
/// 使用 autoDispose 確保離開頁面時自動重置
final narrationAspectsProvider =
    StateProvider.autoDispose<Set<NarrationAspect>>((ref) {
      return {NarrationAspect.historicalBackground};
    });

/// TtsService Provider
///
/// 提供 TTS 語音合成服務
/// 單例模式，整個應用共用
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = tts_impl.FlutterTtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StartNarrationUseCase Provider
///
/// 提供開始導覽的用例
/// 注入 UsageRepository 以檢查每日額度
final startNarrationUseCaseProvider = Provider<CreateNarrationUseCase>((ref) {
  final narrationService = ref.watch(narrationServiceProvider);
  final usageRepository = ref.watch(usageRepositoryProvider);
  return CreateNarrationUseCase(narrationService, usageRepository);
});

/// NarrationGenerationController Provider
///
/// 管理導覽生成的狀態（在選擇面向頁面使用）
/// 使用 autoDispose 確保離開頁面時自動清理資源
final narrationGenerationControllerProvider =
    StateNotifierProvider.autoDispose<
      NarrationGenerationController,
      NarrationGenerationState
    >((ref) {
      final useCase = ref.watch(startNarrationUseCaseProvider);
      final journeyRepository = ref.watch(journeyRepositoryProvider);
      return NarrationGenerationController(useCase, journeyRepository);
    });

/// PlayerController Provider
///
/// 管理播放器狀態和控制播放行為
/// 使用 autoDispose 確保離開頁面時自動清理資源
/// 僅負責播放，不負責生成導覽內容
final playerControllerProvider =
    StateNotifierProvider.autoDispose<PlayerController, NarrationState>((ref) {
      final ttsService = ref.watch(ttsServiceProvider);
      return PlayerController(ttsService);
    });
