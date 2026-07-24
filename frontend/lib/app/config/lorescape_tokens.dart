import 'dart:ui' show lerpDouble;

import 'package:context_app/app/config/appearance_options.dart';
import 'package:flutter/material.dart';

/// Warm "Field Journal" design tokens, resolved for the active brand
/// accent and reading surface.
///
/// Read via `Theme.of(context).extension<LorescapeTokens>()!`. Values come
/// from the design handoff (`ls2.css`, `app.jsx`).
@immutable
class LorescapeTokens extends ThemeExtension<LorescapeTokens> {
  const LorescapeTokens({
    required this.paper,
    required this.paperRaised,
    required this.paperSunk,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.clay,
    required this.clayDeep,
    required this.claySoft,
    required this.clayTint,
    required this.inkBg,
    required this.inkBg2,
    required this.inkBg3,
    required this.onDark,
    required this.onDark2,
    required this.onDark3,
    required this.readBg,
    required this.readInk,
    required this.readDim,
    required this.readLine,
    required this.readCap,
    required this.rSm,
    required this.rMd,
    required this.rLg,
    required this.rXl,
    required this.rImg,
    required this.e1,
    required this.e2,
    required this.e3,
  });

  final Color paper;
  final Color paperRaised;
  final Color paperSunk;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color clay;
  final Color clayDeep;
  final Color claySoft;
  final Color clayTint;
  final Color inkBg;
  final Color inkBg2;
  final Color inkBg3;
  final Color onDark;
  final Color onDark2;
  final Color onDark3;
  final Color readBg;
  final Color readInk;
  final Color readDim;
  final Color readLine;
  final Color readCap;
  final double rSm;
  final double rMd;
  final double rLg;
  final double rXl;
  final double rImg;
  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;

