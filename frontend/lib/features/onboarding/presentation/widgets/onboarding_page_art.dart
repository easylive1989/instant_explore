import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/shared/widgets/pulsing_glow.dart';
import 'package:flutter/material.dart';

/// Editorial hero illustration for a single welcome carousel page.
///
/// Layers (back → front):
///   1. A ghostly oversized serial numeral ("01" .. "04") bleeding off the
///      top-left — creates the magazine/Wired editorial rhythm.
///   2. A slowly pulsing radial glow in the page's accent color so the
///      dark canvas feels alive rather than static.
///   3. The feature icon, scaled larger than the default Material size.
///   4. A glass-morphic chip label (uppercase) anchoring the icon to the
///      page's topic.
///
/// All layers are vector-only — no image assets — so the welcome flow stays
/// fully offline and the bundle size is untouched.
class OnboardingPageArt extends StatelessWidget {
  const OnboardingPageArt({
    super.key,
    required this.icon,
    required this.serialLabel,
    required this.chipLabel,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String serialLabel;
  final String chipLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _GhostSerial(label: serialLabel),
          PulsingGlow(
            color: accent,
            size: 260,
            child: Icon(icon, size: 84, color: accent),
          ),
          Positioned(
            bottom: 8,
            child: _ChipLabel(label: chipLabel, accent: accent),
          ),
        ],
      ),
    );
  }
}

class _GhostSerial extends StatelessWidget {
  const _GhostSerial({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: -12,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 220,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -8,
          color: AppColors.surfaceVariant,
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
