import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/core/services/gemini_service.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/application/start_narration_use_case.dart';
import 'package:context_app/features/player/presentation/player_controller.dart';
import 'package:context_app/features/player/presentation/player_state.dart';
import 'package:context_app/features/passport/application/save_narration_to_passport_use_case.dart';

/// 導覽風格選擇 Provider
///
/// 管理用戶選擇的導覽風格
/// 預設為深度版（deepDive）
/// 使用 autoDispose 確保離開頁面時自動重置
final narrationStyleProvider = StateProvider.autoDispose<NarrationStyle>((ref) {
  return NarrationStyle.deepDive;
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
  final geminiService = ref.watch(geminiServiceProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return StartNarrationUseCase(geminiService, ttsService);
});

/// PlayerController Provider
///
/// 管理播放器狀態和控制播放行為
/// 使用 autoDispose 確保離開頁面時自動清理資源
final playerControllerProvider =
    StateNotifierProvider.autoDispose<PlayerController, PlayerState>((ref) {
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
