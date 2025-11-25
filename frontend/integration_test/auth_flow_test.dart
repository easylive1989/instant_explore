import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:travel_diary/main.dart' as app;

import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

/// Test: Authentication Flow
///
/// This test verifies the complete authentication flow:
/// 1. App launches and shows login screen
/// 2. User can sign in with Google
/// 3. After successful login, user is redirected to diary list screen
/// 4. User can log out
void main() {
  patrolTest(
    'Authentication flow - Login and Logout',
    ($) async {
      // Launch the app with test configuration
      await _launchAppWithTestConfig($);

      // Verify login screen is displayed
      TestHelpers.verifyScreenDisplayed(
        $,
        find.text('使用 Google 登入'),
      );

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'auth_01_login_screen');
      }

      // Tap Google Sign In button
      await $(ElevatedButton).tap();

      // Note: For E2E tests with real Google auth, you would need to:
      // 1. Handle the Google OAuth web view or native dialog
      // 2. Enter test credentials
      // 3. Grant permissions
      //
      // For now, this assumes a test Supabase setup where Google auth
      // is mocked or a test account is automatically logged in

      // Wait for navigation to complete
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      // Verify successful login - should show diary list screen
      // Look for the FAB (Floating Action Button) which is on the diary list
      expect($(FloatingActionButton), findsOneWidget);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'auth_02_logged_in_diary_list');
      }

      // Navigate to settings
      await $(Icon).withIcon(Icons.settings).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'auth_03_settings_screen');
      }

      // Find and tap logout button
      // The logout button might be in a list, so scroll if needed
      final logoutButton = find.text('登出');

      if (!$.tester.any(logoutButton)) {
        await TestHelpers.scrollUntilVisible($, logoutButton);
      }

      await $(logoutButton).tap();
      await $.pumpAndSettle();

      // Confirm logout in dialog
      await $(TextButton).withText('確定').tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      // Verify we're back at login screen
      expect(find.text('使用 Google 登入'), findsOneWidget);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'auth_04_logged_out');
      }
    },
  );

  patrolTest(
    'Login screen displays correctly',
    ($) async {
      await _launchAppWithTestConfig($);

      // Verify all key elements are present on login screen
      expect($(Icon).withIcon(Icons.book), findsOneWidget);
      expect(find.text('旅食日記'), findsOneWidget);
      expect(find.text('使用 Google 登入'), findsOneWidget);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'login_screen_elements');
      }
    },
  );
}

/// Launch app with test configuration for local Supabase
Future<void> _launchAppWithTestConfig(PatrolIntegrationTester $) async {
  // Set up environment for testing
  if (TestConfig.useLocalSupabase) {
    // Note: To use local Supabase, run the app with these dart-defines:
    // --dart-define=SUPABASE_URL=http://localhost:54321
    // --dart-define=SUPABASE_ANON_KEY=your_local_anon_key
  }

  await $.pumpWidgetAndSettle(
    app.main() as Widget,
  );

  // Wait for initial loading
  await $.pumpAndSettle();
  await Future.delayed(TestConfig.shortDelay);
}
