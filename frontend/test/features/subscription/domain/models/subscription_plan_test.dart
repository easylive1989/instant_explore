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

    test('freeTrialDays defaults to null (no trial)', () {
      const plan = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );

      expect(plan.freeTrialDays, isNull);
    });

    test('freeTrialDays is part of equality', () {
      const base = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );
      const withTrial = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
        freeTrialDays: 7,
      );

      expect(withTrial == base, isFalse);
      expect(withTrial.freeTrialDays, 7);
    });
  });
}
