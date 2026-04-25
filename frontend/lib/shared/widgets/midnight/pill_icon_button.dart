import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

/// Visual style variants for [PillIconButton].
enum PillIconButtonVariant { filled, ghost }

/// A circular icon button with filled/ghost variants and optional tooltip.
class PillIconButton extends StatelessWidget {
  const PillIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = PillIconButtonVariant.filled,
    this.size = 48,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PillIconButtonVariant variant;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final isFilled = variant == PillIconButtonVariant.filled;

    final material = Material(
      color: isFilled
          ? (disabled
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary)
          : AppColors.surfaceContainerHigh,
      shape: CircleBorder(
        side: isFilled
            ? BorderSide.none
            : const BorderSide(color: AppColors.outlineVariant),
      ),
      shadowColor: isFilled && !disabled
          ? AppColors.primary.withValues(alpha: 0.2)
          : null,
      elevation: isFilled && !disabled ? 6 : 0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: isFilled
                ? (disabled
                      ? AppColors.onPrimary.withValues(alpha: 0.5)
                      : AppColors.onPrimary)
                : AppColors.onSurface,
            size: size * 0.5,
          ),
        ),
      ),
    );

    final wrapped = PressScale(
      onTap: disabled ? null : onPressed,
      child: material,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: wrapped);
    }
    return wrapped;
  }
}
