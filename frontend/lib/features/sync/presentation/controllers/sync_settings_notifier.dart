import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSyncEnabledKey = 'sync_enabled';

/// Manages the user's "sync to cloud" preference and persists it.
///
/// State is `true` when sync is on. Initialised eagerly to `false` and
/// updated asynchronously after loading from [SharedPreferences].
class SyncSettingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSyncEnabledKey, enabled);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_kSyncEnabledKey);
    if (stored != null && stored != state) {
      state = stored;
    }
  }
}
