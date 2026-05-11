// frontend/lib/features/subscription/domain/models/subscription_plan.dart

/// 可購買的訂閱方案資訊
///
/// [priceString] 為商店回傳的已本地化價格字串（例如 `NT$90` 或 `$2.99`），
/// 不要自己組字串或做貨幣換算。
class SubscriptionPlan {
  final String priceString;
  final SubscriptionPeriod period;
  final String packageIdentifier;
  final bool isBestValue;

  const SubscriptionPlan({
    required this.priceString,
    required this.period,
    required this.packageIdentifier,
    this.isBestValue = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          priceString == other.priceString &&
          period == other.period &&
          packageIdentifier == other.packageIdentifier &&
          isBestValue == other.isBestValue;

  @override
  int get hashCode =>
      Object.hash(priceString, period, packageIdentifier, isBestValue);
}

/// 訂閱方案週期
enum SubscriptionPeriod { weekly, monthly, yearly }
