import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/trip/data/hive_trip_repository.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:context_app/features/trip/presentation/controllers/current_trip_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return HiveTripRepository();
});

/// All trips, newest first. autoDispose so callers don't keep stale lists.
final tripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) {
  return ref.watch(tripRepositoryProvider).getAll();
});

/// Lookup a single trip by id. Returns null if the trip is missing.
final tripByIdProvider = FutureProvider.autoDispose.family<Trip?, String>((
  ref,
  id,
) {
  return ref.watch(tripRepositoryProvider).getById(id);
});

/// 當前「進行中」的旅程 id（持久化到 SharedPreferences）。
///
/// 新建立的 narration / quick guide 條目會自動帶上此 id；若為 `null`
/// 則條目屬於「未分類」。
final currentTripIdProvider = NotifierProvider<CurrentTripIdNotifier, String?>(
  CurrentTripIdNotifier.new,
);

/// 取得某個 trip 的 JourneyItem（narration + quick guide）。
///
/// 傳入 `null` 表示「未分類」群組（tripId 為 null 的條目）。
final journeyItemsForTripProvider = FutureProvider.autoDispose
    .family<List<JourneyItem>, String?>((ref, tripId) async {
      final items = await ref.watch(allJourneyItemsProvider.future);
      return items.where((item) {
        final itemTripId = switch (item) {
          NarrationJourneyItem(:final entry) => entry.tripId,
          QuickGuideJourneyItem(:final entry) => entry.tripId,
        };
        return itemTripId == tripId;
      }).toList();
    });

/// 計算每個 trip 與未分類群組的條目數。
///
/// 回傳 map 的 key：`null` 代表未分類，其他為 trip id。
final tripItemCountsProvider = FutureProvider.autoDispose<Map<String?, int>>((
  ref,
) async {
  final items = await ref.watch(allJourneyItemsProvider.future);
  final counts = <String?, int>{};
  for (final item in items) {
    final tripId = switch (item) {
      NarrationJourneyItem(:final entry) => entry.tripId,
      QuickGuideJourneyItem(:final entry) => entry.tripId,
    };
    counts[tripId] = (counts[tripId] ?? 0) + 1;
  }
  return counts;
});
