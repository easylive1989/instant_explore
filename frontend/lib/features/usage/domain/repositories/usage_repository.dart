import 'package:context_app/features/usage/domain/models/usage_status.dart';

/// 使用額度管理 Repository 介面
abstract class UsageRepository {
  /// 取得當前使用狀態（若跨日則自動重置）
  Future<UsageStatus> getUsageStatus();

  /// 消耗一次使用額度
  Future<void> consumeUsage();

  /// 觀看廣告後新增一次額外額度
  Future<void> addBonusFromAd();
}
