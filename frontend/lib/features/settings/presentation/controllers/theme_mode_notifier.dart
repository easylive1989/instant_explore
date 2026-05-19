import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the app's [ThemeMode] and persists it via
/// [SettingsPreferencesRepository].
///
/// The app is currently locked to [ThemeMode.dark] (Midnight Kyoto).
/// This notifier still reads/writes the persisted value so the
/// architecture is intact for future re-introduction of a light theme:
///
/// 1. Implement [ThemeConfig.lightTheme] with a real light variant.
/// 2. In `app.dart`, replace `themeMode: ThemeMode.dark` with
///    `themeMode: ref.watch(themeModeProvider)`.
/// 3. Restore the toggle UI in settings_screen.
/// 4. Remove the override in [build] so the saved value is honoured.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Still load the persisted value so future light-theme work picks
    // it up automatically — but always expose dark for now.
    _primePersistedValue();
    return ThemeMode.dark;
  }

  /// Persists the user's preference. The exposed [state] stays
  /// [ThemeMode.dark] until the app's light theme is re-enabled.
  Future<void> setThemeMode(ThemeMode mode) {
    return ref.read(settingsPreferencesRepositoryProvider).saveThemeMode(mode);
  }

  Future<void> _primePersistedValue() async {
    // Read but ignore — kept so the value survives across upgrades and
    // is available the moment the dark-mode override is removed.
    await ref.read(settingsPreferencesRepositoryProvider).loadThemeMode();
  }
}
