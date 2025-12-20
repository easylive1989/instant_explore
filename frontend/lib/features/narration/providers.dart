import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/narration/data/gemini_service.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/use_cases/start_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/player_controller.dart';
import 'package:context_app/features/narration/presentation/narration_state.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';

/// 導覽介紹面向選擇 Provider
///
/// 管理用戶選擇的導覽介紹面向
/// 預設為歷史背景（historicalBackground）
/// 使用 autoDispose 確保離開頁面時自動重置
final narrationAspectProvider = StateProvider.autoDispose<NarrationAspect>((
  ref,
) {
  return NarrationAspect.historicalBackground;
});

/// TtsService Provider
///
/// 提供 TTS 語音合成服務
/// 單例模式，整個應用共用
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StartNarrationUseCase Provider
///
/// 提供開始導覽的用例
final startNarrationUseCaseProvider = Provider<StartNarrationUseCase>((ref) {
  final narrationService = ref.watch(narrationServiceProvider);
  return StartNarrationUseCase(narrationService);
});

/// PlayerController Provider
///
/// 管理播放器狀態和控制播放行為
/// 使用 autoDispose 確保離開頁面時自動清理資源
final playerControllerProvider =
    StateNotifierProvider.autoDispose<PlayerController, NarrationState>((ref) {
      final startNarrationUseCase = ref.watch(startNarrationUseCaseProvider);
      final saveNarrationToPassportUseCase = ref.watch(
        saveNarrationToPassportUseCaseProvider,
      );
      final ttsService = ref.watch(ttsServiceProvider);
      return PlayerController(
        startNarrationUseCase,
        saveNarrationToPassportUseCase,
        ttsService,
      );
    });
