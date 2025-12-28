import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:context_app/features/journey/domain/use_cases/get_my_journey_use_case.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';
import 'package:context_app/features/journey/domain/use_cases/delete_journey_entry_use_case.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// 旅程資料儲存庫 Provider
final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(Supabase.instance.client);
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// 取得我的旅程用例 Provider
final getMyJourneyUseCaseProvider = Provider<GetMyJourneyUseCase>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  return GetMyJourneyUseCase(repository);
});

/// 儲存導覽到旅程用例 Provider
final saveNarrationToJourneyUseCaseProvider =
    Provider<SaveNarrationToJourneyUseCase>((ref) {
      final repository = ref.watch(journeyRepositoryProvider);
      return SaveNarrationToJourneyUseCase(repository);
    });

/// 刪除旅程項目用例 Provider
final deleteJourneyEntryUseCaseProvider = Provider<DeleteJourneyEntryUseCase>((
  ref,
) {
  final repository = ref.watch(journeyRepositoryProvider);
  return DeleteJourneyEntryUseCase(repository);
});

// ============================================================================
// UI Providers
// ============================================================================

/// 我的旅程 Provider
final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) async {
  final useCase = ref.watch(getMyJourneyUseCaseProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return useCase.execute(userId);
});
