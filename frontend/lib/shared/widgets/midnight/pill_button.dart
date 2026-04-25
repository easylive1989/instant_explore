import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

/// Variants that control the visual style of a [PillButton].
enum PillButtonVariant { primary, secondary, ghost }

/// Stadium-shaped button with three variants and an optional leading icon.
///
/// Set [onPressed] to `null` to disable the button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final colors = _resolveColors(disabled);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final material = Material(
      color: colors.background,
      shape: StadiumBorder(side: colors.borderSide ?? BorderSide.none),
      shadowColor: colors.shadow,
      elevation: colors.shadow != null ? 6 : 0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: content,
        ),
      ),
    );

    return PressScale(onTap: disabled ? null : onPressed, child: material);
  }

  _PillColors _resolveColors(bool disabled) {
    switch (variant) {
      case PillButtonVariant.primary:
        return _PillColors(
          background: disabled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
          foreground: disabled
              ? AppColors.onPrimary.withValues(alpha: 0.5)
              : AppColors.onPrimary,
          shadow: disabled ? null : AppColors.primary.withValues(alpha: 0.2),
        );
      case PillButtonVariant.secondary:
        return _PillColors(
          background: AppColors.surfaceContainerHigh,
          foreground: disabled
              ? AppColors.onSurface.withValues(alpha: 0.5)
              : AppColors.onSurface,
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        );
      case PillButtonVariant.ghost:
        return _PillColors(
          background: Colors.transparent,
          foreground: disabled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
        );
    }
  }
}

class _PillColors {
  const _PillColors({
    required this.background,
    required this.foreground,
    this.borderSide,
    this.shadow,
  });
  final Color background;
  final Color foreground;
  final BorderSide? borderSide;
  final Color? shadow;
}
