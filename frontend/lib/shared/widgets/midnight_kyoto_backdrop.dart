import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Atmospheric backdrop layer for the Midnight Kyoto brand moments.
///
/// Draws a deep radial wash of electric blue at the top so the canvas
/// reads as "night sky over Kyoto" rather than a flat dark rectangle.
/// Used by both the onboarding welcome carousel and the subscription
/// paywall to share the same brand atmosphere.
class MidnightKyotoBackdrop extends StatelessWidget {
  const MidnightKyotoBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.1,
          colors: [Color(0x33137FEC), AppColors.backgroundDark],
          stops: [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
