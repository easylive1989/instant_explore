import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPlan', () {
    test('isBestValue defaults to false', () {
      const plan = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );

      expect(plan.isBestValue, isFalse);
    });
  });
}
