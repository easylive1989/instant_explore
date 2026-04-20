import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/screens/select_narration_aspect_screen.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_narration_service.dart';
import '../../../../fakes/fake_rewarded_ad_service.dart';
import '../../../../fakes/in_memory_journey_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SelectNarrationAspectScreen', () {
    testWidgets(
      'given a place, when the screen loads, '
      'then the place name and address are rendered',
      (tester) async {
        final place = buildPlace(
          name: 'Fushimi Inari',
          formattedAddress: '68 Fukakusa Yabunouchicho',
        );

        await _givenSelectNarrationAspectScreen(tester, place: place);

        _thenPlaceHeaderIsVisible(place.name);
        _thenAddressIsVisible(place.formattedAddress);
      },
    );

    testWidgets(
      'given the screen is open, when the user has not selected any aspect, '
      'then the start button is disabled',
      (tester) async {
        await _givenSelectNarrationAspectScreen(tester, aspects: const {});

        _thenStartButtonIsDisabled(tester);
      },
    );

    testWidgets(
      'given the screen is open, when an aspect is preselected, '
      'then the start button is enabled',
      (tester) async {
        await _givenSelectNarrationAspectScreen(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
        );

        _thenStartButtonIsEnabled(tester);
      },
    );
  });
}

Future<void> _givenSelectNarrationAspectScreen(
  WidgetTester tester, {
  required Place place,
  Set<NarrationAspect>? aspects,
}) async {
  await pumpScreen(
    tester,
    child: SelectNarrationAspectScreen(place: place),
    overrides: [
      narrationServiceProvider.overrideWithValue(FakeNarrationService()),
      journeyRepositoryProvider.overrideWithValue(InMemoryJourneyRepository()),
      usageRepositoryProvider.overrideWithValue(InMemoryUsageRepository()),
      rewardedAdServiceProvider.overrideWithValue(FakeRewardedAdService()),
      if (aspects != null)
        narrationAspectsProvider.overrideWith((ref) => aspects),
    ],
  );
  await tester.pump(const Duration(milliseconds: 20));
}

void _thenPlaceHeaderIsVisible(String name) {
  expect(find.text(name), findsOneWidget);
}

void _thenAddressIsVisible(String address) {
  expect(find.text(address), findsOneWidget);
}

void _thenStartButtonIsDisabled(WidgetTester tester) {
  expect(_findStartButton(tester).onPressed, isNull);
}

void _thenStartButtonIsEnabled(WidgetTester tester) {
  expect(_findStartButton(tester).onPressed, isNotNull);
}

/// Locates the primary start CTA by finding the [AdaptiveButton] that
/// wraps the start-button label.
AdaptiveButton _findStartButton(WidgetTester tester) {
  final buttonFinder = find.ancestor(
    of: find.text('config_screen.start_button'),
    matching: find.byType(AdaptiveButton),
  );
  return tester.widget<AdaptiveButton>(buttonFinder.first);
}
