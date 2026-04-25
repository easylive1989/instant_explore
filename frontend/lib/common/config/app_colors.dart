import 'package:flutter/material.dart';

/// Midnight Kyoto color tokens.
///
/// Names follow Material 3 conventions where possible. Legacy aliases
/// (`surfaceDarkPlayer`, `surfaceDarkConfig`, `surfaceDarkCard`,
/// `success`, `amber`, `errorBg`) are kept for backwards-compat with
/// existing screens; they will be replaced in S3.
class AppColors {
  AppColors._();

  // --- Brand primary (electric blue) ---
  static const Color primary = Color(0xFF137FEC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0x33137FEC); // primary @ 20%
  static const Color onPrimaryContainer = Color(0xFFA8C8FF);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color primaryFixedDim = Color(0xFFA8C8FF);
  static const Color onPrimaryFixed = Color(0xFF001B3C);
  static const Color onPrimaryFixedVariant = Color(0xFF004689);
  static const Color inversePrimary = Color(0xFF005EB4);
  static const Color surfaceTint = Color(0xFF137FEC);

  // --- Secondary (soft blue) ---
  static const Color secondary = Color(0xFFADC8F7);
  static const Color onSecondary = Color(0xFF123158);
  static const Color secondaryContainer = Color(0xFF2C4770);
  static const Color onSecondaryContainer = Color(0xFF9BB6E5);
  static const Color secondaryFixed = Color(0xFFD5E3FF);
  static const Color secondaryFixedDim = Color(0xFFADC8F7);
  static const Color onSecondaryFixed = Color(0xFF001B3C);
  static const Color onSecondaryFixedVariant = Color(0xFF2C4770);

  // --- Tertiary (warm orange) ---
  static const Color tertiary = Color(0xFFFFB68C);
  static const Color onTertiary = Color(0xFF532200);
  static const Color tertiaryContainer = Color(0xFFE47019);
  static const Color onTertiaryContainer = Color(0xFF481D00);
  static const Color tertiaryFixed = Color(0xFFFFDBC9);
  static const Color tertiaryFixedDim = Color(0xFFFFB68C);
  static const Color onTertiaryFixed = Color(0xFF321200);
  static const Color onTertiaryFixedVariant = Color(0xFF753400);

  // --- Surface ladder (dark to light navy-grey) ---
  static const Color backgroundDark = Color(0xFF101922);
  static const Color surfaceDim = Color(0xFF0D141B);
  static const Color surfaceContainerLowest = Color(0xFF0B1117);
  static const Color surfaceContainerLow = Color(0xFF151E27);
  static const Color surfaceContainer = Color(0xFF1C2630);
  static const Color surfaceContainerHigh = Color(0xFF27313C);
  static const Color surfaceContainerHighest = Color(0xFF323C48);
  static const Color surfaceBright = Color(0xFF222D39);

  /// Glass card primary fill (white at 8% opacity).
  static const Color surfaceVariant = Color(0x14FFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFC1C6D5);
  static const Color inverseSurface = Color(0xFFE0E2EC);
  static const Color inverseOnSurface = Color(0xFF2D3038);
  static const Color onBackground = Color(0xFFFFFFFF);

  // --- Outline (ghost border) ---
  static const Color outline = Color(0xFF8B919F);

  /// Ghost border (white at 10% opacity).
  static const Color outlineVariant = Color(0x1AFFFFFF);

  // --- Error ---
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // --- Convenience aliases ---
  /// Same as [outlineVariant]; kept under the old name for legacy callers.
  static const Color glassBorder = outlineVariant;
  static const Color white10 = outlineVariant;
  static const Color white20 = Color(0x33FFFFFF);
  static const Color black20 = Color(0x33000000);

  // --- Legacy (S3 will remove these) ---
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDark = surfaceContainer;
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkPlayer = Color(0xFF182430);
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkConfig = Color(0xFF192633);
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkCard = Color(0xFF1C2732);
  @Deprecated('Use a tertiary or new token; will be removed in S3.')
  static const Color success = Color(0xFF10B981);
  @Deprecated('Use a tertiary or new token; will be removed in S3.')
  static const Color amber = Color(0xFFF59E0B);
  @Deprecated('Use errorContainer or your own opacity; will be removed in S3.')
  static const Color errorBg = Color(0x1AF44336);

  // --- Legacy text aliases ---
  @Deprecated('Use onSurface (dark theme is now mandatory).')
  static const Color textPrimaryLight = Color(0xFF0F172A);
  @Deprecated('Use onSurfaceVariant (dark theme is now mandatory).')
  static const Color textSecondaryLight = Color(0xFF64748B);
  @Deprecated('Use onSurface; will be removed in S3.')
  static const Color textPrimaryDark = onSurface;
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textTertiaryDark = Colors.white60;
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textQuaternaryDark = Colors.white54;

  @Deprecated('Light theme retired; use backgroundDark.')
  static const Color backgroundLight = Color(0xFFF6F7F8);
}
