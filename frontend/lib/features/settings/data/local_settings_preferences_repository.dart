import 'package:context_app/features/settings/domain/repositories/settings_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SettingsPreferencesRepository] backed by [SharedPreferences].
class LocalSettingsPreferencesRepository
    implements SettingsPreferencesRepository {
  static const _kThemeModeKey = 'theme_mode';
  static const _dark = 'dark';
  static const _light = 'light';
  static const _system = 'system';

  @override
  Future<ThemeMode?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_kThemeModeKey));
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _encode(mode));
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => _dark,
    ThemeMode.light => _light,
    ThemeMode.system => _system,
  };

  static ThemeMode? _decode(String? raw) => switch (raw) {
    _dark => ThemeMode.dark,
    _light => ThemeMode.light,
    _system => ThemeMode.system,
    _ => null,
  };
}
