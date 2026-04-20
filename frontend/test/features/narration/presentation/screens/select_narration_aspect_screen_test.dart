import 'dart:typed_data';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
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
import 'package:go_router/go_router.dart';

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

    testWidgets(
      'given no preselection, when the user taps an aspect option, '
      'then that aspect becomes selected and the start button enables',
      (tester) async {
        await _givenSelectNarrationAspectScreen(tester, aspects: const {});

        expect(find.byIcon(Icons.check_box), findsNothing);

        await tester.tap(find.byType(AspectOption).first);
        await tester.pump();

        expect(find.byIcon(Icons.check_box), findsOneWidget);
        _thenStartButtonIsEnabled(tester);
      },
    );

    testWidgets(
      'given an aspect is already selected, when the user taps it again, '
      'then it deselects and the start button disables',
      (tester) async {
        await _givenSelectNarrationAspectScreen(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
        );

        await tester.tap(find.byType(AspectOption).first);
        await tester.pump();

        expect(find.byIcon(Icons.check_box), findsNothing);
        _thenStartButtonIsDisabled(tester);
      },
    );

    testWidgets(
      'given quota is exhausted, when the user taps start, '
      'then the watch-ad dialog is shown',
      (tester) async {
        await _givenSelectNarrationAspectScreen(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
          usageRepo: InMemoryUsageRepository(usedToday: 1),
        );

        await tester.tap(find.text('config_screen.start_button'));
        await tester.pumpAndSettle();

        expect(find.text('ads.quota_exceeded_title'), findsOneWidget);
        expect(find.text('ads.watch_video'), findsOneWidget);
        expect(find.text('subscription.upgrade_cta'), findsOneWidget);
      },
    );

    testWidgets(
      'given the watch-ad dialog is open, when the user cancels, '
      'then no narration generation is triggered',
      (tester) async {
        final service = FakeNarrationService();

        await _givenSelectNarrationAspectScreen(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
          usageRepo: InMemoryUsageRepository(usedToday: 1),
          service: service,
        );

        await tester.tap(find.text('config_screen.start_button'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('settings.cancel'));
        await tester.pumpAndSettle();

        expect(find.text('ads.quota_exceeded_title'), findsNothing);
        expect(service.lastPlace, isNull);
      },
    );

    testWidgets(
      'given capturedImageBytes are provided, when the screen renders, '
      'then the background uses an Image.memory with those bytes',
      (tester) async {
        await _givenSelectNarrationAspectScreen(
          tester,
          capturedImageBytes: _transparentPngBytes(),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w is Image && w.image is MemoryImage,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given a narration service that throws, when the user taps start, '
      'then the generation-error dialog appears',
      (tester) async {
        final service = FakeNarrationService(
          error: const AppError(type: NarrationError.networkError),
        );

        await _givenSelectNarrationAspectScreen(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
          service: service,
        );

        await tester.tap(find.text('config_screen.start_button'));
        await tester.pumpAndSettle();

        expect(find.text('config_screen.generation_error_title'), findsOneWidget);
        expect(find.text('config_screen.generation_error_ok'), findsOneWidget);
      },
    );

    testWidgets(
      'given a router, when generation succeeds, '
      'then the player route is pushed with place and narration content',
      (tester) async {
        final extras = <Object?>[];

        await _givenSelectNarrationAspectScreenWithRouter(
          tester,
          aspects: const {NarrationAspect.historicalBackground},
          onPlayerPush: extras.add,
        );

        await tester.tap(find.text('config_screen.start_button'));
        await tester.pumpAndSettle();

        expect(extras, hasLength(1));
        final extra = extras.single as Map<String, dynamic>;
        expect(extra['place'], isNotNull);
        expect(extra['narrationContent'], isNotNull);
        expect(extra['autoPlay'], isTrue);
      },
    );
  });
}

Future<void> _givenSelectNarrationAspectScreen(
  WidgetTester tester, {
  Place? place,
  Set<NarrationAspect>? aspects,
  FakeNarrationService? service,
  InMemoryUsageRepository? usageRepo,
  Uint8List? capturedImageBytes,
}) async {
  await pumpScreen(
    tester,
    child: SelectNarrationAspectScreen(
      place: place ?? buildPlace(),
      capturedImageBytes: capturedImageBytes,
    ),
    overrides: _buildOverrides(
      aspects: aspects,
      service: service,
      usageRepo: usageRepo,
    ),
  );
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _givenSelectNarrationAspectScreenWithRouter(
  WidgetTester tester, {
  Place? place,
  Set<NarrationAspect>? aspects,
  FakeNarrationService? service,
  InMemoryUsageRepository? usageRepo,
  required void Function(Object? extra) onPlayerPush,
}) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => SelectNarrationAspectScreen(
          place: place ?? buildPlace(),
        ),
      ),
      GoRoute(
        name: 'player',
        path: '/player',
        builder: (_, state) {
          onPlayerPush(state.extra);
          return const Scaffold(
            key: Key('player-screen'),
            body: SizedBox.shrink(),
          );
        },
      ),
    ],
    overrides: _buildOverrides(
      aspects: aspects,
      service: service,
      usageRepo: usageRepo,
    ),
  );
  await tester.pump(const Duration(milliseconds: 20));
}

List<Override> _buildOverrides({
  Set<NarrationAspect>? aspects,
  FakeNarrationService? service,
  InMemoryUsageRepository? usageRepo,
}) {
  return [
    narrationServiceProvider.overrideWithValue(
      service ?? FakeNarrationService(),
    ),
    journeyRepositoryProvider.overrideWithValue(InMemoryJourneyRepository()),
    usageRepositoryProvider.overrideWithValue(
      usageRepo ?? InMemoryUsageRepository(),
    ),
    rewardedAdServiceProvider.overrideWithValue(FakeRewardedAdService()),
    if (aspects != null)
      narrationAspectsProvider.overrideWith((ref) => aspects),
  ];
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

/// 1x1 transparent PNG — minimal valid bytes to feed Image.memory.
Uint8List _transparentPngBytes() {
  return Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
}
