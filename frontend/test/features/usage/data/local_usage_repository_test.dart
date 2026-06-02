import 'package:context_app/features/usage/data/local_usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalUsageRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LocalUsageRepository();
  });

  group('getUsageStatus', () {
    test('初始狀態應為 usedToday=0，可使用', () async {
      final status = await repository.getUsageStatus();

      expect(status.usedToday, 0);
      expect(status.dailyFreeLimit, 1);
      expect(status.canUseNarration, isTrue);
    });

    test('跨日後應自動重置使用量', () async {
      // 模擬昨天的資料
      SharedPreferences.setMockInitialValues({
        'last_usage_date': '2020-01-01',
        'usage_count': 5,
      });
      repository = LocalUsageRepository();

      final status = await repository.getUsageStatus();

      expect(status.usedToday, 0);
      expect(status.canUseNarration, isTrue);
    });
  });

  group('consumeUsage', () {
    test('消耗一次額度後 usedToday 增加 1', () async {
      await repository.consumeUsage();
      final status = await repository.getUsageStatus();

      expect(status.usedToday, 1);
    });

    test('多次消耗後 usedToday 正確累加', () async {
      await repository.consumeUsage();
      await repository.consumeUsage();
      final status = await repository.getUsageStatus();

      expect(status.usedToday, 2);
    });

    test('額度用完後 canUseNarration 回傳 false', () async {
      await repository.consumeUsage();
      final status = await repository.getUsageStatus();

      expect(status.canUseNarration, isFalse);
    });
  });

  group('跨日重置', () {
    test('consumeUsage 在跨日後應先重置再消耗', () async {
      SharedPreferences.setMockInitialValues({
        'last_usage_date': '2020-01-01',
        'usage_count': 5,
      });
      repository = LocalUsageRepository();

      await repository.consumeUsage();
      final status = await repository.getUsageStatus();

      expect(status.usedToday, 1);
    });
  });
}
