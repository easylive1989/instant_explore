import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:context_app/features/quick_guide/providers.dart'
    show quickGuideRepositoryProvider, quickGuideEntriesProvider;

/// Filter type for the journey list.
enum JourneyFilter { all, narration, quickGuide }

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final myJourneyProvider =
    FutureProvider.autoDispose<List<JourneyEntry>>((ref) {
  return ref.watch(journeyRepositoryProvider).getAll();
});

/// Combined provider returning all journey items (narration + quick guide)
/// sorted newest first.
final allJourneyItemsProvider =
    FutureProvider.autoDispose<List<JourneyItem>>((ref) async {
  final narrationEntries =
      await ref.watch(journeyRepositoryProvider).getAll();
  final quickGuideEntries =
      await ref.watch(quickGuideRepositoryProvider).getAll();

  final items = <JourneyItem>[
    ...narrationEntries.map(NarrationJourneyItem.new),
    ...quickGuideEntries.map(QuickGuideJourneyItem.new),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return items;
});

/// Current search query entered by the user.
final journeySearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Current type filter selected by the user.
final journeyFilterProvider =
    StateProvider.autoDispose<JourneyFilter>((ref) => JourneyFilter.all);

/// Items after applying search query and type filter.
final filteredJourneyItemsProvider =
    Provider.autoDispose<AsyncValue<List<JourneyItem>>>((ref) {
  final asyncItems = ref.watch(allJourneyItemsProvider);
  final query =
      ref.watch(journeySearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(journeyFilterProvider);

  return asyncItems.whenData((items) {
    var result = items;

    if (filter != JourneyFilter.all) {
      result = result.where((item) {
        return switch (filter) {
          JourneyFilter.narration => item is NarrationJourneyItem,
          JourneyFilter.quickGuide => item is QuickGuideJourneyItem,
          JourneyFilter.all => true,
        };
      }).toList();
    }

    if (query.isNotEmpty) {
      result = result
          .where(
            (item) =>
                item.searchableText.toLowerCase().contains(query),
          )
          .toList();
    }

    return result;
  });
});
