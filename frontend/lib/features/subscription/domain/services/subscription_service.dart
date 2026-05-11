import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';

/// 訂閱服務介面
///
/// 抽象化訂閱管理操作，方便測試時替換實作
abstract class SubscriptionService {
  /// 初始化 SDK 並設定 API key
  Future<void> initialize({required String apiKey});

  /// 綁定使用者身份（登入後呼叫）
  Future<void> logIn(String userId);

  /// 解除使用者身份（登出時呼叫）
  Future<void> logOut();

  /// 訂閱狀態變化串流
  Stream<SubscriptionStatus> get statusStream;

  /// 取得當前訂閱狀態
  Future<SubscriptionStatus> getStatus();

  /// 購買指定週期的訂閱方案。
  ///
  /// 回傳購買後的訂閱狀態。使用者取消時回傳 `null`。
  /// 若當前 offering 沒有對應 [period] 的 package，丟出
  /// [SubscriptionPlanNotAvailableException]。
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period);

  /// 恢復購買
  Future<SubscriptionStatus> restorePurchases();

  /// 取得目前可購買的方案列表，固定回傳順序：weekly → monthly → yearly。
  ///
  /// 若沒有任何可用 offerings 則回傳空 list；UI 應顯示載入錯誤。
  Future<List<SubscriptionPlan>> getAvailablePlans();
}
