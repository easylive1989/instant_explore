import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsageStatus', () {
    test('未使用時 canUseNarration 為 true', () {
      const status = UsageStatus(usedToday: 0, dailyFreeLimit: 1);

      expect(status.canUseNarration, isTrue);
      expect(status.remaining, 1);
      expect(status.totalAvailable, 1);
    });

    test('已用完免費額度時 canUseNarration 為 false', () {
      const status = UsageStatus(usedToday: 1, dailyFreeLimit: 1);

      expect(status.canUseNarration, isFalse);
      expect(status.remaining, 0);
    });

    test('usedToday 超過 totalAvailable 時 remaining 不會變負數', () {
      const status = UsageStatus(usedToday: 5, dailyFreeLimit: 1);

      expect(status.remaining, 0);
      expect(status.canUseNarration, isFalse);
    });

    test('預設 dailyFreeLimit 為 1', () {
      const status = UsageStatus(usedToday: 0);

      expect(status.dailyFreeLimit, 1);
      expect(status.totalAvailable, 1);
    });
  });
}
