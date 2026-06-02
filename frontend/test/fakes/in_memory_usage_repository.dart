import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';

/// In-memory [UsageRepository] used by widget tests.
class InMemoryUsageRepository implements UsageRepository {
  int _usedToday;
  final int _dailyFreeLimit;

  InMemoryUsageRepository({
    int usedToday = 0,
    int dailyFreeLimit = 1,
  }) : _usedToday = usedToday,
       _dailyFreeLimit = dailyFreeLimit;

  @override
  Future<UsageStatus> getUsageStatus() async {
    return UsageStatus(
      usedToday: _usedToday,
      dailyFreeLimit: _dailyFreeLimit,
    );
  }

  @override
  Future<void> consumeUsage() async {
    _usedToday += 1;
  }
}
