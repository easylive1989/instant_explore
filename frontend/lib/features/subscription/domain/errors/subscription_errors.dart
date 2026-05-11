import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';

/// Thrown when the user requests a [SubscriptionPeriod] that the current
/// RevenueCat offering does not contain a package for.
class SubscriptionPlanNotAvailableException implements Exception {
  final SubscriptionPeriod period;

  SubscriptionPlanNotAvailableException(this.period);

  @override
  String toString() => 'SubscriptionPlanNotAvailableException: ${period.name}';
}
