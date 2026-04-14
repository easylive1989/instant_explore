import 'dart:typed_data';

import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

JourneyEntry _makeNarration({
  String id = 'n1',
  String placeName = 'Kyoto Temple',
  String placeAddress = 'Kyoto, Japan',
  String narrationText =
      'This ancient temple has a long and rich history.',
  DateTime? createdAt,
}) {
  return JourneyEntry(
    id: id,
    place: SavedPlace(
      id: 'p-$id',
      name: placeName,
      address: placeAddress,
    ),
    narrationContent: NarrationContent.create(
      narrationText,
      language: Language.english,
    ),
    narrationAspects: const {NarrationAspect.historicalBackground},
    createdAt: createdAt ?? DateTime(2026, 4, 1),
    language: Language.english,
  );
}

QuickGuideEntry _makeQuickGuide({
  String id = 'q1',
  String description =
      'A beautiful shrine gate standing near the river.',
  DateTime? createdAt,
}) {
  return QuickGuideEntry(
    id: id,
    imageBytes: Uint8List.fromList([0, 1, 2]),
    aiDescription: description,
    createdAt: createdAt ?? DateTime(2026, 4, 2),
    language: Language.english,
  );
}

/// Creates a [ProviderContainer] with [allJourneyItemsProvider]
/// overridden with the given items, plus the specified search
/// query and filter.
ProviderContainer _createContainer({
  required List<JourneyItem> items,
  String query = '',
  JourneyFilter filter = JourneyFilter.all,
}) {
  final container = ProviderContainer(
    overrides: [
      allJourneyItemsProvider.overrideWith(
        (ref) async => items,
      ),
    ],
  );

  if (query.isNotEmpty) {
    container.read(journeySearchQueryProvider.notifier).state =
        query;
  }
  if (filter != JourneyFilter.all) {
    container.read(journeyFilterProvider.notifier).state = filter;
  }

  return container;
}

void main() {
  final narration1 = NarrationJourneyItem(
    _makeNarration(id: 'n1', placeName: 'Kyoto Temple'),
  );
  final narration2 = NarrationJourneyItem(
    _makeNarration(
      id: 'n2',
      placeName: 'Tokyo Tower',
      placeAddress: 'Tokyo, Japan',
      narrationText:
          'Tokyo Tower is an iconic landmark in the city.',
    ),
  );
  final quickGuide1 = QuickGuideJourneyItem(
    _makeQuickGuide(
      id: 'q1',
      description:
          'A beautiful shrine gate standing near the river.',
    ),
  );

  group('filteredJourneyItemsProvider', () {
    test('returns all items when no filter or search applied',
        () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
      );

      // Wait for async provider to resolve.
      await container.read(allJourneyItemsProvider.future);

      final result =
          container.read(filteredJourneyItemsProvider);
      final items = result.value!;
      expect(items.length, 3);
    });

    test('filters by narration type', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        filter: JourneyFilter.narration,
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 2);
      expect(
        items.every((i) => i is NarrationJourneyItem),
        isTrue,
      );
    });

    test('filters by quick guide type', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        filter: JourneyFilter.quickGuide,
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 1);
      expect(items.first, isA<QuickGuideJourneyItem>());
    });

    test('searches by place name (case-insensitive)', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: 'kyoto',
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 1);
      expect(items.first.id, 'n1');
    });

    test('searches by narration content', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: 'iconic landmark',
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 1);
      expect(items.first.id, 'n2');
    });

    test('searches quick guide by AI description', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: 'shrine gate',
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 1);
      expect(items.first.id, 'q1');
    });

    test('combines filter and search', () async {
      // Search "japan" matches both narrations (address).
      // Filter narration only → should exclude quick guide.
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: 'japan',
        filter: JourneyFilter.narration,
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 2);
      expect(
        items.every((i) => i is NarrationJourneyItem),
        isTrue,
      );
    });

    test('returns empty list when nothing matches', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: 'xyznonexistent',
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items, isEmpty);
    });

    test('trims whitespace in search query', () async {
      final container = _createContainer(
        items: [narration1, narration2, quickGuide1],
        query: '  kyoto  ',
      );

      await container.read(allJourneyItemsProvider.future);

      final items =
          container.read(filteredJourneyItemsProvider).value!;
      expect(items.length, 1);
      expect(items.first.id, 'n1');
    });
  });
}
