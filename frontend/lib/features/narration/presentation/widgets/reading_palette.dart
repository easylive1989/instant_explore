import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';

/// Resolved colours for the Field Journal narration reader.
///
/// The reader uses the warm "reading surface" (sepia by default) for its body
/// and dark chrome for the floating audio bar. Colours come from
/// [LorescapeTokens] (or const fallbacks when the extension is absent, e.g.
/// widget tests); the accent follows the active brand accent via `tokens.clay`.
class ReadingPalette {
  const ReadingPalette({
    required this.readBg,
    required this.readInk,
    required this.readDim,
    required this.readLine,
    required this.readCap,
    required this.clay,
    required this.inkBg,
    required this.inkBg2,
    required this.onDark,
    required this.onDark2,
    required this.rLg,
  });

  final Color readBg;
  final Color readInk;
  final Color readDim;
  final Color readLine;
  final Color readCap;
  final Color clay;
  final Color inkBg;
  final Color inkBg2;
  final Color onDark;
  final Color onDark2;
  final double rLg;

  factory ReadingPalette.of(BuildContext context) {
    final t = Theme.of(context).extension<LorescapeTokens>();
    return ReadingPalette(
      readBg: t?.readBg ?? const Color(0xFFEFE2CB),
      readInk: t?.readInk ?? const Color(0xFF2A2013),
      readDim: t?.readDim ?? const Color(0xFF6A5A3E),
      readLine: t?.readLine ?? const Color(0xFFDDCBA8),
      readCap: t?.readCap ?? const Color(0xFF97442A),
      clay: t?.clay ?? const Color(0xFFBC5E3E),
      inkBg: t?.inkBg ?? const Color(0xFF1B1611),
      inkBg2: t?.inkBg2 ?? const Color(0xFF251E17),
      onDark: t?.onDark ?? const Color(0xFFF7F1E6),
      onDark2: t?.onDark2 ?? const Color(0xFFC3B7A4),
      rLg: t?.rLg ?? 16,
    );
  }
}
