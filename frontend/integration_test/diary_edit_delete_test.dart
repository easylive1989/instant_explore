import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

/// Test: Diary Edit and Delete
///
/// This test verifies:
/// 1. User can edit an existing diary entry
/// 2. Changes are saved and reflected in the list
/// 3. User can delete a diary entry
/// 4. Deleted entry is removed from the list
void main() {
  patrolTest(
    'Edit existing diary entry',
    ($) async {
      // Wait for the diary list screen to load
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_01_list');
      }

      // First, create a diary entry to edit
      const originalTitle = '原始日記標題';
      const updatedTitle = '更新後的日記標題';

      await _createTestDiary($, originalTitle);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_02_diary_created');
      }

      // Find and tap the created diary entry
      final diaryCard = find.textContaining(originalTitle);
      expect(diaryCard, findsOneWidget);

      await $(diaryCard).tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.shortDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_03_detail_view');
      }

      // Find and tap the edit button
      final editButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.edit,
      );

      expect(editButton, findsOneWidget);
      await $(editButton).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_04_edit_mode');
      }

      // Edit the title
      final titleField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('標題') ?? false),
      );

      // Clear existing text and enter new title
      await $(titleField).enterText('');
      await $.pumpAndSettle();
      await $(titleField).enterText(updatedTitle);
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_05_title_updated');
      }

      // Save the changes
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

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_06_changes_saved');
      }

      // Verify the updated title is shown in the detail view
      expect(find.textContaining(updatedTitle), findsAtLeastNWidgets(1));

      // Navigate back to list
      await $.native.pressBack();
      await $.pumpAndSettle();

      // Verify the updated title appears in the list
      expect(find.textContaining(updatedTitle), findsAtLeastNWidgets(1));
      expect(find.textContaining(originalTitle), findsNothing);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'edit_07_updated_in_list');
      }

      // Clean up: Delete the test entry
      await _deleteTestDiary($, updatedTitle);
    },
  );

  patrolTest(
    'Delete diary entry',
    ($) async {
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_01_list');
      }

      // Create a test diary entry
      const testTitle = '待刪除的日記';
      await _createTestDiary($, testTitle);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_02_diary_created');
      }

      // Verify it exists in the list
      expect(find.textContaining(testTitle), findsAtLeastNWidgets(1));

      // Tap on the diary to open details
      await $(find.textContaining(testTitle)).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_03_detail_view');
      }

      // Find and tap the delete button
      final deleteButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.delete,
      );

      expect(deleteButton, findsOneWidget);
      await $(deleteButton).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_04_confirm_dialog');
      }

      // Confirm deletion in the dialog
      final confirmButton = find.byWidgetPredicate(
        (widget) =>
            widget is TextButton &&
            widget.child is Text &&
            ((widget.child as Text).data?.contains('刪除') ?? false),
      );

      expect(confirmButton, findsOneWidget);
      await $(confirmButton).tap();
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_05_deleted_back_to_list');
      }

      // Verify we're back at the list and the entry is gone
      expect($(FloatingActionButton), findsOneWidget);
      expect(find.textContaining(testTitle), findsNothing);
    },
  );

  patrolTest(
    'Delete confirmation can be cancelled',
    ($) async {
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      // Create a test diary entry
      const testTitle = '測試取消刪除';
      await _createTestDiary($, testTitle);

      // Open the diary detail
      await $(find.textContaining(testTitle)).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_cancel_01_detail');
      }

      // Tap delete button
      final deleteButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.delete,
      );

      await $(deleteButton).tap();
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'delete_cancel_02_dialog');
      }

      // Cancel the deletion
      final cancelButton = find.byWidgetPredicate(
        (widget) =>
            widget is TextButton &&
            widget.child is Text &&
            ((widget.child as Text).data?.contains('取消') ?? false),
      );

      if ($.tester.any(cancelButton)) {
        await $(cancelButton).tap();
        await $.pumpAndSettle();

        if (TestConfig.takeScreenshots) {
          await TestHelpers.takeScreenshot($, 'delete_cancel_03_cancelled');
        }

        // Verify we're still on the detail screen
        expect(deleteButton, findsOneWidget);

        // Navigate back to list
        await $.native.pressBack();
        await $.pumpAndSettle();

        // Verify the entry still exists
        expect(find.textContaining(testTitle), findsAtLeastNWidgets(1));

        // Clean up: Delete the test entry for real this time
        await _deleteTestDiary($, testTitle);
      }
    },
  );
}

/// Helper function to create a test diary entry
Future<void> _createTestDiary(
  PatrolIntegrationTester $,
  String title,
) async {
  // Tap FAB to create new diary
  await $(FloatingActionButton).tap();
  await $.pumpAndSettle();

  // Enter title
  final titleField = find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        (widget.decoration?.hintText?.contains('標題') ?? false),
  );

  await $(titleField).enterText(title);
  await $.pumpAndSettle();

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
}

/// Helper function to delete a test diary entry
Future<void> _deleteTestDiary(
  PatrolIntegrationTester $,
  String title,
) async {
  final diaryCard = find.textContaining(title);

  if (!$.tester.any(diaryCard)) {
    return;
  }

  await $(diaryCard).tap();
  await $.pumpAndSettle();

  final deleteButton = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        widget.icon is Icon &&
        (widget.icon as Icon).icon == Icons.delete,
  );

  if ($.tester.any(deleteButton)) {
    await $(deleteButton).tap();
    await $.pumpAndSettle();

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
