import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/subscription/domain/models/pass_type.dart';
import 'package:context_app/features/subscription/domain/models/user_entitlement.dart';
import 'package:context_app/features/subscription/domain/repositories/entitlement_repository.dart';

/// 權益倉儲實作
///
/// 整合 RevenueCat (付費狀態) 和 Supabase (每日免費次數)
/// - 付費狀態：從 RevenueCat CustomerInfo 取得
/// - 免費次數：從 Supabase daily_usage 表格取得
/// - daily limit：寫在程式中，屬於商業邏輯
class EntitlementRepositoryImpl implements EntitlementRepository {
  /// 每日免費使用上限（商業邏輯）
  static const int dailyFreeLimit = 3;

  static const String _entitlementId = 'premium_access';

  final SupabaseClient _supabaseClient;
  final _entitlementController = StreamController<UserEntitlement>.broadcast();

  EntitlementRepositoryImpl(this._supabaseClient);

  @override
  Stream<UserEntitlement> get entitlementStream =>
      _entitlementController.stream;

  /// 取得當前用戶 ID
  String? get _userId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<UserEntitlement> getEntitlement() async {
    try {
      // 1. 先從 RevenueCat 檢查付費狀態
      final customerInfo = await Purchases.getCustomerInfo();

      if (customerInfo.entitlements.active.containsKey(_entitlementId)) {
        final entitlement = customerInfo.entitlements.active[_entitlementId]!;
        final passType = PassType.fromProductId(entitlement.productIdentifier);
        final expiresAt = entitlement.expirationDate != null
            ? DateTime.parse(entitlement.expirationDate!)
            : null;

        debugPrint('✅ 用戶有付費權益: ${passType?.name}, 到期: $expiresAt');

        return UserEntitlement.premium(
          passType: passType ?? PassType.dayPass,
          expiresAt: expiresAt,
        );
      }

      // 2. 免費用戶：從 Supabase 取得今日使用量
      final usedCount = await _getDailyUsedCount();
      final remaining = dailyFreeLimit - usedCount;

      debugPrint('📊 免費用戶，已使用: $usedCount, 剩餘: $remaining');

      return UserEntitlement(
        hasActivePass: false,
        remainingFreeUsage: remaining.clamp(0, dailyFreeLimit),
        dailyFreeLimit: dailyFreeLimit,
      );
    } catch (e) {
      debugPrint('❌ 取得權益失敗: $e');
      // 發生錯誤時，給予一次機會（避免阻擋正常使用）
      return UserEntitlement.free(dailyFreeLimit: dailyFreeLimit);
    }
  }

  @override
  Future<void> consumeFreeUsage() async {
    final userId = _userId;
    if (userId == null) {
      throw EntitlementException('用戶未登入');
    }

    try {
      // 先檢查是否有付費權益
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.active.containsKey(_entitlementId)) {
        debugPrint('✅ 用戶有付費權益，不需消耗免費次數');
        return;
      }

      // 先檢查是否已達上限
      final currentUsed = await _getDailyUsedCount();
      if (currentUsed >= dailyFreeLimit) {
        throw EntitlementException('已達今日免費使用上限');
      }

      // 呼叫 Supabase RPC 消耗次數（返回新的使用量）
      await _supabaseClient.rpc(
        'consume_free_usage',
        params: {'p_user_id': userId},
      );

      // 通知狀態變更
      final entitlement = await getEntitlement();
      _entitlementController.add(entitlement);

      debugPrint('✅ 消耗免費次數成功');
    } catch (e) {
      if (e is EntitlementException) rethrow;
      debugPrint('❌ 消耗免費次數失敗: $e');
      throw EntitlementException('無法消耗免費次數: $e');
    }
  }

  @override
  Future<UserEntitlement> activatePass(PassType passType) async {
    // RevenueCat 已經處理了購買和權益啟用
    // 這裡只需要重新取得並廣播權益狀態
    debugPrint('🔄 重新載入權益狀態 (購買後)');

    final entitlement = await getEntitlement();
    _entitlementController.add(entitlement);

    return entitlement;
  }

  @override
  Future<void> checkAndExpire() async {
    // RevenueCat 自動處理過期，這裡只需重新取得狀態
    try {
      final entitlement = await getEntitlement();
      _entitlementController.add(entitlement);
    } catch (e) {
      debugPrint('⚠️ 檢查過期狀態失敗: $e');
    }
  }

  /// 從 Supabase 取得今日已使用次數
  Future<int> _getDailyUsedCount() async {
    final userId = _userId;
    if (userId == null) {
      return 0;
    }

    try {
      final response = await _supabaseClient.rpc(
        'get_daily_used_count',
        params: {'p_user_id': userId},
      );

      return response as int? ?? 0;
    } catch (e) {
      debugPrint('⚠️ 取得使用量失敗: $e');
      return 0;
    }
  }

  /// 釋放資源
  void dispose() {
    _entitlementController.close();
  }
}

/// 權益例外
class EntitlementException implements Exception {
  final String message;

  EntitlementException(this.message);

  @override
  String toString() => 'EntitlementException: $message';
}
