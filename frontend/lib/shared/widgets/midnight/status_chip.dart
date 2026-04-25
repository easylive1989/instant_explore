import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';

/// The visual tone of a [StatusChip].
enum StatusChipTone { active, neutral, error, warning, success }

/// A small uppercase label chip with five semantic tones.
///
/// Use [StatusChipTone] to communicate the nature of a status at a glance:
/// active (primary blue), neutral (surface), error (red), warning (orange),
/// or success (soft blue).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.neutral,
    this.icon,
  });

  /// The text displayed inside the chip; rendered in uppercase.
  final String label;

  /// The semantic tone controlling background and foreground colors.
  final StatusChipTone tone;

  /// Optional leading icon displayed before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChipColors _resolveColors(StatusChipTone tone) {
    switch (tone) {
      case StatusChipTone.active:
        return const _ChipColors(
          background: AppColors.primaryContainer,
          foreground: AppColors.primary,
        );
      case StatusChipTone.neutral:
        return const _ChipColors(
          background: AppColors.surfaceContainerHigh,
          foreground: AppColors.onSurface,
        );
      case StatusChipTone.error:
        return const _ChipColors(
          background: AppColors.errorContainer,
          foreground: AppColors.error,
        );
      case StatusChipTone.warning:
        return const _ChipColors(
          background: AppColors.tertiaryContainer,
          foreground: AppColors.tertiary,
        );
      case StatusChipTone.success:
        return const _ChipColors(
          background: AppColors.secondaryContainer,
          foreground: AppColors.secondary,
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
