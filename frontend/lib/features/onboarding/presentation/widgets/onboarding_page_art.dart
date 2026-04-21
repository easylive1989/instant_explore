import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Large hero-icon illustration used on each welcome carousel page.
///
/// A vector-only illustration keeps the asset bundle small and guarantees
/// the welcome flow has no external dependency (no network image, no API).
class OnboardingPageArt extends StatelessWidget {
  const OnboardingPageArt({
    super.key,
    required this.icon,
    this.tint = AppColors.primary,
  });

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              tint.withValues(alpha: 0.18),
              tint.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Icon(icon, size: 96, color: tint),
      ),
    );
  }
}
