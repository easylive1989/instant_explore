import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// Manages the app's [ThemeMode] and persists it to SharedPreferences.
///
/// The app is currently locked to [ThemeMode.dark] (Midnight Kyoto).
/// This notifier still reads/writes the SharedPreferences key so the
/// architecture is intact for future re-introduction of a light theme:
///
/// 1. Implement [ThemeConfig.lightTheme] with a real light variant.
/// 2. In `app.dart`, replace `themeMode: ThemeMode.dark` with
///    `themeMode: ref.watch(themeModeProvider)`.
/// 3. Restore the toggle UI in settings_screen.
/// 4. Remove the override in [build] so the saved value is honoured.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _dark = 'dark';
  static const _light = 'light';
  static const _system = 'system';

  @override
  ThemeMode build() {
    // Still load the persisted value so future light-theme work picks
    // it up automatically — but always expose dark for now.
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  /// Persists the user's preference. The exposed [state] stays
  /// [ThemeMode.dark] until the app's light theme is re-enabled.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _encode(mode));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Read but ignore — kept so the value survives across upgrades and
    // is available the moment the override is removed.
    prefs.getString(_kThemeModeKey);
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => _dark,
    ThemeMode.light => _light,
    ThemeMode.system => _system,
  };
}
