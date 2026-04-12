import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// 管理應用的 ThemeMode，並持久化到 SharedPreferences。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _dark = 'dark';
  static const _light = 'light';
  static const _system = 'system';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  /// 切換至指定的 ThemeMode 並儲存偏好設定。
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _encode(mode));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved != null) {
      state = _decode(saved);
    }
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => _dark,
    ThemeMode.light => _light,
    ThemeMode.system => _system,
  };

  static ThemeMode _decode(String value) => switch (value) {
    _dark => ThemeMode.dark,
    _light => ThemeMode.light,
    _system => ThemeMode.system,
    _ => ThemeMode.dark,
  };
}