  /// Canonical default token set (terracotta accent, paper reading surface).
  ///
  /// The single source of truth for the values widgets should fall back to
  /// when the [LorescapeTokens] theme extension is absent (e.g. a widget test
  /// that pumps without the full app theme). Read it via [BuildContext.tokens]
  /// rather than re-hardcoding literals at each call site.
  static const LorescapeTokens fallback = LorescapeTokens(
    paper: Color(0xFFF7F1E6),
    paperRaised: Color(0xFFFDFAF3),
    paperSunk: Color(0xFFECE3D3),
    line: Color(0xFFE4DAC8),
    lineStrong: Color(0xFFCDBFA6),
    ink: Color(0xFF221C14),
    ink2: Color(0xFF5E5341),
    ink3: Color(0xFF918471),
    clay: Color(0xFFBC5E3E),
    clayDeep: Color(0xFF97442A),
    claySoft: Color(0xFFF1DDCE),
    clayTint: Color(0xFFF7E8DD),
    inkBg: Color(0xFF1B1611),
    inkBg2: Color(0xFF251E17),
    inkBg3: Color(0xFF312820),
    onDark: Color(0xFFF7F1E6),
    onDark2: Color(0xFFC3B7A4),
    onDark3: Color(0xFF8C8170),
    readBg: Color(0xFFF7F1E6),
    readInk: Color(0xFF221C14),
    readDim: Color(0xFF5E5341),
    readLine: Color(0xFFE4DAC8),
    readCap: Color(0xFF97442A),
    rSm: 8,
    rMd: 12,
    rLg: 16,
    rXl: 22,
    rImg: 10,
    e1: [
      BoxShadow(
        color: Color.fromRGBO(40, 30, 18, 0.06),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    e2: [
      BoxShadow(
        color: Color.fromRGBO(40, 30, 18, 0.09),
        offset: Offset(0, 6),
        blurRadius: 18,
      ),
    ],
    e3: [
      BoxShadow(
        color: Color.fromRGBO(28, 20, 10, 0.20),
        offset: Offset(0, 18),
        blurRadius: 44,
      ),
    ],
  );

  /// Resolves the full token set for a given [accent] + [reading].
  factory LorescapeTokens.forAppearance({
    required BrandAccent accent,
    required ReadingSurface reading,
  }) {
    final (clay, clayDeep, claySoft, clayTint) = switch (accent) {
      BrandAccent.terracotta => (
        const Color(0xFFBC5E3E),
        const Color(0xFF97442A),
        const Color(0xFFF1DDCE),
        const Color(0xFFF7E8DD),
      ),
      BrandAccent.amber => (
        const Color(0xFFB7842B),
        const Color(0xFF8A5F18),
        const Color(0xFFF0E5C8),
        const Color(0xFFF6EED8),
      ),
      BrandAccent.sage => (
        const Color(0xFF5F7148),
        const Color(0xFF46542F),
        const Color(0xFFE3E8D3),
        const Color(0xFFEBEFE0),
      ),
    };
    final (readBg, readInk, readDim, readLine) = switch (reading) {
      ReadingSurface.paper => (
        const Color(0xFFF7F1E6),
        const Color(0xFF221C14),
        const Color(0xFF5E5341),
        const Color(0xFFE4DAC8),
      ),
      ReadingSurface.sepia => (
        const Color(0xFFEFE2CB),
        const Color(0xFF2A2013),
        const Color(0xFF6A5A3E),
        const Color(0xFFDDCBA8),
      ),
      ReadingSurface.night => (
        const Color(0xFF1B1611),
        const Color(0xFFE9E1D2),
        const Color(0xFF9A8E7B),
        const Color.fromRGBO(247, 241, 230, 0.14),
      ),
    };
    return LorescapeTokens(
      paper: const Color(0xFFF7F1E6),
      paperRaised: const Color(0xFFFDFAF3),
      paperSunk: const Color(0xFFECE3D3),
      line: const Color(0xFFE4DAC8),
      lineStrong: const Color(0xFFCDBFA6),
      ink: const Color(0xFF221C14),
      ink2: const Color(0xFF5E5341),
      ink3: const Color(0xFF918471),
      clay: clay,
      clayDeep: clayDeep,
      claySoft: claySoft,
      clayTint: clayTint,
      inkBg: const Color(0xFF1B1611),
      inkBg2: const Color(0xFF251E17),
      inkBg3: const Color(0xFF312820),
      onDark: const Color(0xFFF7F1E6),
      onDark2: const Color(0xFFC3B7A4),
      onDark3: const Color(0xFF8C8170),
      readBg: readBg,
      readInk: readInk,
      readDim: readDim,
      readLine: readLine,
      readCap: clayDeep,
      rSm: 8,
      rMd: 12,
      rLg: 16,
      rXl: 22,
      rImg: 10,
      e1: const [
        BoxShadow(
          color: Color.fromRGBO(40, 30, 18, 0.06),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      e2: const [
        BoxShadow(
          color: Color.fromRGBO(40, 30, 18, 0.09),
          offset: Offset(0, 6),
          blurRadius: 18,
        ),
      ],
      e3: const [
        BoxShadow(
          color: Color.fromRGBO(28, 20, 10, 0.20),
          offset: Offset(0, 18),
          blurRadius: 44,
        ),
      ],
    );
  }

  @override
  LorescapeTokens copyWith({
    Color? paper,
    Color? paperRaised,
    Color? paperSunk,
    Color? line,
    Color? lineStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? clay,
    Color? clayDeep,
    Color? claySoft,
    Color? clayTint,
    Color? inkBg,
    Color? inkBg2,
    Color? inkBg3,
    Color? onDark,
    Color? onDark2,
    Color? onDark3,
    Color? readBg,
    Color? readInk,
    Color? readDim,
    Color? readLine,
    Color? readCap,
    double? rSm,
    double? rMd,
    double? rLg,
    double? rXl,
    double? rImg,
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
  }) {
    return LorescapeTokens(
      paper: paper ?? this.paper,
      paperRaised: paperRaised ?? this.paperRaised,
      paperSunk: paperSunk ?? this.paperSunk,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      clay: clay ?? this.clay,
      clayDeep: clayDeep ?? this.clayDeep,
      claySoft: claySoft ?? this.claySoft,
      clayTint: clayTint ?? this.clayTint,
      inkBg: inkBg ?? this.inkBg,
      inkBg2: inkBg2 ?? this.inkBg2,
      inkBg3: inkBg3 ?? this.inkBg3,
      onDark: onDark ?? this.onDark,
      onDark2: onDark2 ?? this.onDark2,
      onDark3: onDark3 ?? this.onDark3,
      readBg: readBg ?? this.readBg,
      readInk: readInk ?? this.readInk,
      readDim: readDim ?? this.readDim,
      readLine: readLine ?? this.readLine,
      readCap: readCap ?? this.readCap,
      rSm: rSm ?? this.rSm,
      rMd: rMd ?? this.rMd,
      rLg: rLg ?? this.rLg,
      rXl: rXl ?? this.rXl,
      rImg: rImg ?? this.rImg,
      e1: e1 ?? this.e1,
      e2: e2 ?? this.e2,
      e3: e3 ?? this.e3,
    );
  }

  @override
  LorescapeTokens lerp(ThemeExtension<LorescapeTokens>? other, double t) {
    if (other is! LorescapeTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t)!;
    return LorescapeTokens(
      paper: c(paper, other.paper),
      paperRaised: c(paperRaised, other.paperRaised),
      paperSunk: c(paperSunk, other.paperSunk),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      clay: c(clay, other.clay),
      clayDeep: c(clayDeep, other.clayDeep),
      claySoft: c(claySoft, other.claySoft),
      clayTint: c(clayTint, other.clayTint),
      inkBg: c(inkBg, other.inkBg),
      inkBg2: c(inkBg2, other.inkBg2),
      inkBg3: c(inkBg3, other.inkBg3),
      onDark: c(onDark, other.onDark),
      onDark2: c(onDark2, other.onDark2),
      onDark3: c(onDark3, other.onDark3),
      readBg: c(readBg, other.readBg),
      readInk: c(readInk, other.readInk),
      readDim: c(readDim, other.readDim),
      readLine: c(readLine, other.readLine),
      readCap: c(readCap, other.readCap),
      rSm: d(rSm, other.rSm),
      rMd: d(rMd, other.rMd),
      rLg: d(rLg, other.rLg),
      rXl: d(rXl, other.rXl),
      rImg: d(rImg, other.rImg),
      e1: s(e1, other.e1),
      e2: s(e2, other.e2),
      e3: s(e3, other.e3),
    );
  }
}

/// Non-null access to the active [LorescapeTokens].
///
/// Returns the registered theme extension, or [LorescapeTokens.fallback] when
/// none is present. Prefer `context.tokens.paper` over
/// `Theme.of(context).extension<LorescapeTokens>()?.paper ?? <literal>` so the
/// fallback values live in exactly one place.
extension LorescapeTokensContext on BuildContext {
  LorescapeTokens get tokens =>
      Theme.of(this).extension<LorescapeTokens>() ?? LorescapeTokens.fallback;
}
