import 'package:context_app/features/settings/presentation/controllers/theme_mode_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeNotifier', () {
    test('always exposes ThemeMode.dark even with saved light value',
        () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Allow async _loadFromPrefs to complete.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Trigger build.
      container.read(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('exposed state stays ThemeMode.dark after setThemeMode(light)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
