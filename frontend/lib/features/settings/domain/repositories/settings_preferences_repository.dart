import 'package:flutter/material.dart';

/// Persists user-tweakable settings (currently just theme mode).
///
/// Settings that are derived live from the platform — like locale via
/// `easy_localization` — don't go through this repository.
abstract class SettingsPreferencesRepository {
  /// Returns the previously saved [ThemeMode], or `null` if the user
  /// has never made a choice.
  Future<ThemeMode?> loadThemeMode();

  /// Persists the user's [ThemeMode] choice.
  Future<void> saveThemeMode(ThemeMode mode);
}
