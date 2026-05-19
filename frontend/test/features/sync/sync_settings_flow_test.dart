// Sync conflict resolution (algorithm) and per-repository wiring are
// already covered by sync_merger_test and syncing_journey_repository_test.
// What was missing: the user-visible toggle. These tests pin that the
// SyncSettingsNotifier persists across notifier rebuilds, and that
// syncSessionProvider correctly composes the "enabled + signed in"
// gate that every syncing repository keys off of.

import 'package:context_app/features/auth/domain/models/auth_user.dart';
import 'package:context_app/features/auth/providers.dart';
import 'package:context_app/features/sync/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_auth_service.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Sync settings persistence', () {
    test(
      'given a default install, when the notifier first builds, '
      'then sync is off',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(syncSettingsProvider), isFalse);
      },
    );

    test(
      'given the user toggles sync on, when a fresh container reads the '
      'notifier, then the persisted value is restored',
      () async {
        final first = ProviderContainer();
        first.read(syncSettingsProvider);
        await first.read(syncSettingsProvider.notifier).setEnabled(true);
        first.dispose();

        // A new container simulates a fresh app launch.
        final second = ProviderContainer();
        addTearDown(second.dispose);
        // Trigger build() and let _loadFromPrefs settle.
        second.read(syncSettingsProvider);
        await Future<void>.delayed(Duration.zero);

        expect(second.read(syncSettingsProvider), isTrue);
      },
    );
  });

  group('Sync session composition', () {
    test(
      'given sync off and no user, then isActive is false',
      () async {
        // Without this override syncSessionProvider transitively watches
        // a real Supabase authStateChanges() stream and crashes.
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService()),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(syncSessionProvider).isActive, isFalse);
      },
    );

    test(
      'given sync on but no signed-in user, then isActive stays false',
      () async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService()),
          ],
        );
        addTearDown(container.dispose);

        container.read(syncSessionProvider);
        await container.read(syncSettingsProvider.notifier).setEnabled(true);

        expect(container.read(syncSessionProvider).isActive, isFalse);
      },
    );

    test(
      'given sync on and a signed-in user, then isActive becomes true',
      () async {
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(
              FakeAuthService(
                initialUser: const AuthUser(
                  id: 'user-42',
                  email: 'u@example.com',
                  displayName: 'U',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Drive the auth stream into the provider.
        container.read(authStateProvider);
        await Future<void>.delayed(Duration.zero);

        await container.read(syncSettingsProvider.notifier).setEnabled(true);
        final session = container.read(syncSessionProvider);

        expect(session.isActive, isTrue);
        expect(session.userId, 'user-42');
      },
    );
  });
}
