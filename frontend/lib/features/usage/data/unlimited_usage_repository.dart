import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';

/// 無限額度的 UsageRepository
///
/// Premium 用戶使用此實作，跳過所有額度限制
class UnlimitedUsageRepository implements UsageRepository {
  @override
  Future<UsageStatus> getUsageStatus() async {
    return const UsageStatus(usedToday: 0, dailyFreeLimit: 999999);
  }

  @override
  Future<void> consumeUsage() async {
    // Premium 用戶不消耗額度
  }

  @override
  Future<void> addBonusFromAd() async {
    // Premium 用戶不需要廣告獎勵
  }
}
