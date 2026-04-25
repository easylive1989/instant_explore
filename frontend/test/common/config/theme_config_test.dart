import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/common/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeConfig.darkTheme', () {
    final theme = ThemeConfig.darkTheme;

    test('uses Midnight Kyoto primary as colorScheme.primary', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('uses backgroundDark as scaffoldBackgroundColor', () {
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('uses backgroundDark as colorScheme.surface', () {
      expect(theme.colorScheme.surface, AppColors.backgroundDark);
    });

    test('cardTheme has no border (no-line rule)', () {
      final shape = theme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final rounded = shape! as RoundedRectangleBorder;
      expect(rounded.side.width, 0.0);
    });

    test('elevatedButtonTheme uses StadiumBorder (pill shape)', () {
      final shape = theme.elevatedButtonTheme.style?.shape?.resolve({});
      expect(shape, isA<StadiumBorder>());
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('brightness is dark', () {
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('ThemeConfig.lightTheme', () {
    test('is a placeholder that returns darkTheme', () {
      // Light theme is intentionally not implemented yet; getter exists
      // for architectural symmetry per S1 spec.
      expect(
        ThemeConfig.lightTheme.colorScheme.primary,
        ThemeConfig.darkTheme.colorScheme.primary,
      );
    });
  });
}
