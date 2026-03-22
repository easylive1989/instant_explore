import 'package:context_app/features/journey/data/caching_journey_repository.dart';
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Data Layer Providers
// ============================================================================

/// Supabase 旅程資料儲存庫 Provider（遠端）
final supabaseJourneyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(Supabase.instance.client);
});

/// Hive 旅程快取服務 Provider
final hiveJourneyCacheServiceProvider = Provider<HiveJourneyCacheService>((
  ref,
) {
  return HiveJourneyCacheService();
});

/// 旅程資料儲存庫 Provider（含快取）
final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return CachingJourneyRepository(
    remote: ref.watch(supabaseJourneyRepositoryProvider),
    cache: ref.watch(hiveJourneyCacheServiceProvider),
  );
});

// ============================================================================
// UI Providers
// ============================================================================

/// 我的旅程 Provider
final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) async {
  final repository = ref.watch(journeyRepositoryProvider);
  return repository.getAll();
});
