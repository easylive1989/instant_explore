import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';

/// Resolved colours for the Field Journal narration reader.
///
/// The reader uses the warm "reading surface" for its body and dark chrome for
/// the floating audio bar. Colours are a projection of [LorescapeTokens] via
/// [BuildContext.tokens], which supplies [LorescapeTokens.fallback] when the
/// extension is absent (e.g. widget tests); the accent follows the active brand
/// accent via `tokens.clay`.
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
    final t = context.tokens;
    return ReadingPalette(
      readBg: t.readBg,
      readInk: t.readInk,
      readDim: t.readDim,
      readLine: t.readLine,
      readCap: t.readCap,
      clay: t.clay,
      inkBg: t.inkBg,
      inkBg2: t.inkBg2,
      onDark: t.onDark,
      onDark2: t.onDark2,
      rLg: t.rLg,
    );
  }
}
