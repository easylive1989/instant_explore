import 'dart:ui';

import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:flutter/material.dart';

/// A semi-transparent surface card with backdrop blur, ghost border,
/// and rounded corners. Optional [onTap] adds a press-scale interaction
/// and a Material ripple.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
    this.blurSigma = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: radius,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      card = PressScale(
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: radius, child: card),
        ),
      );
    }

    return card;
  }
}
