import 'package:context_app/app.dart';
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lorescapeThemeFor', () {
    test('builds a light theme reflecting the appearance state', () {
      const state = AppearanceState(
        accent: BrandAccent.sage,
        reading: ReadingSurface.paper,
        headlineFont: HeadlineFont.serif,
      );
      final theme = lorescapeThemeFor(state);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF5F7148));
      expect(theme.extension<LorescapeTokens>(), isNotNull);
    });
  });
}
