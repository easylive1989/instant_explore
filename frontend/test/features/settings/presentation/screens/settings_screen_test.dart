import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/in_memory_onboarding_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
import '../../../../helpers/pump_app.dart';

const _fakeVersionLabel = 'Version 9.9.9 (Build 42)';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SettingsScreen', () {
    testWidgets(
      'given a free user with remaining usage, when the screen loads, '
      'then the preferences, usage and upgrade CTA are visible',
      (tester) async {
        await _givenSettingsScreen(tester, status: SubscriptionStatus.free);

        _thenPreferencesSectionIsVisible();
        _thenUsageSectionIsVisible();
        _thenUpgradeCtaIsVisible();
      },
    );

    testWidgets(
      'given a premium user, when the screen loads, '
      'then the premium-active tile is shown instead of the upgrade CTA',
      (tester) async {
        await _givenSettingsScreen(
          tester,
          status: const SubscriptionStatus(isPremium: true),
        );

        _thenPremiumTileIsVisible();
        _thenUpgradeCtaIsHidden();
      },
    );

    testWidgets(
      'given the current theme is dark, when the user toggles theme off, '
      'then the theme switch value flips to light',
      (tester) async {
        await _givenSettingsScreen(tester);

        await _whenUserTogglesThemeSwitch(tester);

        _thenThemeSwitchIsOff(tester);
      },
    );

    testWidgets(
      'given the app version future resolves, when the screen settles, '
      'then the version label is rendered',
      (tester) async {
        await _givenSettingsScreen(tester);

        await _whenVersionFutureResolves(tester);

        _thenVersionLabelIsVisible();
      },
    );
  });
}

Future<void> _givenSettingsScreen(
  WidgetTester tester, {
  InMemoryUsageRepository? usage,
  SubscriptionStatus status = SubscriptionStatus.free,
}) async {
  final usageRepo = usage ?? InMemoryUsageRepository(usedToday: 0);

  // The settings screen is taller than the default 800x600 test surface
  // after the onboarding section was added. Enlarging the surface lets
  // `find.text` locate tiles below the fold without having to scroll.
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await pumpScreen(
    tester,
    child: const SettingsScreen(),
    overrides: [
      usageRepositoryProvider.overrideWithValue(usageRepo),
      usageStatusProvider.overrideWith(
        (ref) async => usageRepo.getUsageStatus(),
      ),
      subscriptionStatusProvider.overrideWith(
        (ref) => Stream<SubscriptionStatus>.value(status),
      ),
      appVersionStringProvider.overrideWith((ref) async => _fakeVersionLabel),
      onboardingRepositoryProvider.overrideWithValue(
        InMemoryOnboardingRepository(welcomeDone: true),
      ),
    ],
  );
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenUserTogglesThemeSwitch(WidgetTester tester) async {
  await tester.tap(find.byType(AdaptiveSwitch));
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _whenVersionFutureResolves(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

void _thenPreferencesSectionIsVisible() {
  expect(find.text('SETTINGS.PREFERENCES'), findsOneWidget);
  expect(find.text('settings.change_language'), findsOneWidget);
  expect(find.text('settings.theme'), findsOneWidget);
}

void _thenUsageSectionIsVisible() {
  expect(find.text('SETTINGS.DAILY_USAGE'), findsOneWidget);
  expect(find.text('settings.daily_usage'), findsOneWidget);
}

void _thenUpgradeCtaIsVisible() {
  expect(find.text('subscription.upgrade_cta'), findsOneWidget);
}

void _thenPremiumTileIsVisible() {
  expect(find.text('subscription.premium_active'), findsOneWidget);
}

void _thenUpgradeCtaIsHidden() {
  expect(find.text('subscription.upgrade_cta'), findsNothing);
}

void _thenThemeSwitchIsOff(WidgetTester tester) {
  final switchWidget = tester.widget<AdaptiveSwitch>(
    find.byType(AdaptiveSwitch),
  );
  expect(switchWidget.value, isFalse);
}

void _thenVersionLabelIsVisible() {
  expect(find.text(_fakeVersionLabel), findsOneWidget);
}
