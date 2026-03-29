import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/subscription/data/revenuecat_subscription_service.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// 訂閱服務 Provider
///
/// 提供 SubscriptionService 實例
/// 測試時可 override 為 FakeSubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = RevenueCatSubscriptionService();
  // 註冊 listener 並發射初始狀態
  service.initialize(apiKey: '');
  ref.onDispose(service.dispose);
  return service;
});

/// 訂閱狀態 Provider
///
/// 各模組 watch 這個 provider 來判斷訂閱狀態
/// 使用 StreamProvider 即時反映訂閱狀態變化
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.statusStream;
});

/// 便利 Provider：是否為 Premium 使用者
///
/// 在 StreamProvider 載入中或錯誤時預設為 false
final isPremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.valueOrNull?.isPremium ?? false;
});
