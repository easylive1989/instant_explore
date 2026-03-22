import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/usage/data/local_usage_repository.dart';
import 'package:context_app/features/usage/data/unlimited_usage_repository.dart';
import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) {
    return UnlimitedUsageRepository();
  }
  return LocalUsageRepository();
});

final usageStatusProvider = FutureProvider<UsageStatus>((ref) async {
  return ref.watch(usageRepositoryProvider).getUsageStatus();
});
