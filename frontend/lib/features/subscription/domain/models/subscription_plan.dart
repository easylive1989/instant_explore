// frontend/lib/features/subscription/domain/models/subscription_plan.dart

/// 可購買的訂閱方案資訊
///
/// [priceString] 為商店回傳的已本地化價格字串（例如 `NT$90` 或 `$2.99`），
/// 不要自己組字串或做貨幣換算。
class SubscriptionPlan {
  final String priceString;
  final SubscriptionPeriod period;

  const SubscriptionPlan({required this.priceString, required this.period});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          priceString == other.priceString &&
          period == other.period;

  @override
  int get hashCode => Object.hash(priceString, period);
}

/// 訂閱方案週期
enum SubscriptionPeriod { weekly, monthly, yearly }
