import 'package:context_app/features/subscription/data/revenuecat_subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('RevenueCatSubscriptionService.freeTrialDays', () {
    test('no trial info returns null', () {
      expect(RevenueCatSubscriptionService.freeTrialDays(), isNull);
    });

    test('iOS 1-week free introductory offer normalizes to 7 days', () {
      const intro = IntroductoryPrice(0, 'Free', 'P1W', 1, PeriodUnit.week, 1);

      expect(
        RevenueCatSubscriptionService.freeTrialDays(introductoryPrice: intro),
        7,
      );
    });

    test('iOS 3-day free introductory offer returns 3 days', () {
      const intro = IntroductoryPrice(0, 'Free', 'P3D', 1, PeriodUnit.day, 3);

      expect(
        RevenueCatSubscriptionService.freeTrialDays(introductoryPrice: intro),
        3,
      );
    });

    test('iOS paid introductory offer (price > 0) is not a free trial', () {
      const intro = IntroductoryPrice(
        1.99,
        'NT\$60',
        'P1M',
        1,
        PeriodUnit.month,
        1,
      );

      expect(
        RevenueCatSubscriptionService.freeTrialDays(introductoryPrice: intro),
        isNull,
      );
    });

    test('Android 7-day free phase returns 7 days', () {
      const period = Period(PeriodUnit.day, 7, 'P7D');

      expect(
        RevenueCatSubscriptionService.freeTrialDays(
          androidFreeTrialPeriod: period,
        ),
        7,
      );
    });

    test('Android 1-week free phase normalizes to 7 days', () {
      const period = Period(PeriodUnit.week, 1, 'P1W');

      expect(
        RevenueCatSubscriptionService.freeTrialDays(
          androidFreeTrialPeriod: period,
        ),
        7,
      );
    });
  });
}
