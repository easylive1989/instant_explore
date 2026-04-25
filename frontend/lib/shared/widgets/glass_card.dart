import 'dart:ui';

import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';

/// A translucent, backdrop-blurred container that matches the
/// Midnight Kyoto "glass card" rule: white 8% fill + 10% white border +
/// 12px backdrop blur. Use for any floating surface on a dark canvas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.blur = 12,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Optional colored overlay mixed into the default white 8% fill.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final fill = tint != null
        ? Color.alphaBlend(tint!.withValues(alpha: 0.12), AppColors.white10)
        : AppColors.white10;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
