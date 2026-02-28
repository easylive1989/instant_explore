import 'package:context_app/features/ads/data/google_rewarded_ad_service.dart';
import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final service = GoogleRewardedAdService();
  ref.onDispose(() => service.dispose());
  return service;
});
