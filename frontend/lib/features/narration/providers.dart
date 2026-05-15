import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/narration/data/gemini_service.dart';
import 'package:context_app/features/narration/data/gemini_story_hook_service.dart';
import 'package:context_app/features/narration/data/tts_service.dart' as tts_impl;
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/services/story_hook_service.dart';
import 'package:context_app/features/narration/domain/services/tts_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/story_hook_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final narrationServiceProvider = Provider<NarrationService>((ref) {
  return GeminiService();
});

/// 產生故事鉤子用的 service；不計入 narration 每日額度。
final storyHookServiceProvider = Provider<StoryHookService>((ref) {
  return GeminiStoryHookService();
});

/// TtsService Provider — 提供 TTS 語音合成服務。
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = tts_impl.FlutterTtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StartNarrationUseCase Provider
final startNarrationUseCaseProvider = Provider<CreateNarrationUseCase>((ref) {
  final narrationService = ref.watch(narrationServiceProvider);
  final usageRepository = ref.watch(usageRepositoryProvider);
  return CreateNarrationUseCase(narrationService, usageRepository);
});

/// NarrationGenerationController Provider — 管理導覽生成的狀態。
final narrationGenerationControllerProvider =
    StateNotifierProvider.autoDispose<
      NarrationGenerationController,
      NarrationGenerationState
    >((ref) {
      final useCase = ref.watch(startNarrationUseCaseProvider);
      final journeyRepository = ref.watch(journeyRepositoryProvider);
      return NarrationGenerationController(
        useCase,
        journeyRepository,
        () => ref.read(currentTripIdProvider),
        () => ref.invalidate(usageStatusProvider),
      );
    });

/// PlayerController Provider — 管理播放器狀態。
final playerControllerProvider =
    StateNotifierProvider.autoDispose<PlayerController, NarrationState>((ref) {
      final ttsService = ref.watch(ttsServiceProvider);
      return PlayerController(ttsService);
    });

/// 故事鉤子 controller 的引數包裝。
///
/// `Place` 沒有實作值相等，因此這裡只比較 `placeId + languageCode`，
/// 讓同一景點 + 同一語言共用一個 controller 實例。
class StoryHookArgs {
  final Place place;
  final Language language;
  const StoryHookArgs({required this.place, required this.language});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryHookArgs &&
          other.place.id == place.id &&
          other.language.code == language.code;

  @override
  int get hashCode => Object.hash(place.id, language.code);
}

/// 故事鉤子 controller — 依景點與語言載入 2-3 個歷史故事鉤子。
///
/// 使用 family 讓不同景點互不影響；autoDispose 確保離開頁面釋放資源。
final storyHookControllerProvider = StateNotifierProvider.autoDispose
    .family<StoryHookController, StoryHookState, StoryHookArgs>((ref, args) {
      final service = ref.watch(storyHookServiceProvider);
      return StoryHookController(service, args.place, args.language);
    });
