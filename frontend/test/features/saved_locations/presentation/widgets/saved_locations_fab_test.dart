import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_sheet.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/in_memory_saved_locations_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SavedLocationsFab', () {
    testWidgets(
      'given no saved locations, when the FAB is rendered, '
      'then the bookmark icon is shown without a visible count badge',
      (tester) async {
        await _pumpFab(tester, repo: InMemorySavedLocationsRepository());

        expect(find.byIcon(Icons.bookmark), findsOneWidget);
        final badge = tester.widget<Badge>(find.byType(Badge));
        expect(badge.isLabelVisible, isFalse);
      },
    );

    testWidgets(
      'given two saved locations, when the FAB is rendered, '
      'then the badge label reflects the count',
      (tester) async {
        final repo = InMemorySavedLocationsRepository();
        await repo.save(_entry(id: 'p1'));
        await repo.save(_entry(id: 'p2'));

        await _pumpFab(tester, repo: repo);

        final badge = tester.widget<Badge>(find.byType(Badge));
        expect(badge.isLabelVisible, isTrue);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'given the FAB is on screen, when the user taps it, '
      'then the saved locations bottom sheet is shown',
      (tester) async {
        await _pumpFab(tester, repo: InMemorySavedLocationsRepository());

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(SavedLocationsSheet), findsOneWidget);
      },
    );

    testWidgets(
      'given the sheet is open, when the user taps the close icon, '
      'then the sheet is dismissed and the FAB stays on screen',
      (tester) async {
        await _pumpFab(tester, repo: InMemorySavedLocationsRepository());

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Close via the sheet's close icon.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(SavedLocationsSheet), findsNothing);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );
  });
}

SavedLocationEntry _entry({
  required String id,
  PlaceCategory category = PlaceCategory.modernUrban,
}) {
  return SavedLocationEntry(
    placeId: id,
    name: 'Name $id',
    address: 'Addr $id',
    latitude: 25.0,
    longitude: 121.0,
    tags: const [],
    photosJson: const [],
    categoryKey: category.name,
    savedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Future<void> _pumpFab(
  WidgetTester tester, {
  required SavedLocationsRepository repo,
}) async {
  await pumpScreen(
    tester,
    overrides: [savedLocationsRepositoryProvider.overrideWithValue(repo)],
    child: const Scaffold(
      floatingActionButton: SavedLocationsFab(),
      body: SizedBox.expand(),
    ),
  );
  // Wait for the async saved-locations load to settle.
  await tester.pumpAndSettle();
}
