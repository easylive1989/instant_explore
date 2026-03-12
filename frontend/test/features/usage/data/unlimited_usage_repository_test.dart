import 'package:context_app/features/usage/data/unlimited_usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnlimitedUsageRepository', () {
    late UnlimitedUsageRepository repo;

    setUp(() {
      repo = UnlimitedUsageRepository();
    });

    test('getUsageStatus always returns canUseNarration true', () async {
      final status = await repo.getUsageStatus();
      expect(status.canUseNarration, isTrue);
      expect(status.remaining, greaterThan(0));
    });

    test('consumeUsage does nothing — still unlimited', () async {
      await repo.consumeUsage();
      final status = await repo.getUsageStatus();
      expect(status.canUseNarration, isTrue);
    });
  });
}
