import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';

/// Custom button widget with consistent styling.
///
/// Provides primary, secondary, and text button variants.
class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buttonChild = isLoading
        ? SizedBox(
            width: UiConstants.iconSizeSm,
            height: UiConstants.iconSizeSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary
                    ? colorScheme.onPrimary
                    : colorScheme.primary,
              ),
            ),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: UiConstants.iconSizeSm),
              const SizedBox(width: UiConstants.spacingSm),
              child,
            ],
          )
        : child;

    final button = switch (variant) {
      ButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, UiConstants.buttonHeightMd),
          padding: UiConstants.paddingHorizontalLg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusSm),
          ),
        ),
        child: buttonChild,
      ),
      ButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, UiConstants.buttonHeightMd),
          padding: UiConstants.paddingHorizontalLg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusSm),
          ),
          side: BorderSide(color: colorScheme.primary),
        ),
        child: buttonChild,
      ),
      ButtonVariant.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, UiConstants.buttonHeightMd),
          padding: UiConstants.paddingHorizontalLg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusSm),
          ),
        ),
        child: buttonChild,
      ),
      ButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          minimumSize: const Size(0, UiConstants.buttonHeightMd),
          padding: UiConstants.paddingHorizontalLg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusSm),
          ),
        ),
        child: buttonChild,
      ),
    };

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Button variant types
enum ButtonVariant {
  /// Primary button with filled background
  primary,

  /// Secondary button with outline
  secondary,

  /// Text-only button
  text,

  /// Danger button for destructive actions
  danger,
}
