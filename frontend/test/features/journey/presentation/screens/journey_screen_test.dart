import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/presentation/screens/journey_screen.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
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

  group('JourneyScreen', () {
    testWidgets(
      'given no entries, when the timeline view is active, '
      'then the empty state message is rendered',
      (tester) async {
        await _givenJourneyScreen(tester);

        _thenNoEntriesStateIsVisible();
      },
    );

    testWidgets(
      'given the user has journey entries, when the timeline view loads, '
      'then each entry is displayed as a timeline card',
      (tester) async {
        final entries = [
          buildJourneyEntry(id: 'e1'),
          buildJourneyEntry(id: 'e2'),
        ];

        await _givenJourneyScreen(tester, seededJourneys: entries);

        _thenTimelineShowsEntries(count: 2);
      },
    );

    testWidgets(
      'given the timeline view is active, when the user opens search, '
      'then a search input is revealed',
      (tester) async {
        await _givenJourneyScreen(tester);

        await _whenUserTapsSearchToggle(tester);

        _thenSearchFieldIsVisible();
      },
    );

    testWidgets(
      'given the timeline view is active, when the user selects by-trip, '
      'then the trip grid replaces the timeline list',
      (tester) async {
        final trip = buildTrip(id: 't1', name: 'Kyoto Trip');

        await _givenJourneyScreen(tester, seededTrips: [trip]);
        await _whenUserSelectsByTripView(tester);

        _thenTripCardIsVisible('Kyoto Trip');
      },
    );

    testWidgets(
      'given narration and quick-guide entries exist, when the user filters '
      'to narration only, then only narration entries remain',
      (tester) async {
        final narration = buildJourneyEntry(id: 'n1');
        final quick = buildQuickGuideEntry(id: 'q1');

        await _givenJourneyScreen(
          tester,
          seededJourneys: [narration],
          seededQuickGuides: [quick],
        );
        await _whenUserTapsNarrationFilterChip(tester);

        _thenOnlyNarrationEntriesRemain();
      },
    );
  });
}

Future<void> _givenJourneyScreen(
  WidgetTester tester, {
  List<JourneyEntry> seededJourneys = const [],
  List<Trip> seededTrips = const [],
  List<QuickGuideEntry> seededQuickGuides = const [],
}) async {
  final journeyRepo = InMemoryJourneyRepository();
  for (final entry in seededJourneys) {
    await journeyRepo.save(entry);
  }
  final quickGuideRepo = InMemoryQuickGuideRepository();
  for (final entry in seededQuickGuides) {
    await quickGuideRepo.save(entry);
  }
  final tripRepo = InMemoryTripRepository();
  for (final trip in seededTrips) {
    await tripRepo.save(trip);
  }

  await pumpScreen(
    tester,
    child: const JourneyScreen(),
    overrides: [
      journeyRepositoryProvider.overrideWithValue(journeyRepo),
      quickGuideRepositoryProvider.overrideWithValue(quickGuideRepo),
      tripRepositoryProvider.overrideWithValue(tripRepo),
    ],
  );
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserTapsSearchToggle(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.search));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserSelectsByTripView(WidgetTester tester) async {
  await tester.tap(find.text('passport.view_by_trip'));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserTapsNarrationFilterChip(WidgetTester tester) async {
  await tester.tap(find.text('passport.filter_narration'));
  await tester.pump(const Duration(milliseconds: 10));
}

void _thenNoEntriesStateIsVisible() {
  expect(find.text('passport.no_entries'), findsOneWidget);
}

void _thenTimelineShowsEntries({required int count}) {
  expect(find.byType(TimelineEntry), findsNWidgets(count));
}

void _thenSearchFieldIsVisible() {
  expect(find.byType(TextField), findsOneWidget);
}

void _thenTripCardIsVisible(String name) {
  expect(find.text(name), findsOneWidget);
}

void _thenOnlyNarrationEntriesRemain() {
  expect(find.byType(TimelineEntry), findsOneWidget);
  expect(find.byType(QuickGuideTimelineEntry), findsNothing);
}
