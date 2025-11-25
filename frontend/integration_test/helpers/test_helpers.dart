import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

/// Test helper utilities for Patrol tests
class TestHelpers {
  /// Wait for a loading indicator to disappear
  static Future<void> waitForLoadingToDisappear(
    PatrolIntegrationTester $,
  ) async {
    // Wait for either CircularProgressIndicator or LinearProgressIndicator
    await $.waitUntilVisible(
      $(CircularProgressIndicator).or($(LinearProgressIndicator)),
      timeout: const Duration(seconds: 2),
    ).catchError((_) => null);

    await $.waitUntilGone(
      $(CircularProgressIndicator).or($(LinearProgressIndicator)),
      timeout: const Duration(seconds: 30),
    );
  }

  /// Wait for a snackbar message to appear and optionally verify its content
  static Future<void> waitForSnackBar(
    PatrolIntegrationTester $, {
    String? containsText,
  }) async {
    await $.waitUntilVisible($(SnackBar));

    if (containsText != null) {
      expect($(SnackBar).$(Text), findsWidgets);
      final textWidgets = $.tester.widgetList<Text>(find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      ));

      final hasMatchingText = textWidgets.any((text) =>
          text.data?.contains(containsText) == true ||
          (text.textSpan?.toPlainText().contains(containsText) ?? false));

      expect(hasMatchingText, true,
          reason: 'Expected SnackBar to contain "$containsText"');
    }
  }

  /// Scroll until a widget becomes visible
  static Future<void> scrollUntilVisible(
    PatrolIntegrationTester $,
    Finder finder, {
    double delta = 300,
    int maxScrolls = 50,
  }) async {
    for (var i = 0; i < maxScrolls; i++) {
      if ($.tester.any(finder)) {
        await $.scrollUntilVisible(finder: finder);
        return;
      }
      await $.native.scroll(
        dy: delta,
        duration: const Duration(milliseconds: 500),
      );
    }
    throw Exception('Widget not found after $maxScrolls scrolls');
  }

  /// Enter text into a text field by finding it with a label or hint
  static Future<void> enterTextInField(
    PatrolIntegrationTester $, {
    String? labelText,
    String? hintText,
    required String text,
  }) async {
    Finder textFieldFinder;

    if (labelText != null) {
      textFieldFinder = find.widgetWithText(TextField, labelText);
    } else if (hintText != null) {
      textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == hintText,
      );
    } else {
      throw ArgumentError('Either labelText or hintText must be provided');
    }

    await $(textFieldFinder).enterText(text);
    await $.pumpAndSettle();
  }

  /// Tap a button by its text or icon
  static Future<void> tapButton(
    PatrolIntegrationTester $, {
    String? text,
    IconData? icon,
  }) async {
    if (text != null) {
      await $(text).tap();
    } else if (icon != null) {
      await $(Icon).withIcon(icon).tap();
    } else {
      throw ArgumentError('Either text or icon must be provided');
    }
    await $.pumpAndSettle();
  }

  /// Wait for navigation to complete
  static Future<void> waitForNavigation(PatrolIntegrationTester $) async {
    await $.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Print debug information about widgets on screen
  static void debugPrintWidgets(PatrolIntegrationTester $) {
    if (kDebugMode) {
      debugPrint('=== Widgets on screen ===');
      $.tester.allWidgets.take(20).forEach((widget) {
        debugPrint(widget.runtimeType.toString());
      });
      debugPrint('=========================');
    }
  }

  /// Take a screenshot with a descriptive name
  static Future<void> takeScreenshot(
    PatrolIntegrationTester $,
    String name,
  ) async {
    await $.native.takeScreenshot(name);
  }

  /// Grant location permissions
  static Future<void> grantLocationPermissions(
    PatrolIntegrationTester $,
  ) async {
    await $.native.grantPermissionWhenInUse();
  }

  /// Grant photo library permissions
  static Future<void> grantPhotoPermissions(
    PatrolIntegrationTester $,
  ) async {
    await $.native.grantPermissionOnlyThisTime();
  }

  /// Verify that a screen is displayed by checking for a specific widget
  static void verifyScreenDisplayed(
    PatrolIntegrationTester $,
    Finder screenIdentifier,
  ) {
    expect(screenIdentifier, findsOneWidget);
  }

  /// Dismiss keyboard if it's open
  static Future<void> dismissKeyboard(PatrolIntegrationTester $) async {
    await $.native.pressHome();
    await $.native.openApp();
    await $.pumpAndSettle();
  }
}

/// Extension methods for easier text matching
extension PatrolTextExtensions on PatrolIntegrationTester {
  /// Find text that contains a substring (case-insensitive)
  Finder textContaining(String text) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data?.toLowerCase().contains(text.toLowerCase()) ?? false),
    );
  }
}
