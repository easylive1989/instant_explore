import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/app/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLorescapeTheme', () {
    final tokens = LorescapeTokens.forAppearance(
      accent: BrandAccent.terracotta,
      reading: ReadingSurface.paper,
    );

    test('is a light theme with clay primary and paper scaffold', () {
      final theme = buildLorescapeTheme(
        tokens: tokens,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, tokens.clay);
      expect(theme.scaffoldBackgroundColor, tokens.paper);
    });

    test('registers the LorescapeTokens extension', () {
      final theme = buildLorescapeTheme(
        tokens: tokens,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.extension<LorescapeTokens>(), isNotNull);
      expect(theme.extension<LorescapeTokens>()!.clay, tokens.clay);
    });

    test('amber tokens flow into the colour scheme primary', () {
      final amber = LorescapeTokens.forAppearance(
        accent: BrandAccent.amber,
        reading: ReadingSurface.paper,
      );
      final theme = buildLorescapeTheme(
        tokens: amber,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.colorScheme.primary, const Color(0xFFB7842B));
    });

    test('secondary and tertiary are warm, not seed-derived cool tones', () {
      final sage = LorescapeTokens.forAppearance(
        accent: BrandAccent.sage,
        reading: ReadingSurface.paper,
      );
      final theme = buildLorescapeTheme(
        tokens: sage,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.colorScheme.tertiary, sage.clayDeep);
      expect(theme.colorScheme.secondary, sage.ink2);
    });
  });
}
