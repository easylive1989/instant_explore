/// 訂閱狀態
///
/// 表示使用者的訂閱狀態，isPremium 為 true 時享有：
/// - 無廣告
/// - 無限使用次數
/// - 路線規劃功能
class SubscriptionStatus {
  final bool isPremium;
  final DateTime? expirationDate;

  const SubscriptionStatus({this.isPremium = false, this.expirationDate});

  /// 免費使用者的預設狀態
  static const free = SubscriptionStatus();
}
