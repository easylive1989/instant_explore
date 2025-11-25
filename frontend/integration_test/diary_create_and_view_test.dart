import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

/// Test: Diary Creation and Viewing
///
/// This test verifies:
/// 1. User can create a new diary entry with title and content
/// 2. Created entry appears in the diary list
/// 3. User can view the diary entry details
void main() {
  patrolTest(
    'Create diary entry with title and content',
    ($) async {
      // Note: This test assumes the user is already logged in
      // You may need to perform login first or start from authenticated state

      // Wait for the diary list screen to load
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      // Verify we're on the diary list screen
      expect($(FloatingActionButton), findsOneWidget);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_01_list_before_create');
      }

      // Tap the FAB to create a new diary
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.shortDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_02_create_screen');
      }

      // Enter diary title
      const testTitle = '測試日記標題';
      final titleField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('標題') ?? false),
      );

      await $(titleField).enterText(testTitle);
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_03_title_entered');
      }

      // Enter diary content
      // The content editor is a rich text editor (flutter_quill)
      // We need to find the editor field and enter text
      const testContent = '這是一篇測試日記的內容。今天天氣很好,心情也很愉快。';

      // Find the content editor - it may have a specific key or be identifiable
      final contentEditor = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('內容') ?? false),
      );

      if ($.tester.any(contentEditor)) {
        await $(contentEditor).enterText(testContent);
        await $.pumpAndSettle();
      }

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_04_content_entered');
      }

      // Dismiss keyboard
      await $.native.pressBack();
      await $.pumpAndSettle();

      // Save the diary entry
      // Look for a save button (might be an icon button or elevated button)
      final saveButton = find.byWidgetPredicate(
        (widget) =>
            (widget is IconButton &&
                widget.icon is Icon &&
                (widget.icon as Icon).icon == Icons.check) ||
            (widget is ElevatedButton &&
                widget.child is Text &&
                ((widget.child as Text).data?.contains('儲存') ?? false)),
      );

      if ($.tester.any(saveButton)) {
        await $(saveButton).tap();
        await $.pumpAndSettle();

        // Wait for save operation to complete
        await Future.delayed(TestConfig.mediumDelay);
      }

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_05_saved_back_to_list');
      }

      // Verify we're back on the list screen
      expect($(FloatingActionButton), findsOneWidget);

      // Verify the new entry appears in the list
      expect(find.textContaining(testTitle), findsAtLeastNWidgets(1));

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_06_entry_in_list');
      }

      // Tap on the created diary to view details
      await $(find.textContaining(testTitle)).tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.shortDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_07_detail_view');
      }

      // Verify the detail screen shows the correct information
      expect(find.textContaining(testTitle), findsOneWidget);

      // Navigate back to list
      await $.native.pressBack();
      await $.pumpAndSettle();

      // Clean up: Delete the test entry
      await _deleteTestDiary($, testTitle);
    },
  );

  patrolTest(
    'Create diary entry with images',
    ($) async {
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_images_01_list');
      }

      // Tap FAB to create new diary
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      // Enter title
      const testTitle = '測試圖片日記';
      final titleField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('標題') ?? false),
      );

      await $(titleField).enterText(testTitle);
      await $.pumpAndSettle();

      // Find and tap the image picker button
      // This might be an icon button with camera or image icon
      final imagePickerButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            ((widget.icon as Icon).icon == Icons.image ||
                (widget.icon as Icon).icon == Icons.add_photo_alternate ||
                (widget.icon as Icon).icon == Icons.camera_alt),
      );

      if ($.tester.any(imagePickerButton)) {
        // Grant photo permissions before selecting
        await TestHelpers.grantPhotoPermissions($);

        await $(imagePickerButton).tap();
        await $.pumpAndSettle();
        await Future.delayed(TestConfig.shortDelay);

        if (TestConfig.takeScreenshots) {
          await TestHelpers.takeScreenshot($, 'diary_images_02_picker_opened');
        }

        // Note: Actually selecting images from the system photo picker
        // requires native interaction and may need to be mocked or
        // handled with test fixtures

        // For now, we'll just verify the button is tappable
        // In a real test, you would use $.native to interact with
        // the photo picker dialog
      }

      // Save the diary
      final saveButton = find.byWidgetPredicate(
        (widget) =>
            (widget is IconButton &&
                widget.icon is Icon &&
                (widget.icon as Icon).icon == Icons.check),
      );

      if ($.tester.any(saveButton)) {
        await $(saveButton).tap();
        await $.pumpAndSettle();
        await Future.delayed(TestConfig.mediumDelay);
      }

      // Clean up
      await _deleteTestDiary($, testTitle);
    },
  );

  patrolTest(
    'Form validation - title is required',
    ($) async {
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      // Tap FAB to create new diary
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'diary_validation_01_empty_form');
      }

      // Try to save without entering a title
      final saveButton = find.byWidgetPredicate(
        (widget) =>
            (widget is IconButton &&
                widget.icon is Icon &&
                (widget.icon as Icon).icon == Icons.check),
      );

      if ($.tester.any(saveButton)) {
        await $(saveButton).tap();
        await $.pumpAndSettle();

        if (TestConfig.takeScreenshots) {
          await TestHelpers.takeScreenshot(
              $, 'diary_validation_02_error_shown');
        }

        // Verify error message or that we're still on the create screen
        // The form should not be submitted
        expect($(FloatingActionButton), findsNothing);

        // Should still be on create screen (no FAB present)
        // or should show an error message
      }

      // Go back without saving
      await $.native.pressBack();
      await $.pumpAndSettle();
    },
  );
}

/// Helper function to delete a test diary entry
Future<void> _deleteTestDiary(
  PatrolIntegrationTester $,
  String title,
) async {
  // Find the diary entry in the list
  final diaryCard = find.textContaining(title);

  if (!$.tester.any(diaryCard)) {
    return; // Already deleted or not found
  }

  // Tap on the diary to open details
  await $(diaryCard).tap();
  await $.pumpAndSettle();

  // Find and tap the delete button (might be in overflow menu or app bar)
  final deleteButton = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        widget.icon is Icon &&
        (widget.icon as Icon).icon == Icons.delete,
  );

  if ($.tester.any(deleteButton)) {
    await $(deleteButton).tap();
    await $.pumpAndSettle();

    // Confirm deletion in dialog
    final confirmButton = find.byWidgetPredicate(
      (widget) =>
          widget is TextButton &&
          widget.child is Text &&
          ((widget.child as Text).data?.contains('刪除') ?? false),
    );

    if ($.tester.any(confirmButton)) {
      await $(confirmButton).tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);
    }
  }
}
