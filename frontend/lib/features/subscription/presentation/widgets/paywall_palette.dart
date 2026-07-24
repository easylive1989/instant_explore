import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';

/// Resolved colours for the immersive (always-dark) Field Journal paywall.
///
/// The paywall stays dark regardless of the app's light theme, so its colours
/// are a projection of [LorescapeTokens] via [BuildContext.tokens], which
/// supplies [LorescapeTokens.fallback] when the extension is absent (e.g.
/// widget tests). The accent still follows the active brand accent via
/// `tokens.clay`. [lineDark] is paywall-specific and not a token.
class PaywallPalette {
  const PaywallPalette({
    required this.inkBg,
    required this.clay,
    required this.clayDeep,
    required this.onDark,
    required this.onDark2,
    required this.onDark3,
    required this.lineDark,
    required this.rLg,
  });

  final Color inkBg;
  final Color clay;
  final Color clayDeep;
  final Color onDark;
  final Color onDark2;
  final Color onDark3;
  final Color lineDark;
  final double rLg;

  /// Faint clay wash used as the selected plan card fill.
  Color get claySelected => clay.withValues(alpha: 0.12);

  /// Translucent surface used by the "最划算" badge.
  Color get badgeSurface => onDark.withValues(alpha: 0.12);

  factory PaywallPalette.of(BuildContext context) {
    final t = context.tokens;
    return PaywallPalette(
      inkBg: t.inkBg,
      clay: t.clay,
      clayDeep: t.clayDeep,
      onDark: t.onDark,
      onDark2: t.onDark2,
      onDark3: t.onDark3,
      lineDark: const Color(0x1FF7F1E6),
      rLg: t.rLg,
    );
  }
}
