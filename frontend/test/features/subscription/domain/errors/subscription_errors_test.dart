import 'package:context_app/features/subscription/domain/errors/subscription_errors.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPlanNotAvailableException', () {
    test('toString mentions the missing period', () {
      final ex = SubscriptionPlanNotAvailableException(
        SubscriptionPeriod.weekly,
      );

      expect(ex.toString(), contains('weekly'));
    });

    test('is an Exception', () {
      final ex = SubscriptionPlanNotAvailableException(
        SubscriptionPeriod.yearly,
      );

      expect(ex, isA<Exception>());
    });
  });
}
