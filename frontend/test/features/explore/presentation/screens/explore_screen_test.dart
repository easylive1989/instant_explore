import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_location_service.dart';
import '../../../../fakes/fake_places_repository.dart';
import '../../../../fakes/in_memory_saved_locations_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ExploreScreen', () {
    testWidgets(
      'given no nearby places, when the screen loads, '
      'then the empty-state copy is shown',
      (tester) async {
        await _givenExploreScreen(tester);

        _thenEmptyStateIsVisible();
      },
    );

    testWidgets(
      'given nearby places are returned, when the screen loads, '
      'then a place card is rendered for each place',
      (tester) async {
        final places = [
          buildPlace(id: 'p1', name: 'Senso-ji'),
          buildPlace(id: 'p2', name: 'Meiji Shrine'),
        ];

        await _givenExploreScreen(tester, places: places);

        _thenPlaceNamesAreVisible(['Senso-ji', 'Meiji Shrine']);
      },
    );

    testWidgets(
      'given a distance filter of 500 m, when the list is filtered, '
      'then only places within range are shown',
      (tester) async {
        // Place near origin (lat 0, lon 0), one within 500 m, one outside.
        final places = [
          buildPlace(
            id: 'p1',
            name: 'Near',
            latitude: 0.001, // ~111 m
            longitude: 0.0,
          ),
          buildPlace(
            id: 'p2',
            name: 'Far',
            latitude: 0.01, // ~1111 m
            longitude: 0.0,
          ),
        ];

        await _givenExploreScreen(
          tester,
          places: places,
          maxDistance: 500.0,
          userLocation: const PlaceLocation(latitude: 0.0, longitude: 0.0),
        );

        _thenPlaceNamesAreVisible(['Near']);
        _thenPlaceNamesAreHidden(['Far']);
      },
    );

    testWidgets(
      'given the user types in the search box and submits, '
      'when the repository returns search results, '
      'then the result list replaces the nearby places',
      (tester) async {
        final repo = FakePlacesRepository(
          nearbyPlaces: [buildPlace(id: 'p1', name: 'Nearby Place')],
          searchResults: [buildPlace(id: 's1', name: 'Searched Place')],
        );

        await _givenExploreScreen(tester, repo: repo);

        await tester.enterText(find.byType(TextField), 'searched');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));

        expect(find.text('Searched Place'), findsOneWidget);
        expect(find.text('Nearby Place'), findsNothing);
      },
    );

    testWidgets(
      'given a submitted search term, when the user taps the clear icon, '
      'then the controller is cleared and nearby places are restored',
      (tester) async {
        final repo = FakePlacesRepository(
          nearbyPlaces: [buildPlace(id: 'p1', name: 'Nearby Place')],
          searchResults: [buildPlace(id: 's1', name: 'Searched Place')],
        );

        await _givenExploreScreen(tester, repo: repo);

        // The clear icon only appears after the search field is actually
        // used — submit once so the suffix rebuilds into a clear button.
        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
        expect(find.text('Nearby Place'), findsOneWidget);
      },
    );

    testWidgets(
      'given places are on screen, when the user taps refresh, '
      'then the nearby-places use case is invoked again',
      (tester) async {
        final repo = FakePlacesRepository(
          nearbyPlaces: [buildPlace(id: 'p1', name: 'Nearby')],
        );

        await _givenExploreScreen(tester, repo: repo);
        final before = repo.nearbyCallCount;

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));

        expect(repo.nearbyCallCount, greaterThan(before));
      },
    );

    testWidgets(
      'given the filter is at its default value (5000 m), when the screen '
      'renders, then no active dot is shown',
      (tester) async {
        await _givenExploreScreen(tester, maxDistance: 5000.0);

        // The active dot is an 8x8 BoxDecoration in the filter-button stack.
        // When inactive (maxDistance == 5000), it is not present.
        expect(_activeDotFinder(), findsNothing);
      },
    );

    testWidgets(
      'given a non-default maxDistance, when the screen renders, '
      'then the active dot is shown',
      (tester) async {
        await _givenExploreScreen(tester, maxDistance: 500.0);

        expect(_activeDotFinder(), findsOneWidget);
      },
    );

    testWidgets(
      'given the filter button is present, when the user taps it, '
      'then the filter panel bottom sheet is shown',
      (tester) async {
        await _givenExploreScreen(tester);

        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        expect(find.text('explore.filter.title'), findsOneWidget);
        expect(find.text('explore.filter.max_distance'), findsOneWidget);
        expect(find.text('explore.filter.reset'), findsOneWidget);
      },
    );

    testWidgets(
      'given an unsaved place card, when the user taps the bookmark icon, '
      'then the card shows the filled bookmark and the repo records the save',
      (tester) async {
        final savedRepo = InMemorySavedLocationsRepository();

        await _givenExploreScreen(
          tester,
          places: [buildPlace(id: 'p1', name: 'Senso-ji')],
          savedRepo: savedRepo,
        );

        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

        await tester.tap(find.byIcon(Icons.bookmark_border));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark), findsAtLeastNWidgets(1));
        expect(await savedRepo.isSaved('p1'), isTrue);
      },
    );

    testWidgets(
      'given a place card under a router, when the card is tapped, '
      'then the config route is pushed with the place as extra',
      (tester) async {
        final extras = <Object?>[];

        await _givenExploreScreenWithRouter(
          tester,
          places: [buildPlace(id: 'p1', name: 'Senso-ji')],
          onConfigPush: extras.add,
        );

        await tester.tap(find.text('Senso-ji'));
        await tester.pumpAndSettle();

        expect(extras.single, isA<Place>());
        expect((extras.single as Place).id, equals('p1'));
      },
    );
  });
}

