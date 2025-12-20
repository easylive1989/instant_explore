import 'package:flutter/material.dart';

/// UI-related constant values.
///
/// Contains spacing, sizing, duration, and other UI constants.
class UiConstants {
  UiConstants._();

  /// Spacing values
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2Xl = 48.0;

  /// Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  /// Icon sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  /// Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  /// Card elevation
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  /// Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Opacity values
  static const double opacityDisabled = 0.4;
  static const double opacityHover = 0.8;
  static const double opacityPressed = 0.6;

  /// Image aspect ratios
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioWide = 16.0 / 9.0;
  static const double aspectRatioUltraWide = 21.0 / 9.0;

  /// List item heights
  static const double listItemHeightSm = 48.0;
  static const double listItemHeightMd = 64.0;
  static const double listItemHeightLg = 80.0;

  /// App bar
  static const double appBarHeight = 56.0;
  static const double bottomNavBarHeight = 56.0;

  /// Breakpoints for responsive design
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  /// Max content width
  static const double maxContentWidth = 1200.0;

  /// Padding presets
  static const EdgeInsets paddingAllXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(spacingXl);

  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: spacingSm,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: spacingMd,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: spacingLg,
  );

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: spacingSm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: spacingMd,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: spacingLg,
  );
}
