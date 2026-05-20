import 'package:context_app/features/analytics/domain/models/consent_state.dart';
import 'package:context_app/features/analytics/providers.dart';
import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/features/auth/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_auth_service.dart';
import '../../../../fakes/in_memory_consent_repository.dart';
import '../../../../fakes/in_memory_onboarding_repository.dart';
import '../../../../fakes/in_memory_usage_repository.dart';
import '../../../../helpers/pump_app.dart';

const _kSwitchKey = ValueKey('analytics_consent_switch');

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SettingsScreen analytics consent toggle', () {
    testWidgets(
      'given_consent_enabled_when_settings_renders_then_switch_shows_on',
      (tester) async {
        final consent = InMemoryConsentRepository(
          initial: ConsentState(enabled: true, updatedAt: DateTime(2026)),
        );
        await _givenSettingsScreen(tester, consentRepository: consent);
        await _settle(tester);

        final toggle = tester.widget<Switch>(_findSwitch());
        expect(toggle.value, isTrue);
      },
    );

    testWidgets(
      'given_consent_disabled_when_settings_renders_then_switch_shows_off',
      (tester) async {
        final consent = InMemoryConsentRepository(
          initial: ConsentState(enabled: false, updatedAt: DateTime(2026)),
        );
        await _givenSettingsScreen(tester, consentRepository: consent);
        await _settle(tester);
        // Stream emits the seed value via a microtask, so allow another
        // frame for the StreamProvider to flip out of AsyncLoading.
        await tester.pumpAndSettle();

        final toggle = tester.widget<Switch>(_findSwitch());
        expect(toggle.value, isFalse);
      },
    );

    testWidgets(
      'given_settings_when_user_toggles_off_then_consent_repository_'
      'write_called_with_disabled_state',
      (tester) async {
        final consent = InMemoryConsentRepository(
          initial: ConsentState(enabled: true, updatedAt: DateTime(2026)),
        );
        await _givenSettingsScreen(tester, consentRepository: consent);
        await _settle(tester);

        await tester.tap(find.byKey(_kSwitchKey));
        await _settle(tester);

        expect(consent.writeCount, 1);
        expect(consent.writes.first.enabled, isFalse);
      },
    );

    testWidgets(
      'given_consent_state_changes_externally_when_settings_visible_'
      'then_switch_reflects_new_state',
      (tester) async {
        final consent = InMemoryConsentRepository(
          initial: ConsentState(enabled: true, updatedAt: DateTime(2026)),
        );
        await _givenSettingsScreen(tester, consentRepository: consent);
        await _settle(tester);

        consent.emit(
          ConsentState(enabled: false, updatedAt: DateTime(2026, 1, 2)),
        );
        await _settle(tester);

        final toggle = tester.widget<Switch>(_findSwitch());
        expect(toggle.value, isFalse);
      },
    );
  });
}

Future<void> _givenSettingsScreen(
  WidgetTester tester, {
  required InMemoryConsentRepository consentRepository,
}) async {
  addTearDown(consentRepository.dispose);
  final auth = FakeAuthService();
  addTearDown(auth.dispose);
  final usageRepo = InMemoryUsageRepository(usedToday: 0);

  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await pumpScreen(
    tester,
    child: const SettingsScreen(),
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      usageRepositoryProvider.overrideWithValue(usageRepo),
      usageStatusProvider.overrideWith(
        (ref) async => usageRepo.getUsageStatus(),
      ),
      subscriptionStatusProvider.overrideWith(
        (ref) => Stream<SubscriptionStatus>.value(SubscriptionStatus.free),
      ),
      appVersionStringProvider.overrideWith((ref) async => 'v-test'),
      onboardingRepositoryProvider.overrideWithValue(
        InMemoryOnboardingRepository(welcomeDone: true),
      ),
      consentRepositoryProvider.overrideWithValue(consentRepository),
    ],
  );
}

/// Pumps enough frames for the broadcast stream to deliver its current
/// value and any subsequent updates the test triggers.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Finder _findSwitch() {
  // AdaptiveSwitch wraps Switch.adaptive which materialises as a Switch
  // on the default test platform.
  return find.descendant(
    of: find.byKey(_kSwitchKey),
    matching: find.byType(Switch),
  );
}
