import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/features/subscription/domain/errors/subscription_errors.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// RevenueCat 實作的訂閱服務
class RevenueCatSubscriptionService implements SubscriptionService {
  static const _entitlementId = 'premium';

  /// PackageTypes we surface in the paywall, in display order.
  static const _supportedPackageTypes = <PackageType>[
    PackageType.weekly,
    PackageType.monthly,
    PackageType.annual,
  ];

  final _controller = StreamController<SubscriptionStatus>.broadcast();

  /// 全域 SDK 初始化（在 main.dart 中呼叫一次）
  static Future<void> configureSDK({required String apiKey}) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  /// Identify the SDK with a stable app user id (the Supabase user id).
  ///
  /// This makes RevenueCat's "App User ID" equal our backend user id, so
  /// server-side webhooks and reconcile attribute entitlements to the right
  /// user. Safe to call before any purchase; RevenueCat aliases the prior
  /// anonymous id so existing purchases are preserved.
  static Future<void> identify(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> initialize({required String apiKey}) async {
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
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        throw SubscriptionPlanNotAvailableException(period);
      }
      final targetType = _packageTypeFor(period);
      Package? package;
      for (final p in current.availablePackages) {
        if (p.packageType == targetType) {
          package = p;
          break;
        }
      }
      if (package == null) {
        throw SubscriptionPlanNotAvailableException(period);
      }
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

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      return const [];
    }

    final byType = <PackageType, Package>{
      for (final p in current.availablePackages)
        if (_supportedPackageTypes.contains(p.packageType)) p.packageType: p,
    };

    final plans = <SubscriptionPlan>[];
    for (final type in _supportedPackageTypes) {
      final pkg = byType[type];
      if (pkg == null) continue;
      final period = mapPeriod(type);
      plans.add(
        SubscriptionPlan(
          priceString: pkg.storeProduct.priceString,
          period: period,
          packageIdentifier: pkg.identifier,
          isBestValue: period == SubscriptionPeriod.yearly,
        ),
      );
    }
    return plans;
  }

  PackageType _packageTypeFor(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => PackageType.weekly,
    SubscriptionPeriod.monthly => PackageType.monthly,
    SubscriptionPeriod.yearly => PackageType.annual,
  };

  /// Maps a RC [PackageType] to our [SubscriptionPeriod].
  ///
  /// Only the three types in [_supportedPackageTypes] are accepted here;
  /// anything else is a programming error because [getAvailablePlans]
  /// filters by [_supportedPackageTypes] before mapping.
  @visibleForTesting
  static SubscriptionPeriod mapPeriod(PackageType type) => switch (type) {
    PackageType.weekly => SubscriptionPeriod.weekly,
    PackageType.monthly => SubscriptionPeriod.monthly,
    PackageType.annual => SubscriptionPeriod.yearly,
    _ => throw ArgumentError.value(type, 'type', 'Unsupported PackageType'),
  };

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
