import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCurrentTripIdKey = 'current_trip_id';

/// 管理使用者設定的「當前旅程」id，並持久化到 SharedPreferences。
///
/// 狀態為 `null` 代表目前沒有進行中的旅程，新建立的條目會進到「未分類」。
class CurrentTripIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  /// 將當前旅程設為 [tripId]。傳 `null` 代表結束當前旅程。
  Future<void> setCurrentTripId(String? tripId) async {
    state = tripId;
    final prefs = await SharedPreferences.getInstance();
    if (tripId == null) {
      await prefs.remove(_kCurrentTripIdKey);
    } else {
      await prefs.setString(_kCurrentTripIdKey, tripId);
    }
  }

  /// 清除當前旅程（等同 `setCurrentTripId(null)`）。
  Future<void> clear() => setCurrentTripId(null);

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCurrentTripIdKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }
}
