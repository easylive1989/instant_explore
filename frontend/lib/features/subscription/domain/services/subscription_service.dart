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

  /// 購買訂閱
  ///
  /// 回傳購買後的訂閱狀態
  /// 使用者取消時回傳 null
  Future<SubscriptionStatus?> purchase();

  /// 恢復購買
  Future<SubscriptionStatus> restorePurchases();
}
