import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/presentation/screens/trip_detail_screen.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/in_memory_journey_repository.dart';
import '../../../../fakes/in_memory_quick_guide_repository.dart';
import '../../../../fakes/in_memory_trip_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('TripDetailScreen', () {
    testWidgets(
      'given a trip with entries, when the detail screen loads, '
      'then the trip name and each timeline entry are rendered',
      (tester) async {
        final trip = buildTrip(id: 'kyoto', name: 'Kyoto Temples');
        final entry = buildJourneyEntry(id: 'e1', tripId: 'kyoto');

        await _givenTripDetailScreen(
          tester,
          tripId: 'kyoto',
          seededTrips: [trip],
          seededJourneys: [entry],
        );

        _thenTripNameIsVisible('Kyoto Temples');
        _thenAtLeastOneTimelineEntryIsShown();
      },
    );

    testWidgets(
      'given a trip with no entries, when the detail screen loads, '
      'then the empty state is rendered',
      (tester) async {
        final trip = buildTrip(id: 'empty', name: 'Empty Trip');

        await _givenTripDetailScreen(
          tester,
          tripId: 'empty',
          seededTrips: [trip],
        );

        _thenEmptyStateIsVisible();
      },
    );

    testWidgets(
      'given the uncategorized bucket, when the screen loads, '
      'then the uncategorized title and checklist action are shown',
      (tester) async {
        final orphan = buildJourneyEntry(id: 'o1');

        await _givenTripDetailScreen(
          tester,
          tripId: null,
          seededJourneys: [orphan],
        );

        _thenUncategorizedTitleIsVisible();
        _thenSelectionModeIsAvailable();
      },
    );

    testWidgets(
      'given uncategorized entries, when the user enters selection mode, '
      'then the selection header replaces the default app bar',
      (tester) async {
        final orphan = buildJourneyEntry(id: 'o1');

        await _givenTripDetailScreen(
          tester,
          tripId: null,
          seededJourneys: [orphan],
        );
        await _whenUserEntersSelectionMode(tester);

        _thenSelectionHeaderIsVisible();
      },
    );
  });
}

Future<void> _givenTripDetailScreen(
  WidgetTester tester, {
  required String? tripId,
  List<Trip> seededTrips = const [],
  List<JourneyEntry> seededJourneys = const [],
}) async {
  final tripRepo = InMemoryTripRepository();
  for (final trip in seededTrips) {
    await tripRepo.save(trip);
  }
  final journeyRepo = InMemoryJourneyRepository();
  for (final entry in seededJourneys) {
    await journeyRepo.save(entry);
  }
  final quickGuideRepo = InMemoryQuickGuideRepository();

  await pumpScreen(
    tester,
    child: TripDetailScreen(tripId: tripId),
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      journeyRepositoryProvider.overrideWithValue(journeyRepo),
      quickGuideRepositoryProvider.overrideWithValue(quickGuideRepo),
    ],
  );
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserEntersSelectionMode(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.checklist));
  await tester.pump(const Duration(milliseconds: 10));
}

void _thenTripNameIsVisible(String name) {
  expect(find.text(name), findsOneWidget);
}

void _thenAtLeastOneTimelineEntryIsShown() {
  expect(find.byType(TimelineEntry), findsAtLeastNWidgets(1));
}

void _thenEmptyStateIsVisible() {
  expect(find.text('trip.no_items'), findsOneWidget);
}

void _thenUncategorizedTitleIsVisible() {
  expect(find.text('trip.uncategorized'), findsOneWidget);
}

void _thenSelectionModeIsAvailable() {
  expect(find.byIcon(Icons.checklist), findsOneWidget);
}

void _thenSelectionHeaderIsVisible() {
  expect(find.text('trip.selected_count'), findsOneWidget);
  expect(find.text('trip.select_all'), findsOneWidget);
}
