import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsageStatus', () {
    test('未使用時 canUseNarration 為 true', () {
      const status = UsageStatus(
        usedToday: 0,
        dailyFreeLimit: 1,
      );

      expect(status.canUseNarration, isTrue);
      expect(status.remaining, 1);
      expect(status.totalAvailable, 1);
    });

    test('已用完免費額度時 canUseNarration 為 false', () {
      const status = UsageStatus(
        usedToday: 1,
        dailyFreeLimit: 1,
      );

      expect(status.canUseNarration, isFalse);
      expect(status.remaining, 0);
    });

    test('usedToday 超過 totalAvailable 時 remaining 不會變負數', () {
      const status = UsageStatus(
        usedToday: 5,
        dailyFreeLimit: 1,
        bonusFromAds: 1,
      );

      expect(status.remaining, 0);
      expect(status.canUseNarration, isFalse);
    });

    test('有廣告獎勵時 totalAvailable 包含 bonusFromAds', () {
      const status = UsageStatus(
        usedToday: 1,
        dailyFreeLimit: 1,
        bonusFromAds: 2,
      );

      expect(status.totalAvailable, 3);
      expect(status.remaining, 2);
      expect(status.canUseNarration, isTrue);
    });

    test('免費額度用完但有廣告獎勵時仍可使用', () {
      const status = UsageStatus(
        usedToday: 1,
        dailyFreeLimit: 1,
        bonusFromAds: 1,
      );

      expect(status.canUseNarration, isTrue);
      expect(status.remaining, 1);
    });

    test('所有額度都用完時不可使用', () {
      const status = UsageStatus(
        usedToday: 3,
        dailyFreeLimit: 1,
        bonusFromAds: 2,
      );

      expect(status.canUseNarration, isFalse);
      expect(status.remaining, 0);
    });

    test('預設 dailyFreeLimit 為 1，bonusFromAds 為 0', () {
      const status = UsageStatus(usedToday: 0);

      expect(status.dailyFreeLimit, 1);
      expect(status.bonusFromAds, 0);
      expect(status.totalAvailable, 1);
    });
  });
}
