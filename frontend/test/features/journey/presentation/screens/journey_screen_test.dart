import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/presentation/screens/journey_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/presentation/controllers/current_trip_notifier.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

    testWidgets(
      'given mixed entries, when the user switches to the quick-guide filter, '
      'then only quick-guide entries remain',
      (tester) async {
        final narration = buildJourneyEntry(id: 'n1');
        final quick = buildQuickGuideEntry(id: 'q1');

        await _givenJourneyScreen(
          tester,
          seededJourneys: [narration],
          seededQuickGuides: [quick],
        );

        final chipFinder = find.text('journey.filter_quick_guide');
        await tester.ensureVisible(chipFinder);
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();

        expect(find.byType(QuickGuideTimelineEntry), findsOneWidget);
        expect(find.byType(TimelineEntry), findsNothing);
      },
    );

    testWidgets(
      'given a non-matching filter is active, when the list has no results, '
      'then the search-off icon and no-results copy are shown',
      (tester) async {
        final quick = buildQuickGuideEntry(id: 'q1');

        await _givenJourneyScreen(tester, seededQuickGuides: [quick]);
        await _whenUserTapsNarrationFilterChip(tester);

        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(find.text('journey.no_results'), findsOneWidget);
      },
    );

    testWidgets(
      'given the search field is open, when the user types a query, '
      'then a clear-search suffix icon is revealed',
      (tester) async {
        await _givenJourneyScreen(tester);
        await _whenUserTapsSearchToggle(tester);

        await tester.enterText(find.byType(TextField), 'tokyo');
        await tester.pump();

        expect(find.byIcon(Icons.clear), findsOneWidget);
      },
    );

    testWidgets(
      'given a typed search query, when the user taps the clear suffix, '
      'then the search field empties and the suffix disappears',
      (tester) async {
        await _givenJourneyScreen(tester);
        await _whenUserTapsSearchToggle(tester);

        await tester.enterText(find.byType(TextField), 'tokyo');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
        expect(find.byIcon(Icons.clear), findsNothing);
      },
    );

    testWidgets(
      'given search is open with text, when the user taps the close toggle, '
      'then the search bar collapses and the query is cleared',
      (tester) async {
        final e1 = buildJourneyEntry(id: 'e1');

        await _givenJourneyScreen(tester, seededJourneys: [e1]);
        await _whenUserTapsSearchToggle(tester);
        await tester.enterText(find.byType(TextField), 'xyz');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
        // Entry re-appears because query was cleared on toggle-close.
        expect(find.byType(TimelineEntry), findsOneWidget);
      },
    );

    testWidgets(
      'given a currentTripId is set, when the screen renders, '
      'then the current-trip banner shows the trip name',
      (tester) async {
        final trip = buildTrip(id: 't1', name: 'Kyoto Trip');

        await _givenJourneyScreen(
          tester,
          seededTrips: [trip],
          currentTripIdInitial: 't1',
        );

        expect(find.text('trip.current_badge'), findsOneWidget);
        expect(find.text('Kyoto Trip'), findsOneWidget);
        expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'given the current-trip banner is visible, when the user taps End, '
      'then the banner disappears',
      (tester) async {
        final trip = buildTrip(id: 't1', name: 'Kyoto Trip');

        await _givenJourneyScreen(
          tester,
          seededTrips: [trip],
          currentTripIdInitial: 't1',
        );

        await tester.tap(find.text('trip.end_current'));
        await tester.pumpAndSettle();

        expect(find.text('trip.current_badge'), findsNothing);
        expect(find.byIcon(Icons.flag_outlined), findsNothing);
      },
    );

    testWidgets(
      'given SharedPreferences has a saved current trip id, '
      'when the screen loads without an override, '
      'then the current-trip banner is hydrated from storage',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'current_trip_id': 't1',
        });
        final trip = buildTrip(id: 't1', name: 'Kyoto Trip');

        await _givenJourneyScreen(tester, seededTrips: [trip]);
        await tester.pumpAndSettle();

        expect(find.text('trip.current_badge'), findsOneWidget);
        expect(find.text('Kyoto Trip'), findsOneWidget);
      },
    );

    testWidgets(
      'given the by-trip view is active under a router, '
      'when the user taps the add icon, '
      'then the trip-edit route is pushed',
      (tester) async {
        await _givenJourneyScreenWithRouter(tester);

        await tester.tap(find.text('journey.view_by_trip'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('edit-screen')), findsOneWidget);
      },
    );
  });
}

Future<void> _givenJourneyScreen(
  WidgetTester tester, {
  List<JourneyEntry> seededJourneys = const [],
  List<Trip> seededTrips = const [],
  List<QuickGuideEntry> seededQuickGuides = const [],
  String? currentTripIdInitial,
}) async {
  final overrides = await _buildJourneyOverrides(
    seededJourneys: seededJourneys,
    seededTrips: seededTrips,
    seededQuickGuides: seededQuickGuides,
    currentTripIdInitial: currentTripIdInitial,
  );

  await pumpScreen(
    tester,
    child: const JourneyScreen(),
    overrides: overrides,
  );
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _givenJourneyScreenWithRouter(
  WidgetTester tester, {
  List<JourneyEntry> seededJourneys = const [],
  List<Trip> seededTrips = const [],
  List<QuickGuideEntry> seededQuickGuides = const [],
}) async {
  final overrides = await _buildJourneyOverrides(
    seededJourneys: seededJourneys,
    seededTrips: seededTrips,
    seededQuickGuides: seededQuickGuides,
  );

  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const JourneyScreen()),
      GoRoute(
        path: '/trip/edit',
        builder: (_, __) => const Scaffold(
          key: ValueKey('edit-screen'),
          body: Text('edit'),
        ),
      ),
    ],
    overrides: overrides,
  );
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<List<Override>> _buildJourneyOverrides({
  List<JourneyEntry> seededJourneys = const [],
  List<Trip> seededTrips = const [],
  List<QuickGuideEntry> seededQuickGuides = const [],
  String? currentTripIdInitial,
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

  return [
    journeyRepositoryProvider.overrideWithValue(journeyRepo),
    quickGuideRepositoryProvider.overrideWithValue(quickGuideRepo),
    tripRepositoryProvider.overrideWithValue(tripRepo),
    if (currentTripIdInitial != null)
      currentTripIdProvider.overrideWith(
        () => _StaticCurrentTripIdNotifier(currentTripIdInitial),
      ),
  ];
}

class _StaticCurrentTripIdNotifier extends CurrentTripIdNotifier {
  _StaticCurrentTripIdNotifier(this._initial);

  final String? _initial;

  @override
  String? build() => _initial;
}

Future<void> _whenUserTapsSearchToggle(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.search));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserSelectsByTripView(WidgetTester tester) async {
  await tester.tap(find.text('journey.view_by_trip'));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserTapsNarrationFilterChip(WidgetTester tester) async {
  await tester.tap(find.text('journey.filter_narration'));
  await tester.pump(const Duration(milliseconds: 10));
}

void _thenNoEntriesStateIsVisible() {
  expect(find.text('journey.no_entries'), findsOneWidget);
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
