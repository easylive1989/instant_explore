import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_dialog.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/in_memory_saved_locations_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SavedLocationsDialog', () {
    testWidgets(
      'given no saved locations, when the dialog is opened, '
      'then the empty state icon and helper text are shown',
      (tester) async {
        await _openDialog(tester, repo: InMemorySavedLocationsRepository());

        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.text('saved_locations.empty'), findsOneWidget);
        expect(find.text('saved_locations.empty_hint'), findsOneWidget);
      },
    );

    testWidgets(
      'given two saved locations, when the dialog is opened, '
      'then each tile shows name, address and a chevron',
      (tester) async {
        final repo = InMemorySavedLocationsRepository();
        await repo.save(_entry(id: 'p1', name: 'Senso-ji', address: 'Asakusa'));
        await repo.save(_entry(id: 'p2', name: 'Meiji', address: 'Shibuya'));

        await _openDialog(tester, repo: repo);

        expect(find.text('Senso-ji'), findsOneWidget);
        expect(find.text('Asakusa'), findsOneWidget);
        expect(find.text('Meiji'), findsOneWidget);
        expect(find.text('Shibuya'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      },
    );

    testWidgets(
      'given the dialog is open, when the user taps the close icon, '
      'then the dialog is dismissed',
      (tester) async {
        await _openDialog(tester, repo: InMemorySavedLocationsRepository());

        expect(find.byType(SavedLocationsDialog), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(SavedLocationsDialog), findsNothing);
      },
    );

    testWidgets(
      'given a saved tile, when the user swipes it away, '
      'then a delete-confirmation dialog is shown',
      (tester) async {
        final repo = InMemorySavedLocationsRepository();
        await repo.save(_entry(id: 'p1', name: 'Senso-ji', address: 'Asakusa'));

        await _openDialog(tester, repo: repo);

        await tester.drag(find.text('Senso-ji'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('saved_locations.delete_title'), findsOneWidget);
        expect(find.text('saved_locations.delete_confirm'), findsOneWidget);
      },
    );

    testWidgets(
      'given the dialog header, when the dialog is rendered, '
      'then the title and bookmark icon are visible',
      (tester) async {
        await _openDialog(tester, repo: InMemorySavedLocationsRepository());

        expect(find.text('saved_locations.title'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      },
    );
  });
}

SavedLocationEntry _entry({
  required String id,
  required String name,
  required String address,
  PlaceCategory category = PlaceCategory.modernUrban,
  DateTime? savedAt,
}) {
  return SavedLocationEntry(
    placeId: id,
    name: name,
    formattedAddress: address,
    latitude: 25.0,
    longitude: 121.0,
    types: const [],
    photosJson: const [],
    categoryKey: category.name,
    savedAt: savedAt ?? DateTime(2024, 1, 1),
  );
}

Future<void> _openDialog(
  WidgetTester tester, {
  required SavedLocationsRepository repo,
}) async {
  await pumpScreen(
    tester,
    overrides: [savedLocationsRepositoryProvider.overrideWithValue(repo)],
    child: _HostPage(),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _HostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: SavedLocationsDialog(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}
