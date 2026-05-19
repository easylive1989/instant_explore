import 'package:context_app/features/auth/providers.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/presentation/screens/journey_screen.dart';
import 'package:context_app/app/main_screen.dart';
import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/features/quick_guide/presentation/screens/quick_guide_screen.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/trip/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_image_analysis_service.dart';
import '../fakes/fake_location_service.dart';
import '../fakes/fake_places_repository.dart';
import '../fakes/fake_quick_guide_ai_service.dart';
import '../fakes/fake_subscription_service.dart';
import '../fakes/in_memory_daily_story_repository.dart';
import '../fakes/in_memory_journey_repository.dart';
import '../fakes/in_memory_onboarding_repository.dart';
import '../fakes/in_memory_quick_guide_repository.dart';
import '../fakes/in_memory_saved_locations_repository.dart';
import '../fakes/in_memory_trip_repository.dart';
import '../fakes/in_memory_usage_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('MainScreen', () {
    testWidgets(
      'given an empty explore tab by default, when the screen is shown, '
      'then the explore tab content is rendered',
      (tester) async {
        await _givenMainScreen(tester);

        _thenExploreTabIsActive();
      },
    );

    testWidgets(
      'given initial tab is the journey, when the screen is shown, '
      'then the journey tab content is rendered',
      (tester) async {
        await _givenMainScreen(tester, initialIndex: 2);

        _thenJourneyTabIsActive();
      },
    );

    testWidgets(
      'given the explore tab is active, when the user selects quick guide, '
      'then the quick guide tab content is rendered',
      (tester) async {
        await _givenMainScreen(tester);

        await _whenUserSelectsBottomNavItem(tester, 'bottom_nav.quick_guide');

        _thenQuickGuideTabIsActive();
      },
    );

    testWidgets(
      'given the explore tab is active, when the user selects settings, '
      'then the settings tab content is rendered',
      (tester) async {
        await _givenMainScreen(tester);

        await _whenUserSelectsBottomNavItem(tester, 'bottom_nav.settings');

        _thenSettingsTabIsActive();
      },
    );
  });
}

Future<void> _givenMainScreen(
  WidgetTester tester, {
  int initialIndex = 0,
}) async {
  await pumpScreen(
    tester,
    child: MainScreen(initialIndex: initialIndex),
    overrides: _mainScreenOverrides(),
  );
}

List<Override> _mainScreenOverrides() {
  return [
    authServiceProvider.overrideWithValue(FakeAuthService()),
    placesRepositoryProvider.overrideWithValue(FakePlacesRepository()),
    locationServiceProvider.overrideWithValue(FakeLocationService()),
    journeyRepositoryProvider.overrideWithValue(InMemoryJourneyRepository()),
    quickGuideRepositoryProvider.overrideWithValue(
      InMemoryQuickGuideRepository(),
    ),
    tripRepositoryProvider.overrideWithValue(InMemoryTripRepository()),
    savedLocationsRepositoryProvider.overrideWithValue(
      InMemorySavedLocationsRepository(),
    ),
    usageRepositoryProvider.overrideWithValue(InMemoryUsageRepository()),
    subscriptionServiceProvider.overrideWithValue(FakeSubscriptionService()),
    quickGuideAiServiceProvider.overrideWithValue(FakeQuickGuideAiService()),
    imageAnalysisServiceProvider.overrideWithValue(FakeImageAnalysisService()),
    onboardingRepositoryProvider.overrideWithValue(
      InMemoryOnboardingRepository(welcomeDone: true),
    ),
    dailyStoryRepositoryProvider.overrideWithValue(
      InMemoryDailyStoryRepository(),
    ),
  ];
}

Future<void> _whenUserSelectsBottomNavItem(
  WidgetTester tester,
  String labelKey,
) async {
  await tester.tap(find.text(labelKey));
  await tester.pump(const Duration(milliseconds: 50));
}

void _thenExploreTabIsActive() {
  expect(find.byType(MainScreen), findsOneWidget);
  // Explore tab is the default index; its screen renders the title key.
  expect(find.text('explore.title'), findsOneWidget);
}

void _thenJourneyTabIsActive() {
  expect(find.byType(JourneyScreen), findsOneWidget);
}

void _thenQuickGuideTabIsActive() {
  expect(find.byType(QuickGuideScreen), findsOneWidget);
}

void _thenSettingsTabIsActive() {
  expect(find.byType(SettingsScreen), findsOneWidget);
}
