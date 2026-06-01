import 'package:flutter/material.dart';

/// Fixed colours for the editorial card reader (daily story detail).
///
/// The reader always uses the warm "paper" reading surface from the design
/// (`ls2.css`), independent of the app's appearance setting, so the article
/// reads like printed paper with a dark photo header. Values mirror the design
/// tokens: `--read-bg`, `--read-ink`, `--read-dim`, `--read-line`,
/// `--read-cap`, `--clay`, `--ink-bg`, `--on-dark`.
abstract final class CardReaderTheme {
  /// Paper background behind the article body.
  static const readBg = Color(0xFFF7F1E6);

  /// Primary body text colour.
  static const readInk = Color(0xFF221C14);

  /// Dimmed text (sub, quote attribution, footer).
  static const readDim = Color(0xFF5E5341);

  /// Hairline divider on paper.
  static const readLine = Color(0xFFE4DAC8);

  /// Editorial accent (drop cap, quote rule, eyebrow) — deep clay.
  static const readCap = Color(0xFF97442A);

  /// Brand clay accent.
  static const clay = Color(0xFFBC5E3E);

  /// Dark chrome behind the top bar.
  static const inkBg = Color(0xFF1B1611);

  /// Cream text/icon colour on dark surfaces.
  static const onDark = Color(0xFFF7F1E6);
}
