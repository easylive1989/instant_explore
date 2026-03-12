import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionStatus', () {
    test('defaults to not premium', () {
      const status = SubscriptionStatus();
      expect(status.isPremium, isFalse);
      expect(status.expirationDate, isNull);
    });

    test('can be created as premium with expiration', () {
      final expiration = DateTime(2026, 4, 12);
      final status = SubscriptionStatus(
        isPremium: true,
        expirationDate: expiration,
      );
      expect(status.isPremium, isTrue);
      expect(status.expirationDate, expiration);
    });

    test('free is a non-premium instance', () {
      expect(SubscriptionStatus.free.isPremium, isFalse);
      expect(SubscriptionStatus.free.expirationDate, isNull);
    });
  });
}
