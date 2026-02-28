import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// 使用 SharedPreferences 追蹤每日使用量的 Repository 實作
class LocalUsageRepository implements UsageRepository {
  static const _keyLastUsageDate = 'last_usage_date';
  static const _keyUsageCount = 'usage_count';
  static const _keyBonusFromAds = 'bonus_from_ads';
  static const _dailyFreeLimit = 1;

  @override
  Future<UsageStatus> getUsageStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_keyLastUsageDate);

    if (lastDate != today) {
      await _resetForNewDay(prefs, today);
      return const UsageStatus(usedToday: 0, dailyFreeLimit: _dailyFreeLimit);
    }

    return UsageStatus(
      usedToday: prefs.getInt(_keyUsageCount) ?? 0,
      dailyFreeLimit: _dailyFreeLimit,
      bonusFromAds: prefs.getInt(_keyBonusFromAds) ?? 0,
    );
  }

  @override
  Future<void> consumeUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureTodayOrReset(prefs);
    final current = prefs.getInt(_keyUsageCount) ?? 0;
    await prefs.setInt(_keyUsageCount, current + 1);
  }

  @override
  Future<void> addBonusFromAd() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureTodayOrReset(prefs);
    final current = prefs.getInt(_keyBonusFromAds) ?? 0;
    await prefs.setInt(_keyBonusFromAds, current + 1);
  }

  Future<void> _ensureTodayOrReset(SharedPreferences prefs) async {
    final today = _todayString();
    final lastDate = prefs.getString(_keyLastUsageDate);
    if (lastDate != today) {
      await _resetForNewDay(prefs, today);
    }
  }

  Future<void> _resetForNewDay(SharedPreferences prefs, String today) async {
    await prefs.setString(_keyLastUsageDate, today);
    await prefs.setInt(_keyUsageCount, 0);
    await prefs.setInt(_keyBonusFromAds, 0);
  }

  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
