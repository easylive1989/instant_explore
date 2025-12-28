import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:context_app/features/subscription/data/entitlement_repository_impl.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';
import 'package:context_app/features/subscription/domain/models/user_entitlement.dart';
import 'package:context_app/features/subscription/domain/repositories/entitlement_repository.dart';

/// EntitlementRepository Provider
///
/// 提供權益倉儲（直接使用 Supabase.instance.client）
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepositoryImpl(Supabase.instance.client);
});

/// PurchaseRepository Provider
///
/// 提供購買倉儲（在 main.dart 中透過 ProviderScope.overrides 注入）
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  throw UnimplementedError(
    'purchaseRepositoryProvider must be overridden in ProviderScope',
  );
});

/// 用戶權益狀態 Provider
///
/// 提供當前用戶的權益狀態
/// 使用 FutureProvider 處理非同步載入
final userEntitlementProvider = FutureProvider<UserEntitlement>((ref) async {
  final repository = ref.watch(entitlementRepositoryProvider);
  return repository.getEntitlement();
});

/// 權益狀態串流 Provider
///
/// 監聽權益狀態變化
final entitlementStreamProvider = StreamProvider<UserEntitlement>((ref) {
  final repository = ref.watch(entitlementRepositoryProvider);
  return repository.entitlementStream;
});

/// 購買更新串流 Provider
///
/// 監聽購買狀態變化
final purchaseUpdateStreamProvider = StreamProvider<PurchaseUpdate>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.purchaseStream;
});

/// RevenueCat Offerings Provider
///
/// 取得 RevenueCat 的 Offerings
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.getOfferings();
});

/// 可購買的產品列表 Provider
///
/// 取得商店中可購買的產品
final availableProductsProvider = FutureProvider<List<StoreProduct>>((
  ref,
) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.getProducts();
});

/// 是否可以使用 AI 導覽 Provider
///
/// 快速檢查用戶是否可以使用 AI 導覽功能
final canUseNarrationProvider = FutureProvider<bool>((ref) async {
  final entitlement = await ref.watch(userEntitlementProvider.future);
  return entitlement.canUseNarration;
});

/// 剩餘免費次數 Provider
///
/// 快速取得今日剩餘免費次數
final remainingFreeUsageProvider = FutureProvider<int>((ref) async {
  final entitlement = await ref.watch(userEntitlementProvider.future);
  return entitlement.remainingFreeUsage;
});
