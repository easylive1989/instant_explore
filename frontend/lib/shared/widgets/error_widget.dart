import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:travel_diary/core/constants/ui_constants.dart';

/// Error display widget with optional retry action.
///
/// Provides a consistent error state UI across the application.
class ErrorDisplay extends StatelessWidget {
  ErrorDisplay({
    required this.message,
    super.key,
    this.onRetry,
    this.icon,
    String? retryButtonText,
  }) : retryButtonText = retryButtonText ?? 'common.retry'.tr();

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String retryButtonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: UiConstants.paddingAllLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: UiConstants.iconSizeXl,
              color: colorScheme.error,
            ),
            const SizedBox(height: UiConstants.spacingMd),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UiConstants.spacingLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: UiConstants.paddingHorizontalLg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiConstants.radiusSm),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error message for form fields
class InlineError extends StatelessWidget {
  const InlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: UiConstants.spacingXs,
        left: UiConstants.spacingMd,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: UiConstants.iconSizeXs,
            color: colorScheme.error,
          ),
          const SizedBox(width: UiConstants.spacingXs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget when no data is available
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: UiConstants.paddingAllLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: UiConstants.iconSizeXl * 1.5,
              color: colorScheme.outline,
            ),
            const SizedBox(height: UiConstants.spacingMd),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: UiConstants.spacingLg),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: UiConstants.paddingHorizontalLg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiConstants.radiusSm),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