Future<void> _givenExploreScreen(
  WidgetTester tester, {
  List<Place> places = const [],
  FakePlacesRepository? repo,
  InMemorySavedLocationsRepository? savedRepo,
  double maxDistance = 5000.0,
  PlaceLocation? userLocation,
}) async {
  final fakeLocation = FakeLocationService(
    location: userLocation ?? const PlaceLocation(latitude: 25.0, longitude: 121.0),
  );
  await pumpScreen(
    tester,
    child: const ExploreScreen(),
    overrides: [
      locationServiceProvider.overrideWithValue(fakeLocation),
      placesRepositoryProvider.overrideWithValue(
        repo ?? FakePlacesRepository(nearbyPlaces: places),
      ),
      savedLocationsRepositoryProvider.overrideWithValue(
        savedRepo ?? InMemorySavedLocationsRepository(),
      ),
      maxDistanceProvider.overrideWith((ref) => maxDistance),
    ],
  );
  // Let async searchNearby + filtered places provider resolve.
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _givenExploreScreenWithRouter(
  WidgetTester tester, {
  List<Place> places = const [],
  required void Function(Object? extra) onConfigPush,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const ExploreScreen()),
      GoRoute(
        name: 'config',
        path: '/config',
        builder: (_, state) {
          onConfigPush(state.extra);
          return const Scaffold(
            key: Key('config-screen'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: [
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      placesRepositoryProvider.overrideWithValue(
        FakePlacesRepository(nearbyPlaces: places),
      ),
      savedLocationsRepositoryProvider.overrideWithValue(
        InMemorySavedLocationsRepository(),
      ),
    ],
  );
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

void _thenEmptyStateIsVisible() {
  expect(find.text('No places found'), findsOneWidget);
}

void _thenPlaceNamesAreVisible(List<String> names) {
  for (final name in names) {
    expect(find.text(name), findsOneWidget);
  }
}

void _thenPlaceNamesAreHidden(List<String> names) {
  for (final name in names) {
    expect(find.text(name), findsNothing);
  }
}

Finder _activeDotFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
        (widget.decoration! as BoxDecoration).color != null,
    description: 'filter active dot',
  );
}
