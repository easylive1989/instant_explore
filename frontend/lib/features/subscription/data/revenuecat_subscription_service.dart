import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// RevenueCat 實作的訂閱服務
class RevenueCatSubscriptionService implements SubscriptionService {
  static const _entitlementId = 'premium';

  final _controller = StreamController<SubscriptionStatus>.broadcast();

  /// 全域 SDK 初始化（在 main.dart 中呼叫一次）
  static Future<void> configureSDK({required String apiKey}) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  @override
  Future<void> initialize({required String apiKey}) async {
    // SDK 已在 main.dart 中透過 configureSDK 初始化
    // 此處僅註冊 listener 並發射初始狀態
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    final info = await Purchases.getCustomerInfo();
    _controller.add(_mapToStatus(info));
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _controller.add(_mapToStatus(info));
  }

  @override
  Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<SubscriptionStatus> getStatus() async {
    final info = await Purchases.getCustomerInfo();
    return _mapToStatus(info);
  }

  @override
  Future<SubscriptionStatus?> purchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        debugPrint('⚠️ No offerings available');
        return null;
      }

      final package = current.availablePackages.first;
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _mapToStatus(result.customerInfo);
    } on PlatformException catch (e) {
      // 使用者取消購買
      if (e.code == '1') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _mapToStatus(info);
  }

  SubscriptionStatus _mapToStatus(CustomerInfo info) {
    final entitlement = info.entitlements.active[_entitlementId];
    if (entitlement == null) {
      return SubscriptionStatus.free;
    }
    return SubscriptionStatus(
      isPremium: true,
      expirationDate: entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null,
    );
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _controller.close();
  }
}
