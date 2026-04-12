import 'package:context_app/features/quick_guide/data/gemini_quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/data/hive_quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/data/quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/presentation/controllers/quick_guide_controller.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickGuideAiServiceProvider = Provider<QuickGuideAiService>((ref) {
  return GeminiQuickGuideAiService();
});

final quickGuideRepositoryProvider = Provider<QuickGuideRepository>((ref) {
  return HiveQuickGuideRepository();
});

final quickGuideControllerProvider =
    StateNotifierProvider<QuickGuideController, QuickGuideState>((ref) {
      return QuickGuideController(
        ref.watch(quickGuideAiServiceProvider),
        ref.watch(quickGuideRepositoryProvider),
        ref.watch(usageRepositoryProvider),
      );
    });

final quickGuideEntriesProvider =
    FutureProvider.autoDispose<List<QuickGuideEntry>>((ref) {
      return ref.watch(quickGuideRepositoryProvider).getAll();
    });
