import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';

/// 測試用的 Fake PurchaseRepository
///
/// 模擬 RevenueCat 行為，避免真實連線
class FakePurchaseRepository implements PurchaseRepository {
  final _purchaseController = StreamController<PurchaseUpdate>.broadcast();

  @override
  Stream<PurchaseUpdate> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<void> setUserId(String userId) async {
    // Fake implementation
  }

  @override
  Future<void> logout() async {
    // Fake implementation
  }

  @override
  Future<List<StoreProduct>> getProducts() async {
    return [];
  }

  @override
  Future<Offerings?> getOfferings() async {
    return null;
  }

  @override
  Future<bool> purchase(Package package) async {
    return true;
  }

  @override
  Future<CustomerInfo?> restorePurchases() async {
    return null;
  }

  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    return null;
  }

  @override
  Future<bool> hasActiveEntitlement() async {
    return false;
  }

  @override
  void dispose() {
    _purchaseController.close();
  }
}
