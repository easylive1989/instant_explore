import 'package:context_app/features/subscription/domain/models/pass_type.dart';
import 'package:context_app/features/subscription/domain/models/user_entitlement.dart';

/// 權益倉儲介面
///
/// 定義用戶權益檢查和管理的抽象介面
/// 實作類別負責整合 RevenueCat (付費狀態) 和 Supabase (免費次數)
abstract class EntitlementRepository {
  /// 獲取當前用戶權益狀態
  ///
  /// 檢查用戶是否有有效通行證，以及今日剩餘免費次數
  Future<UserEntitlement> getEntitlement();

  /// 消耗一次免費使用
  ///
  /// 當免費用戶使用 AI 導覽時呼叫
  /// 拋出例外如果沒有剩餘次數
  Future<void> consumeFreeUsage();

  /// 驗證並啟用購買的通行證
  ///
  /// [passType] 購買的通行證類型
  /// 返回更新後的權益狀態
  Future<UserEntitlement> activatePass(PassType passType);

  /// 檢查並清除過期的通行證
  ///
  /// 應在 app 啟動時呼叫
  Future<void> checkAndExpire();

  /// 監聽權益狀態變化
  Stream<UserEntitlement> get entitlementStream;
}
