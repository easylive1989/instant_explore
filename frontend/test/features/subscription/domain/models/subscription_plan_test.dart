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

    test('two plans with the same fields are equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('plans differing on packageIdentifier are not equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: 'something_else',
      );

      expect(a, isNot(equals(b)));
    });

    test('plans differing on isBestValue are not equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$900',
        period: SubscriptionPeriod.yearly,
        packageIdentifier: r'$rc_annual',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$900',
        period: SubscriptionPeriod.yearly,
        packageIdentifier: r'$rc_annual',
        isBestValue: true,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
