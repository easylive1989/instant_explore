import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
          buildPlace(id: 'p1', name: 'Senso-ji', userRatingCount: 200),
          buildPlace(id: 'p2', name: 'Meiji Shrine', userRatingCount: 150),
        ];

        await _givenExploreScreen(tester, places: places);

        _thenPlaceNamesAreVisible(['Senso-ji', 'Meiji Shrine']);
      },
    );

    testWidgets(
      'given a review-count filter of 500, when the list is filtered, '
      'then only places with enough ratings are shown',
      (tester) async {
        final places = [
          buildPlace(id: 'p1', name: 'Popular', userRatingCount: 800),
          buildPlace(id: 'p2', name: 'Obscure', userRatingCount: 20),
        ];

        await _givenExploreScreen(
          tester,
          places: places,
          minReviewCount: 500,
        );

        _thenPlaceNamesAreVisible(['Popular']);
        _thenPlaceNamesAreHidden(['Obscure']);
      },
    );
  });
}

Future<void> _givenExploreScreen(
  WidgetTester tester, {
  List<Place> places = const [],
  int minReviewCount = 0,
}) async {
  await pumpScreen(
    tester,
    child: const ExploreScreen(),
    overrides: [
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      placesRepositoryProvider.overrideWithValue(
        FakePlacesRepository(nearbyPlaces: places),
      ),
      savedLocationsRepositoryProvider.overrideWithValue(
        InMemorySavedLocationsRepository(),
      ),
      minReviewCountProvider.overrideWith((ref) => minReviewCount),
    ],
  );
  // Let async searchNearby + filtered places provider resolve.
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
