import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// 旅程資料儲存庫 Provider
final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(Supabase.instance.client);
});

// ============================================================================
// UI Providers
// ============================================================================

/// 我的旅程 Provider
final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) async {
  final repository = ref.watch(journeyRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return repository.getJourneyEntries(userId);
});
