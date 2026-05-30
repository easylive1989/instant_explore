import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the warm "Field Journal" light theme from resolved [tokens].
///
/// Headlines use Noto Serif TC (or Noto Sans TC when [headlineFont] is
/// [HeadlineFont.sans]); body text uses Noto Sans TC. The returned
/// [ThemeData] registers [LorescapeTokens] so widgets can read warm tokens
/// not covered by the standard [ColorScheme].
ThemeData buildLorescapeTheme({
  required LorescapeTokens tokens,
  required HeadlineFont headlineFont,
}) {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: tokens.clay,
        brightness: Brightness.light,
      ).copyWith(
        primary: tokens.clay,
        onPrimary: const Color(0xFFFBF1E9),
        primaryContainer: tokens.clayTint,
        onPrimaryContainer: tokens.clayDeep,
        secondary: tokens.ink2,
        onSecondary: tokens.paper,
        secondaryContainer: tokens.paperSunk,
        onSecondaryContainer: tokens.ink,
        tertiary: tokens.clayDeep,
        onTertiary: const Color(0xFFFBF1E9),
        tertiaryContainer: tokens.clayTint,
        onTertiaryContainer: tokens.clayDeep,
        surface: tokens.paper,
        onSurface: tokens.ink,
        onSurfaceVariant: tokens.ink2,
        surfaceContainerLow: tokens.paperRaised,
        surfaceContainerHighest: tokens.paperSunk,
        outline: tokens.lineStrong,
        outlineVariant: tokens.line,
      );

  TextStyle headline(double size, {FontWeight weight = FontWeight.w700}) {
    final base = headlineFont == HeadlineFont.sans
        ? GoogleFonts.notoSansTc
        : GoogleFonts.notoSerifTc;
    return base(fontSize: size, fontWeight: weight, color: tokens.ink);
  }

  final textTheme = TextTheme(
    displayLarge: headline(34).copyWith(letterSpacing: 1, height: 1.1),
    displayMedium: headline(28),
    displaySmall: headline(24),
    headlineMedium: headline(20),
    titleLarge: headline(18).copyWith(letterSpacing: 0.5),
    titleMedium: GoogleFonts.notoSansTc(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: tokens.ink,
    ),
    bodyLarge: GoogleFonts.notoSansTc(
      fontSize: 16,
      height: 1.5,
      color: tokens.ink,
    ),
    bodyMedium: GoogleFonts.notoSansTc(
      fontSize: 14,
      height: 1.5,
      color: tokens.ink2,
    ),
    bodySmall: GoogleFonts.notoSansTc(fontSize: 13, color: tokens.ink3),
    labelLarge: GoogleFonts.notoSansTc(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: tokens.ink,
    ),
    labelSmall: GoogleFonts.notoSansTc(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: tokens.ink3,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.paper,
    textTheme: textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.paper,
      foregroundColor: tokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: headline(18).copyWith(letterSpacing: 0.5),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.paperRaised,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.rLg),
        side: BorderSide(color: tokens.line),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.clay,
        foregroundColor: const Color(0xFFFBF1E9),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rLg),
        ),
        textStyle: GoogleFonts.notoSansTc(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink,
        backgroundColor: tokens.paperRaised,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: tokens.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rLg),
        ),
        textStyle: GoogleFonts.notoSansTc(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: tokens.clay),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.clay,
      foregroundColor: const Color(0xFFFBF1E9),
      elevation: 0,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.paperRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.notoSansTc(color: tokens.ink3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.clay, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.paperSunk,
      side: BorderSide(color: tokens.line),
      labelStyle: GoogleFonts.notoSansTc(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
    ),
    dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.rXl),
      ),
      titleTextStyle: headline(21),
      contentTextStyle: GoogleFonts.notoSansTc(
        fontSize: 15,
        height: 1.6,
        color: tokens.ink2,
      ),
    ),
  );
}
