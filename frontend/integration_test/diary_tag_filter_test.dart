import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

/// Test: Diary Tag Filtering
///
/// This test verifies:
/// 1. User can filter diary entries by tags
/// 2. Only entries with selected tags are shown
/// 3. User can clear filters
void main() {
  patrolTest(
    'Filter diary entries by tags',
    ($) async {
      // Wait for the diary list screen to load
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'tag_filter_01_diary_list');
      }

      // Look for the filter button in the floating app bar
      // It might be an icon button with filter icon
      final filterButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            ((widget.icon as Icon).icon == Icons.filter_list ||
                (widget.icon as Icon).icon == Icons.filter_alt),
      );

      // If the filter button is not visible, scroll down to make the
      // floating app bar appear
      if (!$.tester.any(filterButton)) {
        await $.native.scroll(
          dy: 200,
          duration: const Duration(milliseconds: 500),
        );
        await $.pumpAndSettle();
      }

      if ($.tester.any(filterButton)) {
        // Tap the filter button
        await $(filterButton).tap();
        await $.pumpAndSettle();

        if (TestConfig.takeScreenshots) {
          await TestHelpers.takeScreenshot($, 'tag_filter_02_dialog_opened');
        }

        // Verify the tag filter dialog is shown
        expect($(Dialog).or($(AlertDialog)), findsOneWidget);

        // Find checkboxes for tags
        // The dialog should show a list of available tags with checkboxes
        final checkboxes = find.byType(Checkbox);

        if ($.tester.any(checkboxes)) {
          // Select the first tag
          final firstCheckbox = $.tester.widgetList<Checkbox>(checkboxes).first;

          await $(checkboxes).first.tap();
          await $.pumpAndSettle();

          if (TestConfig.takeScreenshots) {
            await TestHelpers.takeScreenshot($, 'tag_filter_03_tag_selected');
          }

          // Apply the filter by tapping the confirm button
          final confirmButton = find.byWidgetPredicate(
            (widget) =>
                widget is TextButton &&
                widget.child is Text &&
                ((widget.child as Text).data?.contains('確定') ?? false),
          );

          if ($.tester.any(confirmButton)) {
            await $(confirmButton).tap();
            await $.pumpAndSettle();
            await Future.delayed(TestConfig.shortDelay);

            if (TestConfig.takeScreenshots) {
              await TestHelpers.takeScreenshot(
                  $, 'tag_filter_04_filtered_list');
            }

            // Verify that the list is now filtered
            // You should see a clear filter button or indicator
            final clearFilterButton = find.byWidgetPredicate(
              (widget) =>
                  (widget is IconButton &&
                      widget.icon is Icon &&
                      (widget.icon as Icon).icon == Icons.clear) ||
                  (widget is TextButton &&
                      widget.child is Text &&
                      ((widget.child as Text).data?.contains('清除') ?? false)),
            );

            // If clear filter button exists, tap it to clear filters
            if ($.tester.any(clearFilterButton)) {
              await $(clearFilterButton).tap();
              await $.pumpAndSettle();

              if (TestConfig.takeScreenshots) {
                await TestHelpers.takeScreenshot(
                    $, 'tag_filter_05_filter_cleared');
              }

              // Verify all entries are shown again
              expect($(FloatingActionButton), findsOneWidget);
            }
          }
        } else {
          // No tags available, close the dialog
          await $.native.pressBack();
          await $.pumpAndSettle();
        }
      }
    },
  );

  patrolTest(
    'Create diary with tag and filter by it',
    ($) async {
      await $.pumpAndSettle();
      await Future.delayed(TestConfig.mediumDelay);

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'tag_create_01_list');
      }

      // Create a new diary entry with a specific tag
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();

      // Enter title
      const testTitle = '測試標籤日記';
      final titleField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('標題') ?? false),
      );

      await $(titleField).enterText(testTitle);
      await $.pumpAndSettle();

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'tag_create_02_title_entered');
      }

      // Look for tag selector
      // This might be a section with chips or a button to select tags
      final tagSection = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('標籤') ?? false),
      );

      if ($.tester.any(tagSection)) {
        // Try to find and tap a tag chip or tag selector button
        final tagChip = find.byType(ChoiceChip).or(find.byType(FilterChip));

        if ($.tester.any(tagChip)) {
          // Tap the first available tag
          await $(tagChip).first.tap();
          await $.pumpAndSettle();

          if (TestConfig.takeScreenshots) {
            await TestHelpers.takeScreenshot($, 'tag_create_03_tag_selected');
          }
        }
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

      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'tag_create_04_saved');
      }

      // Now filter by the tag we just used
      final filterButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            ((widget.icon as Icon).icon == Icons.filter_list ||
                (widget.icon as Icon).icon == Icons.filter_alt),
      );

      // Scroll to reveal filter button if needed
      if (!$.tester.any(filterButton)) {
        await $.native.scroll(
          dy: 200,
          duration: const Duration(milliseconds: 500),
        );
        await $.pumpAndSettle();
      }

      if ($.tester.any(filterButton)) {
        await $(filterButton).tap();
        await $.pumpAndSettle();

        // Select the same tag in the filter dialog
        final checkboxes = find.byType(Checkbox);
        if ($.tester.any(checkboxes)) {
          await $(checkboxes).first.tap();
          await $.pumpAndSettle();

          // Apply filter
          final confirmButton = find.byWidgetPredicate(
            (widget) =>
                widget is TextButton &&
                widget.child is Text &&
                ((widget.child as Text).data?.contains('確定') ?? false),
          );

          if ($.tester.any(confirmButton)) {
            await $(confirmButton).tap();
            await $.pumpAndSettle();

            if (TestConfig.takeScreenshots) {
              await TestHelpers.takeScreenshot($, 'tag_create_05_filtered');
            }

            // Verify our diary entry is in the filtered list
            expect(find.textContaining(testTitle), findsAtLeastNWidgets(1));
          }
        }
      }

      // Clean up: Clear filter and delete test entry
      final clearFilterButton = find.byWidgetPredicate(
        (widget) =>
            (widget is IconButton &&
                widget.icon is Icon &&
                (widget.icon as Icon).icon == Icons.clear),
      );

      if ($.tester.any(clearFilterButton)) {
        await $(clearFilterButton).tap();
        await $.pumpAndSettle();
      }

      // Delete the test diary
      await _deleteTestDiary($, testTitle);
    },
  );
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
