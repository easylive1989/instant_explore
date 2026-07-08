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

  /// Length of the introductory free trial in days, or `null` when the plan
  /// has no free trial. Normalized to days across stores (iOS reports the
  /// trial as e.g. 1 week, Google Play as 7 days — both surface as 7 here).
  final int? freeTrialDays;

  const SubscriptionPlan({
    required this.priceString,
    required this.period,
    required this.packageIdentifier,
    this.isBestValue = false,
    this.freeTrialDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          priceString == other.priceString &&
          period == other.period &&
          packageIdentifier == other.packageIdentifier &&
          isBestValue == other.isBestValue &&
          freeTrialDays == other.freeTrialDays;

  @override
  int get hashCode => Object.hash(
    priceString,
    period,
    packageIdentifier,
    isBestValue,
    freeTrialDays,
  );
}

/// 訂閱方案週期
enum SubscriptionPeriod { weekly, monthly, yearly }
