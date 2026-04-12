import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:context_app/features/quick_guide/providers.dart'
    show quickGuideRepositoryProvider, quickGuideEntriesProvider;

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((ref) {
  return ref.watch(journeyRepositoryProvider).getAll();
});

/// Combined provider returning all journey items (narration + quick guide)
/// sorted newest first.
final allJourneyItemsProvider = FutureProvider.autoDispose<List<JourneyItem>>((
  ref,
) async {
  final narrationEntries = await ref.watch(journeyRepositoryProvider).getAll();
  final quickGuideEntries = await ref
      .watch(quickGuideRepositoryProvider)
      .getAll();

  final items = <JourneyItem>[
    ...narrationEntries.map(NarrationJourneyItem.new),
    ...quickGuideEntries.map(QuickGuideJourneyItem.new),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return items;
});
