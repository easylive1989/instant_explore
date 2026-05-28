import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/sync/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter type for the journey list.
enum JourneyFilter { all, narration }

/// Journey 頁的檢視模式：完整時間軸 或 依旅程分群。
enum JourneyViewMode { timeline, byTrip }

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return ref.watch(syncingJourneyRepositoryProvider);
});

final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((ref) {
  return ref.watch(journeyRepositoryProvider).getAll();
});

/// Combined provider returning all journey items sorted newest first.
final allJourneyItemsProvider = FutureProvider.autoDispose<List<JourneyItem>>((
  ref,
) async {
  final narrationEntries = await ref.watch(journeyRepositoryProvider).getAll();

  final items = <JourneyItem>[...narrationEntries.map(NarrationJourneyItem.new)]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return items;
});

/// Current search query entered by the user.
final journeySearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Current type filter selected by the user.
final journeyFilterProvider = StateProvider.autoDispose<JourneyFilter>(
  (ref) => JourneyFilter.all,
);

/// Journey 頁當前的檢視模式。
final journeyViewModeProvider = StateProvider.autoDispose<JourneyViewMode>(
  (ref) => JourneyViewMode.timeline,
);

/// Items after applying search query and type filter.
final filteredJourneyItemsProvider =
    Provider.autoDispose<AsyncValue<List<JourneyItem>>>((ref) {
      final asyncItems = ref.watch(allJourneyItemsProvider);
      final query = ref.watch(journeySearchQueryProvider).trim().toLowerCase();
      final filter = ref.watch(journeyFilterProvider);

      return asyncItems.whenData((items) {
        var result = items;

        if (filter != JourneyFilter.all) {
          result = result.where((item) {
            return switch (filter) {
              JourneyFilter.narration => item is NarrationJourneyItem,
              JourneyFilter.all => true,
            };
          }).toList();
        }

        if (query.isNotEmpty) {
          result = result
              .where(
                (item) => item.searchableText.toLowerCase().contains(query),
              )
              .toList();
        }

        return result;
      });
    });
